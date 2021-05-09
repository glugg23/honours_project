defmodule SupplyChain.Clock.Behaviour do
  @moduledoc """
  This is a state machine for the behaviour of the clock agent.
  It ensures all the other agents are ready and then starts the rounds of the simulation.
  """

  use GenStateMachine

  def init(args) do
    {:ok, :setup, %{agent_count: args[:agent_count]}}
  end

  def handle_event({:call, from}, :ready?, _state, data) do
    {:keep_state, data, {:reply, from, true}}
  end
end
