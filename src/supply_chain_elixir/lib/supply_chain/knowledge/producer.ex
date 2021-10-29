defmodule SupplyChain.Knowledge.Producer do
  @moduledoc """
  This defines the Knowledge layer for the Producer agent.
  """

  use SupplyChain.Knowledge

  def init([type = :producer, sub_type]) do
    config = Application.get_env(:supply_chain, type)

    config =
      if sub_type !== nil do
        produces = Application.get_env(:supply_chain, sub_type)
        config ++ produces
      else
        config
      end

    state = %{config: config}

    ETS.new(KnowledgeBase, [:set, :public, :named_table])
    ETS.insert(KnowledgeBase, {:storage, []})
    Knowledge.insert_config(KnowledgeBase, state.config)

    ETS.new(Inbox, [:set, :public, :named_table])
    ETS.new(Orders, [:set, :public, :named_table])

    {:ok, state}
  end
end
