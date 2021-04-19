defmodule SupplyChain.Information.Server do
  @moduledoc false

  require Logger

  use GenServer

  alias SupplyChain.Information
  alias SupplyChain.Information.Registry, as: NodeRegistry
  alias SupplyChain.Knowledge

  def init(_args) do
    state = Knowledge.get_config()
    {:ok, state}
  end

  def handle_call(:get_info, _from, state) do
    {:reply, %{type: state[:type]}, state}
  end

  def handle_cast({:update_registry, diff}, state) do
    for node <- diff[:ins] do
      try do
        info = Information.get_info({Information, node})
        info = Map.put(info, :ignore?, info[:type] in state[:information_filter])

        case Registry.register(NodeRegistry, node, info) do
          {:ok, _} -> :ok
          {:error, {:already_registered, _}} -> Logger.warning("#{node} is already registered")
        end
      catch
        :exit, {:timeout, _} -> Logger.warning("Registration timed out for #{node}")
      end
    end

    for node <- diff[:del] do
      :ok = Registry.unregister(NodeRegistry, node)
    end

    Logger.info("Updated node registry with #{inspect(diff)}")

    {:noreply, state}
  end

  def handle_info(msg = {ref, _}, state) when is_reference(ref) do
    Logger.debug("Ignoring late message #{inspect(msg)}")
    {:noreply, state}
  end
end
