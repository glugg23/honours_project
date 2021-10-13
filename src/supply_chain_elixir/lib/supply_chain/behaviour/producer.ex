defmodule SupplyChain.Behaviour.Producer do
  @moduledoc """
  This is a state machine for the behaviour of the Producer agent.
  """

  use GenStateMachine

  require Logger

  alias :ets, as: ETS

  alias SupplyChain.{Information, Knowledge, Behaviour}
  alias SupplyChain.Information.Nodes, as: Nodes
  alias SupplyChain.Knowledge.Inbox, as: Inbox
  alias SupplyChain.Knowledge.KnowledgeBase, as: KnowledgeBase

  def init(_args) do
    {:ok, :start, %{round_msg: nil, used_production: 0}}
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

    data = %{data | round_msg: msg, used_production: 0}

    {:next_state, :run, data, {:next_event, :internal, :check_orders}}
  end

  def handle_event(:internal, :check_orders, :run, data) do
    messages = ETS.select(Inbox, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])

    for {_ref, msg, _round} <- messages do
      case msg.performative do
        :request ->
          # TODO: Handle logic on accepting to change internal state
          if accept_request?(msg.content, data.used_production) do
            Message.reply(msg, :accept, nil) |> Message.send()
          else
            Message.reply(msg, :reject, nil) |> Message.send()
          end

        _ ->
          Message.reply(msg, :not_understood, nil) |> Message.send()
      end
    end

    {:keep_state, data, {:next_event, :internal, :send_new_figures}}
  end

  def handle_event(:internal, :send_new_figures, :run, data) do
    nodes = ETS.select(Nodes, [{{:"$1", :_, :_}, [], [:"$1"]}])
    produces = ETS.lookup_element(KnowledgeBase, :produces, 2)
    storage = ETS.lookup_element(KnowledgeBase, :storage, 2)
    components = ETS.lookup_element(KnowledgeBase, :components, 2)

    for product <- produces do
      price = components[product]
      quantity = Keyword.get(storage, product, 0)

      nodes
      |> Enum.map(
        &Message.new(
          :inform,
          {Behaviour, Node.self()},
          {Information, &1},
          {:selling, %{type: product, price: price, quantity: quantity}}
        )
      )
      |> Enum.each(&Message.send/1)
    end

    {:next_state, :finish, data, {:next_event, :internal, :send_finish_msg}}
  end

  def handle_event(:internal, :send_finish_msg, :finish, data) do
    SupplyChain.Behaviour.delete_old_messages()
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

  defp accept_request?({type, quantity, price}, used_production) do
    storage = ETS.lookup_element(KnowledgeBase, :storage, 2)

    if (have_enough?(storage, type, quantity) or
          can_produce?(type, quantity, used_production)) and acceptable_price?(type, price) do
      true
    else
      false
    end
  end

  defp have_enough?(storage, type, quantity) do
    have = Keyword.get(storage, type, 0)
    quantity <= have
  end

  defp can_produce?(type, quantity, used_production) do
    produces = ETS.lookup_element(KnowledgeBase, :produces, 2)
    production_capacity = ETS.lookup_element(KnowledgeBase, :production_capacity, 2)

    type in produces and quantity <= production_capacity - used_production
  end

  defp acceptable_price?(type, price) do
    components = ETS.lookup_element(KnowledgeBase, :components, 2)
    default_price = components[type]
    price >= default_price
  end
end
