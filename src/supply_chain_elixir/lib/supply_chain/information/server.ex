defmodule SupplyChain.Information.Server do
  @moduledoc false

  require Logger

  use GenServer

  alias :ets, as: ETS

  alias SupplyChain.{Information, Knowledge}
  alias SupplyChain.Information.Nodes, as: Nodes
  alias SupplyChain.Information.TaskSupervisor, as: TaskSupervisor

  def init(_args) do
    :net_kernel.monitor_nodes(true)
    ETS.new(Nodes, [:set, :protected, :named_table])
    state = %{config: Knowledge.get_config(), tasks: []}
    {:ok, state}
  end

  def handle_call(:get_info, _from, state) do
    {:reply, state.config[:type], state}
  end

  def handle_call({:ready?, other_nodes}, _from, state) do
    connected_nodes = ETS.select(Nodes, [{{:"$1", :_, :_}, [], [:"$1"]}]) |> Enum.sort()
    other_nodes = other_nodes |> Enum.filter(&(&1 !== Node.self())) |> Enum.sort()
    different_nodes = List.myers_difference(connected_nodes, other_nodes)

    new_tasks = Keyword.get(different_nodes, :ins, []) |> Enum.map(&info_task/1)
    state = %{state | tasks: state.tasks ++ new_tasks}

    {:reply, state.tasks === [], state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :shutdown, :ok, state}
  end

  def handle_info(msg = %Message{performative: :inform, content: {:start_round, _}}, state) do
    msg |> Message.forward({Knowledge, Node.self()}) |> Message.send()
    {:noreply, state}
  end

  def handle_info(msg = %Message{sender: {_, node}}, state) do
    ignore? = ETS.lookup_element(Nodes, node, 3)

    unless ignore? do
      msg |> Message.forward(Knowledge) |> Message.send()
    end

    {:noreply, state}
  end

  def handle_info({:nodeup, node}, state) do
    ref = info_task(node)
    {:noreply, %{state | tasks: [ref | state.tasks]}}
  end

  def handle_info({:nodedown, node}, state) do
    ETS.delete(Nodes, node)
    Logger.notice("Node down #{inspect(node)}")
    {:noreply, state}
  end

  def handle_info({ref, {node, type}}, state) when is_reference(ref) do
    if ref in state.tasks do
      Process.demonitor(ref, [:flush])

      ignore? = type in state.config[:information_filter]

      if ETS.insert_new(Nodes, {node, type, ignore?}) do
        Logger.info("Node up #{inspect(node)}")
        Message.new(:inform, Information, Knowledge, {:nodeup, node}) |> Message.send()
      else
        Logger.warning("#{node} is already registered")
      end

      {:noreply, %{state | tasks: List.delete(state.tasks, ref)}}
    else
      Logger.warning("Got node info with no valid task")
      {:noreply, state}
    end
  end

  def handle_info({:DOWN, ref, :process, _, reason = {type, {_, _, [{_, node}, _, _]}}}, state)
      when is_reference(ref) do
    Logger.warning("Task #{inspect(ref)} failed with #{inspect(reason)}")
    state = %{state | tasks: List.delete(state.tasks, ref)}

    case type do
      :timeout ->
        ref = info_task(node)
        {:noreply, %{state | tasks: [ref | state.tasks]}}

      :noproc ->
        ref = info_task(node)
        {:noreply, %{state | tasks: [ref | state.tasks]}}

      _ ->
        {:noreply, state}
    end
  end

  defp info_task(node) do
    task =
      Task.Supervisor.async_nolink(TaskSupervisor, fn ->
        {node, Information.get_info({Information, node})}
      end)

    task.ref
  end
end
