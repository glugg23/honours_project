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
