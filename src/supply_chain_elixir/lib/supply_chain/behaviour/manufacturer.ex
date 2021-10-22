defmodule SupplyChain.Behaviour.Manufacturer do
  @moduledoc """
  This is a state machine for the behaviour of the Manufacturer agent.
  """

  use GenStateMachine

  require Logger

  alias :ets, as: ETS

  alias SupplyChain.{Information, Knowledge}
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
    {:next_state, :run, data, {:next_event, :internal, :handle_messages}}
  end

  def handle_event(:internal, :handle_messages, :run, data) do
    messages = ETS.select(Inbox, [{{:_, :"$1", :_}, [], [:"$1"]}])

    {buying_requests, _production} =
      messages
      |> Enum.filter(fn m -> m.performative === :inform end)
      |> Enum.filter(fn m -> m.content.type === :buying end)
      |> Enum.sort_by(& &1.content, {:desc, Request})
      |> Enum.map_reduce(0, fn m, acc ->
        if accept_buying_request?(m.content, acc) do
          {{m, :accept}, acc + m.content.quantity}
        else
          {{m, :reject}, acc}
        end
      end)

    buying_requests
    |> Enum.each(fn {m, p} ->
      Message.reply(m, p, nil, {Information, Node.self()}) |> Message.send()
    end)

    round = ETS.lookup_element(KnowledgeBase, :round, 2)

    buying_requests
    |> Enum.filter(fn {_, p} -> p === :accept end)
    |> Enum.each(fn {m, _} -> ETS.insert(Orders, {m.conversation_id, m, round}) end)

    {:keep_state, data, {:next_event, :internal, :handle_orders}}
  end

  def handle_event(:internal, :handle_orders, :run, data) do
    round = ETS.lookup_element(KnowledgeBase, :round, 2)
    recipes = ETS.lookup_element(KnowledgeBase, :recipes, 2)
    orders = ETS.select(Orders, [{{:_, :"$1", :"$2"}, [{:"=:=", :"$2", round}], [:"$1"]}])

    # Turns list of messages into list of required finished computers
    # Then turns that list into a list of components with duplicates
    # Then combines duplicates to create one list of all components required
    required_components =
      orders
      |> Enum.reduce([], fn m, acc ->
        Keyword.update(acc, m.content.good, m.content.quantity, fn v -> v + m.content.quantity end)
      end)
      |> Enum.flat_map(fn {good, amount} ->
        recipes[good] |> Enum.map(fn {good, required} -> {good, required * amount} end)
      end)
      |> Enum.reduce([], fn {good, amount}, acc ->
        Keyword.update(acc, good, amount, fn orig -> orig + amount end)
      end)

    producer_capacity = ETS.lookup_element(KnowledgeBase, :producer_capacity, 2)

    for {good, amount} <- required_components do
      # Select all messages where request.type === :selling
      # And where the value of request.good is the good in the loop
      selling_orders =
        ETS.select(Inbox, [
          {{:_, :"$1", :_},
           [
             {:andalso, {:"=:=", {:map_get, :type, {:map_get, :content, :"$1"}}, :selling},
              {:"=:=", {:map_get, :good, {:map_get, :content, :"$1"}}, good}}
           ], [:"$1"]}
        ])
        |> Enum.sort_by(& &1.content, {:asc, Request})

      # Send requests in packets of at most producer capacity
      # Send to cheapest producer first
      # If there are more requests than producers, send to first producer and handle reject message
      # TODO: Handle reject message
      for i <- 0..div(amount, producer_capacity), reduce: amount do
        # TODO: Race condition, this crashes if seling_orders === []
        acc ->
          msg =
            case Enum.at(selling_orders, i) do
              m = %Message{} -> m
              nil -> Enum.at(selling_orders, 0)
            end

          {_, node} = msg.reply_to

          quantity = if acc > producer_capacity, do: producer_capacity, else: acc

          request =
            Message.new(
              :request,
              {Information, Node.self()},
              {Information, node},
              Request.new(:buying, good, quantity, msg.content.price, round + 2),
              msg.conversation_id
            )
            |> Message.send()

          ETS.insert(Orders, {request.conversation_id, request, round})

          acc - producer_capacity
      end
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

  defp accept_buying_request?(
         %Request{good: good, quantity: quantity, price: price},
         used_production
       ) do
    can_produce?(good, quantity, used_production) and acceptable_price?(good, price)
  end

  defp can_produce?(good, quantity, used_production) do
    computers = ETS.lookup_element(KnowledgeBase, :computers, 2)
    production_capacity = ETS.lookup_element(KnowledgeBase, :production_capacity, 2)

    Keyword.has_key?(computers, good) and quantity <= production_capacity - used_production
  end

  defp acceptable_price?(good, price) do
    computers = ETS.lookup_element(KnowledgeBase, :computers, 2)
    default_price = computers[good]
    price >= default_price
  end
end
