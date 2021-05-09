defmodule SupplyChain.Knowledge do
  @moduledoc """
  The Knowledge layer of the agent.
  It handles loading the configuration file for the different types of agents.
  It passes the Information Filter to SupplyChain.Information.
  It acts as the knowledge storage for the Behaviour layer.
  """

  def child_spec(args) do
    %{
      id: SupplyChain.Knowledge,
      start: {SupplyChain.Knowledge, :start_link, [args]},
      shutdown: 5_000,
      restart: :permanent,
      type: :worker
    }
  end

  def start_link(type) do
    case type do
      :clock ->
        GenServer.start_link(SupplyChain.Clock.Knowledge, type, name: __MODULE__)

      _ ->
        GenServer.start_link(SupplyChain.Knowledge.Server, type, name: __MODULE__)
    end
  end

  def get_config() do
    GenServer.call(__MODULE__, :get_config)
  end

  def ready?() do
    GenServer.call(__MODULE__, :ready?)
  end
end
