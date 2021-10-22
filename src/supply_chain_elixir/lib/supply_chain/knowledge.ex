defmodule SupplyChain.Knowledge do
  @moduledoc """
  The Knowledge layer of the agent.
  It handles loading the configuration file for the different types of agents.
  It passes the Information Filter to SupplyChain.Information.
  It acts as the knowledge storage for the Behaviour layer.
  """

  require Logger

  alias :ets, as: ETS

  defmacro __using__(_opts) do
    quote do
      use GenServer

      alias :ets, as: ETS

      alias SupplyChain.{Behaviour, Information, Knowledge}
      alias SupplyChain.Knowledge.Inbox, as: Inbox
      alias SupplyChain.Knowledge.KnowledgeBase, as: KnowledgeBase
      alias SupplyChain.Knowledge.Orders, as: Orders

      @doc false
      def handle_call(:get_config, _from, state) do
        {:reply, state.config, state}
      end

      @doc false
      def handle_call(:ready?, _from, state) do
        {:reply, true, state}
      end

      @doc false
      def handle_call(:stop, _from, state) do
        {:stop, :shutdown, :ok, state}
      end

      @doc false
      def handle_info(
            %Message{performative: :inform, content: {:nodeup, _}, sender: Information},
            state
          ) do
        {:noreply, state}
      end

      @doc false
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

      @doc false
      def handle_info(msg = %Message{conversation_id: ref}, state) do
        # This will only be messages that have passed the information filter
        # Therefore store them in the inbox so that the Behaviour layer can process them
        round = ETS.lookup_element(KnowledgeBase, :round, 2)
        msg = Message.forward(msg, {Behaviour, Node.self()})
        ETS.insert(Inbox, {ref, msg, round})
        {:noreply, state}
      end
    end
  end

  def child_spec(args) do
    %{
      id: SupplyChain.Knowledge,
      start: {SupplyChain.Knowledge, :start_link, [args]},
      shutdown: 5_000,
      restart: :transient,
      type: :worker
    }
  end

  def start_link(type) do
    case type do
      :clock ->
        GenServer.start_link(SupplyChain.Knowledge.Clock, type, name: __MODULE__)

      :producer ->
        GenServer.start_link(SupplyChain.Knowledge.Producer, type, name: __MODULE__)

      :consumer ->
        GenServer.start_link(SupplyChain.Knowledge.Consumer, type, name: __MODULE__)

      :manufacturer ->
        GenServer.start_link(SupplyChain.Knowledge.Manufacturer, type, name: __MODULE__)

      _ ->
        Logger.critical("#{inspect(type)} is not a valid Knowledge layer implementation")

        System.stop(1)
    end
  end

  def insert_config(table, config) do
    common = Application.get_env(:supply_chain, :common)

    for {k, v} <- common do
      ETS.insert(table, {k, v})
    end

    for {k, v} <- config do
      ETS.insert(table, {k, v})
    end

    ETS.insert(table, {:money, 0})
  end

  def get_config do
    GenServer.call(__MODULE__, :get_config)
  end

  def ready?(node \\ Node.self()) do
    GenServer.call({__MODULE__, node}, :ready?)
  end

  def stop(node \\ Node.self()) do
    GenServer.call({__MODULE__, node}, :stop)
  end
end
