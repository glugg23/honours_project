defmodule SupplyChain.Knowledge.Manufacturer do
  @moduledoc """
  This defines the Knowledge layer for the Manufacturer agent.
  """

  use SupplyChain.Knowledge

  def init(type = :manufacturer) do
    state = %{config: Application.get_env(:supply_chain, type)}

    ETS.new(KnowledgeBase, [:set, :public, :named_table])
    ETS.insert(KnowledgeBase, {:used_storage, 0})
    Knowledge.insert_config(KnowledgeBase, state.config)

    ETS.new(Inbox, [:set, :public, :named_table])

    {:ok, state}
  end
end
