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
      |> Enum.filter(fn m -> elem(m.content, 0) === :buying end)
      |> Enum.sort_by(&elem(&1.content, 1), {:desc, Request})
      |> Enum.map_reduce(0, fn m, acc ->
        {_, content} = m.content

        if accept_buying_request?(content, acc) do
          {{m, :accept}, acc + content.quantity}
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
        {_, content} = m.content
        Keyword.update(acc, content.type, content.quantity, fn v -> v + content.quantity end)
      end)
      |> Enum.flat_map(fn {type, amount} ->
        recipes[type] |> Enum.map(fn {good, required} -> {good, required * amount} end)
      end)
      |> Enum.reduce([], fn {type, amount}, acc ->
        Keyword.update(acc, type, amount, fn orig -> orig + amount end)
      end)

    Logger.notice("#{inspect(required_components)}")

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
         %Request{type: type, quantity: quantity, price: price},
         used_production
       ) do
    can_produce?(type, quantity, used_production) and acceptable_price?(type, price)
  end

  defp can_produce?(type, quantity, used_production) do
    computers = ETS.lookup_element(KnowledgeBase, :computers, 2)
    production_capacity = ETS.lookup_element(KnowledgeBase, :production_capacity, 2)

    Keyword.has_key?(computers, type) and quantity <= production_capacity - used_production
  end

  defp acceptable_price?(type, price) do
    computers = ETS.lookup_element(KnowledgeBase, :computers, 2)
    default_price = computers[type]
    price >= default_price
  end
end
