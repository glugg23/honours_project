defmodule SupplyChain.Information.Server do
  @moduledoc false

  require Logger

  use GenServer

  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_info, _from, state) do
    {:reply, %{type: :agent}, state}
  end

  def handle_cast({:update_registry, diff}, state) do
    for node <- diff[:ins] do
      # This could timeout, wrap in try/catch and handle late messages
      # https://cultivatehq.com/posts/genserver-call-timeouts/
      info = SupplyChain.Information.get_info({SupplyChain.Information, node})
      {:ok, _} = Registry.register(SupplyChain.Information.Registry, node, info)
    end

    for node <- diff[:del] do
      :ok = Registry.unregister(SupplyChain.Information.Registry, node)
    end

    Logger.info("Updated node registry with #{inspect(diff)}")

    {:noreply, state}
  end
end
