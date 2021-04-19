defmodule SupplyChain.Information.Server do
  @moduledoc false

  require Logger

  use GenServer

  def init(_args) do
    state = [config: SupplyChain.Knowledge.get_config()]
    {:ok, state}
  end

  def handle_call(:get_info, _from, state) do
    {:reply, state[:config], state}
  end

  def handle_cast({:update_registry, diff}, state) do
    for node <- diff[:ins] do
      try do
        info = SupplyChain.Information.get_info({SupplyChain.Information, node})

        case Registry.register(SupplyChain.Information.Registry, node, info) do
          {:ok, _} -> :ok
          {:error, {:already_registered, _}} -> Logger.warning("#{node} is already registered")
        end
      catch
        :exit, {:timeout, _} -> Logger.warning("Registration timed out for #{node}")
      end
    end

    for node <- diff[:del] do
      :ok = Registry.unregister(SupplyChain.Information.Registry, node)
    end

    Logger.info("Updated node registry with #{inspect(diff)}")

    {:noreply, state}
  end

  def handle_info(msg = {ref, _}, state) when is_reference(ref) do
    Logger.debug("Ignoring late message #{inspect(msg)}")
    {:noreply, state}
  end
end
