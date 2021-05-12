defmodule SupplyChain.Clock.Behaviour do
  @moduledoc """
  This is a state machine for the behaviour of the clock agent.
  It ensures all the other agents are ready and then starts the rounds of the simulation.
  """

  use GenStateMachine

  require Logger

  alias :ets, as: ETS

  alias SupplyChain.Information
  alias SupplyChain.Information.Nodes, as: Nodes
  alias SupplyChain.Knowledge
  alias SupplyChain.Behaviour
  alias SupplyChain.Behaviour.TaskSupervisor, as: TaskSupervisor

  def init(args) do
    {:ok, :setup,
     %{
       agent_count: args[:agent_count],
       round: 0,
       max_rounds: args[:max_rounds],
       finished_agents: []
     }}
  end

  def handle_event(:internal, :ask_ready, :is_ready?, data) do
    nodes = ETS.select(Nodes, [{{:"$1", :_, :_}, [], [:"$1"]}])

    ready =
      Task.Supervisor.async_stream_nolink(
        TaskSupervisor,
        nodes,
        Behaviour,
        :ready?,
        []
      )
      |> Enum.to_list()

    if Enum.all?(ready, fn x -> x === {:ok, true} end) do
      Logger.info("All nodes ready")
      {:next_state, :start_round, data, {:next_event, :internal, :anounce}}
    else
      Logger.debug("Not yet ready: #{inspect(ready)}")
      {:keep_state, data, {:next_event, :internal, :ask_ready}}
    end
  end

  def handle_event(:internal, :anounce, :start_round, data) do
    nodes = ETS.select(Nodes, [{{:"$1", :_, :_}, [], [:"$1"]}])
    data = %{data | round: data.round + 1}

    Logger.notice("Starting round #{data.round}")

    Enum.map(nodes, fn n ->
      Message.new(
        :inform,
        {Behaviour, Node.self()},
        {Information, n},
        {:start_round, %{round: data.round}}
      )
    end)
    |> Enum.each(&Message.send/1)

    {:next_state, :end_round, data}
  end

  def handle_event(:internal, :continue?, :end_round, data) do
    data = %{data | finished_agents: []}

    if data.round === data.max_rounds do
      {:next_state, :finish, data, {:next_event, :internal, :stop_nodes}}
    else
      {:next_state, :start_round, data, {:next_event, :internal, :anounce}}
    end
  end

  def handle_event(:internal, :stop_nodes, :finish, data) do
    Logger.notice("Stopping all nodes")

    nodes = ETS.select(Nodes, [{{:"$1", :_, :_}, [], [:"$1"]}])
    Enum.each(nodes, &Behaviour.stop(&1))

    Behaviour.stop()
    {:keep_state, data}
  end

  def handle_event({:call, from}, :ready?, _state, data) do
    {:keep_state, data, {:reply, from, true}}
  end

  def handle_event(:cast, :stop, :finish, _data) do
    System.stop(0)
    {:stop, :shutdown}
  end

  def handle_event(
        :info,
        msg = %Message{performative: :inform, content: {:nodeup, _}, sender: Knowledge},
        :setup,
        data
      ) do
    current = ETS.match(Nodes, :"$1") |> length()

    if current === data.agent_count do
      msg
      |> Message.reply(:request, %{send_nodeup: false})
      # Use new function instead of this?
      |> Map.replace(:receiver, Knowledge)
      |> Message.send()

      Logger.info("All nodes connected to clock agent")

      {:next_state, :is_ready?, data, {:next_event, :internal, :ask_ready}}
    else
      {:keep_state, data}
    end
  end

  def handle_event(
        :info,
        %Message{performative: :inform, content: :finished, sender: {_, node}},
        :end_round,
        data
      ) do
    nodes = ETS.select(Nodes, [{{:"$1", :_, :_}, [], [:"$1"]}]) |> Enum.sort()
    data = %{data | finished_agents: [node | data.finished_agents] |> Enum.sort()}

    Logger.info("[#{length(data.finished_agents)}/#{length(nodes)}] agents finished")

    if data.finished_agents === nodes do
      {:keep_state, data, {:next_event, :internal, :continue?}}
    else
      {:keep_state, data}
    end
  end
end
