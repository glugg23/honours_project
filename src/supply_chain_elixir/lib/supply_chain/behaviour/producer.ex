defmodule SupplyChain.Behaviour.Producer do
  @moduledoc """
  This is a state machine for the behaviour of the Producer agent.
  """

  use GenStateMachine

  alias :ets, as: ETS

  alias SupplyChain.{Information, Knowledge, Behaviour}
  alias SupplyChain.Information.Nodes, as: Nodes
  alias SupplyChain.Knowledge.KnowledgeBase, as: KnowledgeBase

  def init(_args) do
    {:ok, :start, %{round_msg: nil}}
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

    nodes = ETS.select(Nodes, [{{:"$1", :_, :_}, [], [:"$1"]}])
    amount = ETS.lookup_element(KnowledgeBase, :used_storage, 2)
    price = ETS.lookup_element(KnowledgeBase, :price_per_unit, 2)

    nodes
    |> Enum.map(
      &Message.new(
        :inform,
        {Behaviour, Node.self()},
        {Information, &1},
        {:selling, %{amount: amount, price: price}}
      )
    )
    |> Enum.each(&Message.send/1)

    {:next_state, :run, data, {:next_event, :internal, :main}}
  end
end
