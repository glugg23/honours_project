defmodule SupplyChain.Producer.Behaviour do
  @moduledoc """
  This is a state machine for the behaviour of the Producer agent.
  """

  use GenStateMachine

  alias SupplyChain.Knowledge

  def init(_args) do
    {:ok, :state, %{}}
  end

  def handle_event({:call, from}, :ready?, _state, data) do
    {:keep_state, data, {:reply, from, true}}
  end

  def handle_event(:cast, :stop, _state, _data) do
    System.stop(0)
    {:stop, :shutdown}
  end

  def handle_event(
        :info,
        msg = %Message{
          performative: :inform,
          sender: {Knowledge, _},
          content: {:start_round, _}
        },
        _state,
        data
      ) do
    msg |> Message.reply(:inform, :finished) |> Message.send()
    {:keep_state, data}
  end
end
