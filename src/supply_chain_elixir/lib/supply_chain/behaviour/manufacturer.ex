defmodule SupplyChain.Behaviour.Manufacturer do
  @moduledoc """
  This is a state machine for the behaviour of the Manufacturer agent.
  """

  use GenStateMachine

  require Logger

  alias :ets, as: ETS

  alias SupplyChain.Behaviour.TaskSupervisor, as: TaskSupervisor
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
    {:next_state, :run, data, {:next_event, :internal, :handle_new_orders}}
  end

  def handle_event(:internal, :handle_new_orders, :run, data) do
    messages =
      ETS.select(Inbox, [
        {{:_, :"$1", :_},
         [
           {:andalso, {:"=:=", {:map_get, :performative, :"$1"}, :inform},
            {:"=:=", {:map_get, :type, {:map_get, :content, :"$1"}}, :buying}}
         ], [:"$1"]}
      ])

    {buying_requests, _} =
      messages
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

    {:keep_state, data, {:next_event, :internal, :handle_new_components}}
  end

  def handle_event(:internal, :handle_new_components, :run, data) do
    round = ETS.lookup_element(KnowledgeBase, :round, 2)
    recipes = ETS.lookup_element(KnowledgeBase, :recipes, 2)
    orders = ETS.select(Orders, [{{:_, :"$1", :"$2"}, [{:"=:=", :"$2", round}], [:"$1"]}])

    # Turns list of messages into list of required finished computers
    # Then turns that list into a list of components with duplicates
    # Then combines duplicates to create one list of all components required
    required_components =
      orders
      |> Enum.reduce([], fn m, acc ->
        Keyword.update(acc, m.content.good, m.content.quantity, &(&1 + m.content.quantity))
      end)
      |> Enum.flat_map(fn {good, amount} ->
        recipes[good] |> Enum.map(fn {good, required} -> {good, required * amount} end)
      end)
      |> Enum.reduce([], fn {good, amount}, acc ->
        Keyword.update(acc, good, amount, &(&1 + amount))
      end)

    new_components_check(required_components)

    {:keep_state, data, {:next_event, :internal, :handle_component_orders}}
  end

  def handle_event(:internal, :handle_component_orders, :run, data) do
    messages =
      ETS.select(Inbox, [
        {{:"$1", :"$2", :_},
         [
           {:orelse, {:"=:=", {:map_get, :performative, :"$2"}, :accept},
            {:"=:=", {:map_get, :performative, :"$2"}, :reject}}
         ], [{{:"$1", :"$2"}}]}
      ])

    for {ref, msg} <- messages do
      case {msg.performative, msg.content} do
        {:accept, nil} ->
          ETS.update_element(Orders, ref, {4, true})

        {:accept, %Request{type: :delivery, good: good, quantity: quantity}} ->
          storage = ETS.lookup_element(KnowledgeBase, :storage, 2)
          storage = Keyword.update(storage, good, quantity, &(&1 + quantity))
          ETS.insert(KnowledgeBase, {:storage, storage})

          money = ETS.lookup_element(KnowledgeBase, :money, 2)
          ETS.insert(KnowledgeBase, {:money, money - msg.content.price * msg.content.quantity})

        {:reject, _} ->
          ETS.delete(Orders, ref)
      end
    end

    {:keep_state, data, {:next_event, :internal, :handle_finished_orders}}
  end

  def handle_event(:internal, :handle_finished_orders, :run, data) do
    round = ETS.lookup_element(KnowledgeBase, :round, 2)
    recipes = ETS.lookup_element(KnowledgeBase, :recipes, 2)
    storage = ETS.lookup_element(KnowledgeBase, :storage, 2)

    orders =
      ETS.select(Orders, [
        {{:"$1", :"$2", :_},
         [{:"=:=", {:map_get, :round, {:map_get, :content, :"$2"}}, round + 1}],
         [{{:"$1", :"$2"}}]}
      ])

    storage =
      for {ref, msg} <- orders, reduce: storage do
        acc ->
          components =
            recipes[msg.content.good]
            |> Enum.map(fn {good, required} -> {good, required * msg.content.quantity} end)

          # If the storage for all components is larger than the quantity
          if Enum.all?(components, fn {c, q} -> Keyword.get(acc, c, 0) >= q end) do
            Message.reply(
              msg,
              :inform,
              Request.new(
                :delivery,
                msg.content.good,
                msg.content.quantity,
                msg.content.price,
                round
              )
            )
            |> Message.send()

            money = ETS.lookup_element(KnowledgeBase, :money, 2)
            ETS.insert(KnowledgeBase, {:money, money + msg.content.price * msg.content.quantity})

            ETS.delete(Orders, ref)

            Enum.reduce(components, acc, fn {c, q}, acc -> Keyword.update!(acc, c, &(&1 - q)) end)
          else
            # TODO: Handle not having enough components in storage
            acc
          end
      end

    ETS.insert(KnowledgeBase, {:storage, storage})

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

  defp new_components_check([]) do
    :ok
  end

  defp new_components_check(required_components) do
    producer_capacity = ETS.lookup_element(KnowledgeBase, :producer_capacity, 2)
    round = ETS.lookup_element(KnowledgeBase, :round, 2)

    tasks =
      Task.Supervisor.async_stream_nolink(TaskSupervisor, required_components, fn {good, amount} ->
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
        # If there are more requests than producers, send to first producer
        for i <- 0..div(amount, producer_capacity), reduce: amount do
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

            ETS.insert(Orders, {request.conversation_id, request, round, false})

            acc - producer_capacity
        end
      end)
      |> Enum.to_list()
      |> Enum.with_index()
      |> Enum.filter(fn {{status, _}, _} -> status === :exit end)

    required_components =
      Enum.reduce(tasks, [], fn {_, i}, acc -> acc ++ [Enum.at(required_components, i)] end)

    new_components_check(required_components)
  end
end
