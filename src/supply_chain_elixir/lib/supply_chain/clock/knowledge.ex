defmodule SupplyChain.Clock.Knowledge do
  @moduledoc """
  This defines the Knowledge layer for the Clock agent.
  """

  use GenServer

  alias SupplyChain.Information
  alias SupplyChain.Knowledge
  alias SupplyChain.Behaviour

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

  def handle_info(
        %Message{performative: :request, content: %{send_nodeup: value}, sender: Behaviour},
        state
      ) do
    {:noreply, %{state | send_nodeup?: value}}
  end
end
