defmodule SupplyChain.Knowledge.Consumer do
  @moduledoc """
  This defines the Knowledge layer for the Consumer agent.
  """

  use SupplyChain.Knowledge

  def init(type = :consumer) do
    state = %{config: Application.get_env(:supply_chain, type)}

    ETS.new(KnowledgeBase, [:set, :public, :named_table])
    Knowledge.insert_config(KnowledgeBase, state.config)

    ETS.new(Inbox, [:set, :public, :named_table])
    ETS.new(Orders, [:set, :public, :named_table])

    {:ok, state}
  end
end
