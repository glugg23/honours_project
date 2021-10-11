defmodule SupplyChain.Behaviour.Consumer do
  @moduledoc """
  This is a state machine for the behaviour of the Consumer agent.
  """

  use GenStateMachine

  require Logger

  alias :ets, as: ETS

  alias SupplyChain.{Information, Knowledge, Behaviour}
  alias SupplyChain.Information.Nodes, as: Nodes
  alias SupplyChain.Knowledge.KnowledgeBase, as: KnowledgeBase

  def init(_args) do
    {:ok, :start, %{round_msg: nil}}
  end

  def handle_event(
        :info,
        msg = %Message{
          performative: :inform,
          sender: {Knowledge, _},
          content: {:start_round, round}
        },
        :start,
        data
      ) do
    Logger.info("Round #{round}")
    data = %{data | round_msg: msg}

    {:next_state, :run, data, {:next_event, :internal, :check_orders}}
  end

  def handle_event(:internal, :check_orders, :run, data) do
    # TODO: Implement this
    {:keep_state, data, {:next_event, :internal, :send_new_orders}}
  end

  def handle_event(:internal, :send_new_orders, :run, data) do
    nodes = ETS.select(Nodes, [{{:"$1", :_, :_}, [], [:"$1"]}])
    computers = ETS.lookup_element(KnowledgeBase, :computers, 2)

    # TODO: Select recipe that should be ordered
    computer = hd(computers)

    # TODO: Select a quantity that should be ordered
    nodes
    |> Enum.map(
      &Message.new(
        :inform,
        {Behaviour, Node.self()},
        {Information, &1},
        {:buying, %{type: computer.name, price: computer.price, quantity: 1}}
      )
    )
    |> Enum.each(&Message.send/1)

    {:next_state, :finish, data, {:next_event, :internal, :send_finish_msg}}
  end

  def handle_event(:internal, :send_finish_msg, :finish, data) do
    data.round_msg |> Message.reply(:inform, :finished) |> Message.send()
    {:next_state, :start, data}
  end

  def handle_event({:call, from}, :ready?, _state, data) do
    {:keep_state, data, {:reply, from, true}}
  end

  def handle_event(:cast, :stop, _state, _data) do
    System.stop(0)
    {:stop, :shutdown}
  end
end
