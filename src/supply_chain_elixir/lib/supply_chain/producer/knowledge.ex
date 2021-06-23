defmodule SupplyChain.Producer.Knowledge do
  @moduledoc """
  This defines the Knowledge layer for the Producer agent.
  """

  use GenServer

  alias SupplyChain.Information
  alias SupplyChain.Behaviour

  def init(type = :producer) do
    state = %{config: Application.get_env(:supply_chain, type)}
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
          content: {:start_round, _}
        },
        state
      ) do
    msg |> Message.forward({Behaviour, Node.self()}) |> Message.send()
    {:noreply, state}
  end
end
