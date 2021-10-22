defmodule SupplyChain.Knowledge.Clock do
  @moduledoc """
  This defines the Knowledge layer for the Clock agent.
  """

  require Logger

  use GenServer

  alias SupplyChain.{Behaviour, Information, Knowledge}

  def init(type = :clock) do
    state = %{config: Application.get_env(:supply_chain, type), send_nodeup?: true}
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
        msg = %Message{performative: :inform, content: {:nodeup, _}, sender: Information},
        state
      ) do
    if state.send_nodeup? do
      msg |> Message.forward(Behaviour, Knowledge) |> Message.send()
    end

    {:noreply, state}
  end

  def handle_info(msg = %Message{performative: :inform, content: :finished}, state) do
    msg |> Message.forward(Behaviour) |> Message.send()
    {:noreply, state}
  end

  def handle_info(msg = %Message{}, state) do
    Logger.debug("Ignoring message #{inspect(msg, pretty: true)}")
    {:noreply, state}
  end

  def handle_info(
        %Message{performative: :request, content: %{send_nodeup: value}, sender: Behaviour},
        state
      ) do
    {:noreply, %{state | send_nodeup?: value}}
  end
end
