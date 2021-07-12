defmodule SupplyChain.Knowledge.Manufacturer do
  @moduledoc """
  This defines the Knowledge layer for the Manufacturer agent.
  """

  require Logger

  use GenServer

  alias :ets, as: ETS

  alias SupplyChain.{Information, Behaviour}
  alias SupplyChain.Knowledge.KnowledgeBase, as: KnowledgeBase

  def init(type = :manufacturer) do
    state = %{config: Application.get_env(:supply_chain, type)}

    ETS.new(KnowledgeBase, [:set, :protected, :named_table])
    ETS.insert(KnowledgeBase, {:total_storage, state.config[:total_storage]})
    ETS.insert(KnowledgeBase, {:used_storage, 0})
    ETS.insert(KnowledgeBase, {:production_capacity, state.config[:production_capacity]})
    ETS.insert(KnowledgeBase, {:production_cost, state.config[:production_cost]})
    ETS.insert(KnowledgeBase, {:price_per_unit, state.config[:price_per_unit]})
    ETS.insert(KnowledgeBase, {:money, 0})

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
    msg |> Message.forward({Behaviour, Node.self()}) |> Message.send()
    {:noreply, state}
  end

  def handle_info(
        %Message{performative: :inform, content: {:nodeup, _}, sender: Information},
        state
      ) do
    {:noreply, state}
  end

  def handle_info(msg = %Message{}, state) do
    Logger.debug("Ignoring message #{inspect(msg, pretty: true)}")
    {:noreply, state}
  end
end
