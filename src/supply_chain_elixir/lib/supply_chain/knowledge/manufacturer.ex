defmodule SupplyChain.Knowledge.Manufacturer do
  @moduledoc """
  This defines the Knowledge layer for the Manufacturer agent.
  """

  require Logger

  use GenServer

  alias :ets, as: ETS

  alias SupplyChain.{Information, Behaviour}
  alias SupplyChain.Information.Nodes, as: Nodes
  alias SupplyChain.Knowledge.KnowledgeBase, as: KnowledgeBase

  def init(type = :manufacturer) do
    state = %{
      config: Application.get_env(:supply_chain, type),
      round_msg: nil,
      unfiltered_agent_count: nil
    }

    ETS.new(KnowledgeBase, [:set, :public, :named_table])
    ETS.insert(KnowledgeBase, {:total_storage, state.config[:total_storage]})
    ETS.insert(KnowledgeBase, {:used_storage, 0})
    ETS.insert(KnowledgeBase, {:production_capacity, state.config[:production_capacity]})
    ETS.insert(KnowledgeBase, {:production_cost, state.config[:production_cost]})
    ETS.insert(KnowledgeBase, {:price_per_unit, state.config[:price_per_unit]})
    ETS.insert(KnowledgeBase, {:money, 0})
    ETS.insert(KnowledgeBase, {:buying, []})
    ETS.insert(KnowledgeBase, {:selling, []})

    {:ok, state}
  end

  def handle_call(:get_config, _from, state) do
    {:reply, state.config, state}
  end

  def handle_call(:ready?, _from, state) do
    {:reply, true, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :shutdown, :ok, state}
  end

  def handle_info(
        msg = %Message{
          performative: :inform,
          sender: {Information, _},
          content: {:start_round, round}
        },
        state
      ) do
    ETS.insert(KnowledgeBase, {:round, round})
    state = %{state | round_msg: msg}
    {:noreply, state}
  end

  def handle_info(
        %Message{performative: :inform, content: {:nodeup, _}, sender: Information},
        state
      ) do
    {:noreply, state}
  end

  def handle_info(msg = %Message{performative: :inform, content: {:start_round, type, _}}, state) do
    state =
      if state.unfiltered_agent_count == nil do
        # Count the number of unfiltered agents, excluding the Clock agent
        agent_count =
          ETS.select_count(Nodes, [
            {{:_, :"$1", :"$2"}, [{:andalso, {:"/=", :"$2", true}, {:"/=", :"$1", :clock}}],
             [true]}
          ])

        %{state | unfiltered_agent_count: agent_count}
      else
        state
      end

    messages = ETS.lookup_element(KnowledgeBase, type, 2)
    messages = [msg | messages]
    ETS.insert(KnowledgeBase, {type, messages})

    selling_count = ETS.lookup_element(KnowledgeBase, :selling, 2) |> length()
    buying_count = ETS.lookup_element(KnowledgeBase, :buying, 2) |> length()
    message_count = selling_count + buying_count

    # Start the Behaviour layer only when all the start round messages are received
    if message_count === state.unfiltered_agent_count do
      state.round_msg |> Message.forward({Behaviour, Node.self()}) |> Message.send()
    end

    {:noreply, state}
  end
end
