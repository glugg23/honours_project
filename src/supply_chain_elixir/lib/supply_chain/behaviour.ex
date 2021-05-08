defmodule SupplyChain.Behaviour do
  @moduledoc """
  The Behaviour layer for the agent.
  This handles the client side actions for defining the behaviour of the agent.
  The actual logic should be in seperate modules, which will be selected to run by start_link/1
  """

  alias SupplyChain.Information
  alias SupplyChain.Knowledge

  def child_spec(args) do
    %{
      id: SupplyChain.Behaviour,
      start: {SupplyChain.Behaviour, :start_link, [args]},
      shutdown: 5_000,
      restart: :permanent,
      type: :worker
    }
  end

  def start_link(args) do
    GenServer.start_link(SupplyChain.Behaviour.Server, args, name: __MODULE__)
  end
end

  def ready?() do
    Information.ready?() and Knowledge.ready?() and GenServer.call(__MODULE__, :ready?)
  end
end