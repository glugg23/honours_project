defmodule SupplyChain.Information.HeartBeat do
  @moduledoc """
  This module checks the nodes that are connected to ensure the node registry is up to date.
  """

  use GenServer

  def init(state) do
    Process.send_after(self(), :heartbeat, :random.uniform(5_000))
    {:ok, state}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def handle_info(:heartbeat, state) do
    registered =
      Registry.keys(SupplyChain.Information.Registry, Process.whereis(SupplyChain.Information))
      |> Enum.sort()

    connected = Node.list() |> Enum.sort()
    diff = List.myers_difference(registered, connected)

    # No need to update registry if there has been no change
    case diff do
      [] -> :ok
      [eq: _] -> :ok
      _ -> prepare(diff) |> SupplyChain.Information.update_registry()
    end

    Process.send_after(self(), :heartbeat, :random.uniform(5_000))
    {:noreply, state}
  end

  # Ensure the diff always has :ins and :del keys
  defp prepare(diff) do
    diff = if(diff[:ins] == nil, do: diff ++ [ins: []], else: diff)
    diff = if(diff[:del] == nil, do: diff ++ [del: []], else: diff)
    diff
  end
end
