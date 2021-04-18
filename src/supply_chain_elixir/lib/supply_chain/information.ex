defmodule SupplyChain.Information do
  @moduledoc """
  The Information layer for the agent.
  It handles receiving all the data from other agents and filtering it according to the Knowledge layer.
  """

  def child_spec(args) do
    %{
      id: SupplyChain.Information,
      start: {SupplyChain.Information, :start_link, [args]},
      shutdown: 5_000,
      restart: :permanent,
      type: :worker
    }
  end

  def start_link(args) do
    GenServer.start_link(SupplyChain.Information.Server, args, name: __MODULE__)
  end

  def get_info(layer) do
    GenServer.call(layer, :get_info)
  end

  def update_registry(diff) do
    GenServer.cast(__MODULE__, {:update_registry, diff})
  end
end
