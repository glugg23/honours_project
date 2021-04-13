defmodule SupplyChain.Information.Server do
  @moduledoc false

  require Logger

  use GenServer

  def init(state) do
    {:ok, _} = Registry.start_link(keys: :unique, name: SupplyChain.Information.Registry)
    # TODO: Waiting only 1 second is a race condition.
    # There is no guarantee that libcluster will connect to all nodes in this time.
    # Consider implementing a custom heartbeat to monitor Nodes.list/0?
    Process.send_after(self(), :init, 1_000)
    {:ok, state}
  end

  def handle_call(:info, _from, state) do
    {:reply, %{type: :agent}, state}
  end

  def handle_info(:init, state) do
    for n <- Node.list() do
      info = SupplyChain.Information.info({SupplyChain.Information, n})
      {:ok, _} = Registry.register(SupplyChain.Information.Registry, n, info)
    end

    Logger.info("#{Node.self()} is done")

    {:noreply, state}
  end
end
