defmodule SupplyChain.Behaviour.Consumer do
  @moduledoc """
  This is a state machine for the behaviour of the Consumer agent.
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

    {:next_state, :run, data, {:next_event, :internal, :mark_orders}}
  end

  def handle_event(:internal, :mark_orders, :run, data) do
    messages =
      ETS.select(Inbox, [
        {{:"$1", :"$2", :_},
         [
           {:orelse, {:"=:=", {:map_get, :performative, :"$2"}, :accept},
            {:"=:=", {:map_get, :performative, :"$2"}, :reject}}
         ], [{{:"$1", :"$2"}}]}
      ])

    for {ref, msg} <- messages do
      case msg.performative do
        :accept -> ETS.update_element(Orders, ref, {4, true})
        :reject -> ETS.delete(Orders, ref)
      end
    end

    {:keep_state, data, {:next_event, :internal, :handle_delivered_orders}}
  end

  def handle_event(:internal, :handle_delivered_orders, :run, data) do
    delivered_orders =
      ETS.select(Inbox, [
        {{:"$1", :"$2", :_},
         [{:"=:=", {:map_get, :type, {:map_get, :content, :"$2"}}, :delivery}],
         [{{:"$1", :"$2"}}]}
      ])

    for {ref, msg} <- delivered_orders do
      # I have no idea why an order sometimes does not exist
      # In order to avoid a crash we just log it and move on
      try do
        order = ETS.lookup_element(Orders, ref, 2)

        if msg.content.good === order.content.good and
             msg.content.quantity === order.content.quantity do
          Logger.info("Delivery for order: #{inspect(order.content)}")
          money = ETS.lookup_element(KnowledgeBase, :money, 2)
          ETS.insert(KnowledgeBase, {:money, money - msg.content.price * msg.content.quantity})
        else
          Logger.warning("Incorrect delivery for order: #{inspect(order.content)}")
        end

        ETS.delete(Orders, ref)
      rescue
        e -> Logger.warning(Exception.format(:error, e, __STACKTRACE__))
      end
    end

    {:keep_state, data, {:next_event, :internal, :handle_late_orders}}
  end

  def handle_event(:internal, :handle_late_orders, :run, data) do
    round = ETS.lookup_element(KnowledgeBase, :round, 2)

    late_orders =
      ETS.select(Orders, [
        {{:_, :"$1", :_, :"$2"},
         [{:andalso, :"$2", {:<, {:map_get, :round, {:map_get, :content, :"$1"}}, round}}],
         [:"$1"]}
      ])

    for msg <- late_orders do
      Logger.info("Order #{inspect(msg.content)} is late!")
    end

    {:keep_state, data, {:next_event, :internal, :send_new_orders}}
  end

  def handle_event(:internal, :send_new_orders, :run, data) do
    nodes = ETS.select(Nodes, [{{:"$1", :_, :_}, [], [:"$1"]}])
    computers = ETS.lookup_element(KnowledgeBase, :computers, 2)
    round = ETS.lookup_element(KnowledgeBase, :round, 2)

    for {computer, price} <- computers do
      # TODO: Select a quantity that should be ordered
      # TODO: Select round that order should be fulfilled
      #       Minimum is +4 rounds in the future as this is the time required to accept and receive all orders
      message =
        Message.new(
          :inform,
          {Information, Node.self()},
          Information,
          Request.new(:buying, computer, 1, price, round + 4)
        )

      nodes
      |> Enum.map(&%Message{message | receiver: {Information, &1}})
      |> Enum.each(&Message.send/1)

      # Columns: ID, message, round sent, accepted?
      ETS.insert(Orders, {message.conversation_id, message, round, false})
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
end
