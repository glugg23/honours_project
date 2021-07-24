defmodule SupplyChain.Behaviour.Manufacturer do
  @moduledoc """
  This is a state machine for the behaviour of the Manufacturer agent.
  """

  use GenStateMachine

  alias :ets, as: ETS

  alias SupplyChain.Knowledge
  alias SupplyChain.Knowledge.KnowledgeBase, as: KnowledgeBase

  def init(_args) do
    {:ok, :start, %{round_msg: nil}}
  end

  def handle_event(:internal, :main, :run, data) do
    {:next_state, :finish, data, {:next_event, :internal, :round_end_tasks}}
  end

  def handle_event(:internal, :round_end_tasks, :finish, data) do
    # Reset the list of resource messages for the next round
    ETS.insert(KnowledgeBase, {:buying, []})
    ETS.insert(KnowledgeBase, {:selling, []})
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

  def handle_event(
        :info,
        msg = %Message{
          performative: :inform,
          sender: {Knowledge, _},
          content: {:start_round, _}
        },
        :start,
        data
      ) do
    data = %{data | round_msg: msg}
    {:next_state, :run, data, {:next_event, :internal, :main}}
  end
end
