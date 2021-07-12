defmodule SupplyChain.Knowledge.Consumer do
  @moduledoc """
  This defines the Knowledge layer for the Consumer agent.
  """

  use GenServer

  alias :ets, as: ETS

  alias SupplyChain.{Information, Behaviour}
  alias SupplyChain.Knowledge.KnowledgeBase, as: KnowledgeBase

  def init(type = :consumer) do
    state = %{config: Application.get_env(:supply_chain, type)}

    ETS.new(KnowledgeBase, [:set, :protected, :named_table])
    ETS.insert(KnowledgeBase, {:demand, state.config[:demand]})
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
