defmodule SupplyChain.Knowledge.Producer do
  @moduledoc """
  This defines the Knowledge layer for the Producer agent.
  """

  use SupplyChain.Knowledge

  def init(type = :producer) do
    state = %{config: Application.get_env(:supply_chain, type)}

    ETS.new(KnowledgeBase, [:set, :protected, :named_table])
    ETS.insert(KnowledgeBase, {:total_storage, state.config[:total_storage]})
    ETS.insert(KnowledgeBase, {:used_storage, 0})
    ETS.insert(KnowledgeBase, {:production_capacity, state.config[:production_capacity]})
    ETS.insert(KnowledgeBase, {:production_cost, state.config[:production_cost]})
    ETS.insert(KnowledgeBase, {:price_per_unit, state.config[:price_per_unit]})
    ETS.insert(KnowledgeBase, {:money, 0})

    ETS.new(Inbox, [:set, :protected, :named_table])

    {:ok, state}
  end
end
