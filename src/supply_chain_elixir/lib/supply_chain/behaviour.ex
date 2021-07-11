defmodule SupplyChain.Behaviour do
  @moduledoc """
  The Behaviour layer for the agent.
  This handles the client side actions for defining the behaviour of the agent.
  The actual logic should be in separate modules, which will be selected to run by start_link/1
  """

  alias SupplyChain.Information
  alias SupplyChain.Knowledge

  def child_spec(args) do
    %{
      id: SupplyChain.Behaviour,
      start: {SupplyChain.Behaviour, :start_link, [args]},
      shutdown: 5_000,
      restart: :transient,
      type: :worker
    }
  end

  def start_link(args) do
    case args[:type] do
      :clock ->
        GenStateMachine.start_link(SupplyChain.Behaviour.Clock, args, name: __MODULE__)

      :producer ->
        GenStateMachine.start_link(SupplyChain.Behaviour.Producer, args, name: __MODULE__)

      :consumer ->
        GenStateMachine.start_link(SupplyChain.Behaviour.Consumer, args, name: __MODULE__)

      :manufacturer ->
        GenStateMachine.start_link(SupplyChain.Behaviour.Manufacturer, args, name: __MODULE__)

      _ ->
        GenServer.start_link(SupplyChain.Behaviour.Server, args, name: __MODULE__)
    end
  end

  def ready?(node \\ Node.self()) do
    Information.ready?(node) and Knowledge.ready?(node) and
      GenServer.call({__MODULE__, node}, :ready?)
  end

  def stop(node \\ Node.self()) do
    :ok = Information.stop(node)
    :ok = Knowledge.stop(node)
    GenServer.cast({__MODULE__, node}, :stop)
  end
end
