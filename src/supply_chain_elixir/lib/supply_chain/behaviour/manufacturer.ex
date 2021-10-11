defmodule SupplyChain.Behaviour.Manufacturer do
  @moduledoc """
  This is a state machine for the behaviour of the Manufacturer agent.
  """

  use GenStateMachine

  require Logger

  alias SupplyChain.Knowledge

  def init(_args) do
    {:ok, :start, %{round_msg: nil}}
  end

  def handle_event(
        :info,
        msg = %Message{
          performative: :inform,
          sender: {Knowledge, _},
          content: {:start_round, round}
        },
        :start,
        data
      ) do
    Logger.info("Round #{round}")
    data = %{data | round_msg: msg}
    {:next_state, :run, data, {:next_event, :internal, :main}}
  end

  def handle_event(:internal, :main, :run, data) do
    {:next_state, :finish, data, {:next_event, :internal, :send_finish_msg}}
  end

  def handle_event(:internal, :send_finish_msg, :finish, data) do
    data.round_msg |> Message.reply(:inform, :finished) |> Message.send()
    {:next_state, :start, data}
  end

  def handle_event({:call, from}, :ready?, _state, data) do
    {:keep_state, data, {:reply, from, true}}
  end

  def handle_event(:cast, :stop, _state, _data) do
    System.stop(0)
    {:stop, :shutdown}
  end
end
