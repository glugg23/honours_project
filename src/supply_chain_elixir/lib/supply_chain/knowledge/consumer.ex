defmodule SupplyChain.Knowledge.Consumer do
  @moduledoc """
  This defines the Knowledge layer for the Consumer agent.
  """

  use SupplyChain.Knowledge

  def init(type = :consumer) do
    state = %{config: Application.get_env(:supply_chain, type)}

    ETS.new(KnowledgeBase, [:set, :protected, :named_table])
    Knowledge.insert_config(KnowledgeBase, state.config)

    ETS.new(Inbox, [:set, :protected, :named_table])

    {:ok, state}
  end
end
