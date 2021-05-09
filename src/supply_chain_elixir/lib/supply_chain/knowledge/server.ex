defmodule SupplyChain.Knowledge.Server do
  @moduledoc """
  This is a dummy Knowledge layer implementation.
  Each agent type should define their own Knowledge layer.
  """

  require Logger

  use GenServer

  def init(type) do
    state = %{config: Application.get_env(:supply_chain, type)}
    {:ok, state}
  end

  def handle_call(:get_config, _from, state) do
    {:reply, state.config, state}
  end

  def handle_call(:ready?, _from, state) do
    {:reply, true, state}
  end

  def handle_call(atom, from, state) do
    Logger.warning("Received call #{inspect(atom)} from #{inspect(from)}")
    {:reply, :noop, state}
  end

  def handle_cast(atom, state) do
    Logger.warning("Received cast #{inspect(atom)}")
    {:noreply, state}
  end

  def handle_info(atom, state) do
    Logger.warning("Received info #{inspect(atom)}")
    {:noreply, state}
  end
end
