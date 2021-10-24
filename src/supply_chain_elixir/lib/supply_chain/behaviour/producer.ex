defmodule SupplyChain.Behaviour.Producer do
  @moduledoc """
  This is a state machine for the behaviour of the Producer agent.
  """

  use GenStateMachine

  require Logger

  alias :ets, as: ETS

  alias SupplyChain.{Information, Knowledge}
  alias SupplyChain.Information.Nodes, as: Nodes
  alias SupplyChain.Knowledge.Inbox, as: Inbox
  alias SupplyChain.Knowledge.KnowledgeBase, as: KnowledgeBase
  alias SupplyChain.Knowledge.Orders, as: Orders

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

    {:next_state, :run, data, {:next_event, :internal, :check_orders}}
  end

  def handle_event(:internal, :check_orders, :run, data) do
    messages =
      ETS.select(Inbox, [
        {{:_, :"$1", :_}, [{:"=:=", {:map_get, :performative, :"$1"}, :request}], [:"$1"]}
      ])

    round = ETS.lookup_element(KnowledgeBase, :round, 2)

    {requests, production} =
      messages
      # The selection of which requests to fulfill is basically the Knapsack Problem
      # We look at requests in descending item price order as a good enough solution
      |> Enum.sort_by(& &1.content, {:desc, Request})
      |> Enum.map_reduce(0, fn m, acc ->
        if accept_request?(m.content, acc) do
          {{m, :accept}, acc + m.content.quantity}
        else
          {{m, :reject}, acc}
        end
      end)

    requests
    |> Enum.map(fn {m, p} ->
      case p do
        :accept when m.content.round === round + 1 ->
          storage = ETS.lookup_element(KnowledgeBase, :storage, 2)

          storage =
            Keyword.update(
              storage,
              m.content.good,
              m.content.quantity,
              &(&1 - m.content.quantity)
            )

          ETS.insert(KnowledgeBase, {:storage, storage})

          Message.reply(
            m,
            :accept,
            Request.new(:selling, m.content.good, m.content.quantity, m.content.price, round)
          )

        :accept ->
          ETS.insert(Orders, {m.conversation_id, m, round})

          Message.reply(m, :accept, nil)

        :reject ->
          Message.reply(m, :reject, nil)
      end
    end)
    |> Enum.each(&Message.send/1)

    storage = ETS.lookup_element(KnowledgeBase, :storage, 2)
    produces = ETS.lookup_element(KnowledgeBase, :produces, 2)
    storage = Keyword.update(storage, produces, 0, &(&1 + production))
    ETS.insert(KnowledgeBase, {:storage, storage})

    {:keep_state, data, {:next_event, :internal, :send_new_figures}}
  end

  def handle_event(:internal, :send_new_figures, :run, data) do
    nodes = ETS.select(Nodes, [{{:"$1", :_, :_}, [], [:"$1"]}])
    storage = ETS.lookup_element(KnowledgeBase, :storage, 2)
    components = ETS.lookup_element(KnowledgeBase, :components, 2)
    round = ETS.lookup_element(KnowledgeBase, :round, 2)

    # TODO: Increase price based on storage, 1x capacity in storage = 2x price etc.
    produces = ETS.lookup_element(KnowledgeBase, :produces, 2)
    price = components[produces]
    quantity = storage[produces]

    nodes
    |> Enum.map(
      &Message.new(
        :inform,
        {Information, Node.self()},
        {Information, &1},
        Request.new(:selling, produces, quantity, price, round)
      )
    )
    |> Enum.each(&Message.send/1)

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

  # Producer agent is lean, it never stockpiles components
  # Only accept request if we have enough production capacity
  defp accept_request?(%Request{good: good, quantity: quantity, price: price}, used_production) do
    can_produce?(good, quantity, used_production) and acceptable_price?(good, price)
  end

  defp can_produce?(good, quantity, used_production) do
    produces = ETS.lookup_element(KnowledgeBase, :produces, 2)
    production_capacity = ETS.lookup_element(KnowledgeBase, :production_capacity, 2)

    good === produces and quantity <= production_capacity - used_production
  end

  defp acceptable_price?(good, price) do
    components = ETS.lookup_element(KnowledgeBase, :components, 2)
    default_price = components[good]
    price >= default_price
  end
end
