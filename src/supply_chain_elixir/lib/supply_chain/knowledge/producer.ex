defmodule SupplyChain.Knowledge.Producer do
  @moduledoc """
  This defines the Knowledge layer for the Producer agent.
  """

  use GenServer

  alias :ets, as: ETS

  alias SupplyChain.Information
  alias SupplyChain.Knowledge.KnowledgeBase, as: KnowledgeBase
  alias SupplyChain.Behaviour

  def init(type = :producer) do
    state = %{config: Application.get_env(:supply_chain, type)}

    ETS.new(KnowledgeBase, [:set, :protected, :named_table])
    ETS.insert(KnowledgeBase, {:total_storage, state.config[:total_storage]})
    ETS.insert(KnowledgeBase, {:used_storage, 0})
    ETS.insert(KnowledgeBase, {:production_capacity, state.config[:production_capacity]})
    ETS.insert(KnowledgeBase, {:production_price, state.config[:production_price]})
    ETS.insert(KnowledgeBase, {:base_sell_price, state.config[:base_sell_price]})
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
        %Message{performative: :inform, content: {:nodeup, _}, sender: Information},
        state
      ) do
    {:noreply, state}
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
end
