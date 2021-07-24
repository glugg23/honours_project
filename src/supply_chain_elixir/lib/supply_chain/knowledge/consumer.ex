defmodule SupplyChain.Knowledge.Consumer do
  @moduledoc """
  This defines the Knowledge layer for the Consumer agent.
  """

  use SupplyChain.Knowledge

  def init(type = :consumer) do
    state = %{config: Application.get_env(:supply_chain, type)}

    ETS.new(KnowledgeBase, [:set, :protected, :named_table])
    ETS.insert(KnowledgeBase, {:demand, state.config[:demand]})
    ETS.insert(KnowledgeBase, {:price_per_unit, state.config[:price_per_unit]})
    ETS.insert(KnowledgeBase, {:money, 0})

    ETS.new(Inbox, [:set, :protected, :named_table])

    {:ok, state}
  end
end
