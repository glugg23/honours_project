defmodule SupplyChain.Information.Server do
  @moduledoc false

  require Logger

  use GenServer

  alias :ets, as: ETS

  alias SupplyChain.Information
  alias SupplyChain.Information.Nodes, as: Nodes
  alias SupplyChain.Knowledge

  def init(_args) do
    ETS.new(Nodes, [:set, :protected, :named_table])
    state = Knowledge.get_config()
    {:ok, state}
  end

  def handle_call(:get_info, _from, state) do
    {:reply, state[:type], state}
  end

  def handle_cast({:update_registry, diff}, state) do
    for node <- diff[:ins] do
      try do
        type = Information.get_info({Information, node})
        ignore = type in state[:information_filter]

        unless ETS.insert_new(Nodes, {node, type, ignore}) do
          Logger.warning("#{node} is already registered")
        end
      catch
        :exit, {:timeout, _} -> Logger.warning("Registration timed out for #{node}")
      end
    end

    for node <- diff[:del] do
      ETS.delete(Nodes, node)
    end

    Logger.info("Updated node registry with #{inspect(diff)}")

    {:noreply, state}
  end

  def handle_info(msg = %Message{}, state) do
    Logger.debug("Got message: #{inspect(msg, pretty: true)}")
    {:noreply, state}
  end

  def handle_info(msg = {ref, _}, state) when is_reference(ref) do
    Logger.debug("Ignoring late message #{inspect(msg)}")
    {:noreply, state}
  end
end
