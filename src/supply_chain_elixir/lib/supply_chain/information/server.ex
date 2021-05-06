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
    ETS.new(Nodes, [:set, :protected, :named_table])
    state = %{config: Knowledge.get_config(), tasks: []}
    {:ok, state}
  end

  def handle_call(:get_info, _from, state) do
    {:reply, state.config[:type], state}
  end

  def handle_cast({:update_registry, diff}, state) do
    tasks =
      Enum.map(
        diff[:ins],
        &Task.Supervisor.async_nolink(TaskSupervisor, fn ->
          {&1, Information.get_info({Information, &1})}
        end)
      )
      |> Enum.map(fn t -> t.ref end)

    Enum.each(diff[:del], &ETS.delete(Nodes, &1))

    Logger.debug("Updated node registry with #{inspect(diff)}")

    {:noreply, %{state | tasks: state.tasks ++ tasks}}
  end

  def handle_info(msg = %Message{}, state) do
    Logger.notice("Got message: #{inspect(msg, pretty: true)}")
    {:noreply, state}
  end

  def handle_info(msg = {ref, {node, type}}, state) when is_reference(ref) do
    if ref in state.tasks do
      Process.demonitor(ref, [:flush])

      ignore = type in state.config[:information_filter]

      unless ETS.insert_new(Nodes, {node, type, ignore}) do
        Logger.warning("#{node} is already registered")
      end

      {:noreply, %{state | tasks: List.delete(state.tasks, ref)}}
    else
      Logger.debug("Got: #{inspect(msg)}")
      {:noreply, state}
    end
  end

  def handle_info({:DOWN, ref, :process, _, reason}, state) when is_reference(ref) do
    Logger.warning("Task #{inspect(ref)} failed with #{inspect(reason)}")
    {:noreply, %{state | tasks: List.delete(state.tasks, ref)}}
  end
end
