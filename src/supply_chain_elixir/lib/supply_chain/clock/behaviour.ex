defmodule SupplyChain.Clock.Behaviour do
  @moduledoc """
  This is a state machine for the behaviour of the clock agent.
  It ensures all the other agents are ready and then starts the rounds of the simulation.
  """

  use GenStateMachine

  require Logger

  alias :ets, as: ETS

  alias SupplyChain.Information.Nodes, as: Nodes
  alias SupplyChain.Knowledge
  alias SupplyChain.Behaviour
  alias SupplyChain.Behaviour.TaskSupervisor, as: TaskSupervisor

  def init(args) do
    {:ok, :setup, %{agent_count: args[:agent_count]}}
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
      {:next_state, :start_round, data}
    else
      Logger.debug("Not yet ready: #{inspect(ready)}")
      {:keep_state, data, {:next_event, :internal, :ask_ready}}
    end
  end

  def handle_event({:call, from}, :ready?, _state, data) do
    {:keep_state, data, {:reply, from, true}}
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
      |> Message.reply(:inform, %{send_nodeup: false})
      # Use new function instead of this?
      |> Map.replace(:receiver, Knowledge)
      |> Message.send()

      Logger.info("All nodes connected to clock agent")

      {:next_state, :is_ready?, data, {:next_event, :internal, :ask_ready}}
    else
      {:keep_state, data}
    end
  end
end
