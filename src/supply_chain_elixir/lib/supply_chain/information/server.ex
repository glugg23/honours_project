defmodule SupplyChain.Information.Server do
  @moduledoc false

  require Logger

  use GenServer

  alias :ets, as: ETS

  alias SupplyChain.Information
  alias SupplyChain.Information.Nodes, as: Nodes
  alias SupplyChain.Information.TaskSupervisor, as: TaskSupervisor
  alias SupplyChain.Knowledge

  def init(_args) do
    :net_kernel.monitor_nodes(true)
    ETS.new(Nodes, [:set, :protected, :named_table])
    state = %{config: Knowledge.get_config(), tasks: []}
    {:ok, state}
  end

  def handle_call(:get_info, _from, state) do
    {:reply, state.config[:type], state}
  end

  def handle_info(msg = %Message{}, state) do
    Logger.notice("Got message: #{inspect(msg, pretty: true)}")
    {:noreply, state}
  end

  def handle_info({:nodeup, node}, state) do
    task =
      Task.Supervisor.async_nolink(TaskSupervisor, fn ->
        {node, Information.get_info({Information, node})}
      end)

    {:noreply, %{state | tasks: [task.ref | state.tasks]}}
  end

  def handle_info({:nodedown, node}, state) do
    ETS.delete(Nodes, node)
    Logger.notice("Node down #{inspect(node)}")
    {:noreply, state}
  end

  def handle_info({ref, {node, type}}, state) when is_reference(ref) do
    if ref in state.tasks do
      Process.demonitor(ref, [:flush])

      ignore = type in state.config[:information_filter]

      if ETS.insert_new(Nodes, {node, type, ignore}) do
        Logger.info("Node up #{inspect(node)}")
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
        task =
          Task.Supervisor.async_nolink(TaskSupervisor, fn ->
            {node, Information.get_info({Information, node})}
          end)

        {:noreply, %{state | tasks: [task.ref | state.tasks]}}

      _ ->
        {:noreply, state}
    end
  end
end
