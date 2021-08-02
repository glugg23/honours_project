defmodule SupplyChain.Knowledge.Manufacturer do
  @moduledoc """
  This defines the Knowledge layer for the Manufacturer agent.
  """

  use SupplyChain.Knowledge

  alias SupplyChain.Information.Nodes, as: Nodes

  def init(type = :manufacturer) do
    state = %{
      config: Application.get_env(:supply_chain, type),
      round_msg: nil,
      unfiltered_agent_count: nil
    }

    ETS.new(KnowledgeBase, [:set, :public, :named_table])
    ETS.insert(KnowledgeBase, {:used_storage, 0})
    ETS.insert(KnowledgeBase, {:buying, []})
    ETS.insert(KnowledgeBase, {:selling, []})
    Knowledge.insert_config(KnowledgeBase, state.config)

    ETS.new(Inbox, [:set, :protected, :named_table])

    {:ok, state}
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
