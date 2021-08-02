defmodule SupplyChain.Knowledge.Producer do
  @moduledoc """
  This defines the Knowledge layer for the Producer agent.
  """

  use SupplyChain.Knowledge

  def init(type = :producer) do
    state = %{config: Application.get_env(:supply_chain, type)}

    ETS.new(KnowledgeBase, [:set, :protected, :named_table])
    ETS.insert(KnowledgeBase, {:used_storage, 0})
    Knowledge.insert_config(KnowledgeBase, state.config)

    ETS.new(Inbox, [:set, :protected, :named_table])

    {:ok, state}
  end
end
