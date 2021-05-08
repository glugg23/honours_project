defmodule SupplyChain.Behaviour.Server do
  @moduledoc """
  This is a dummy Behaviour layer implementation.
  This should be used as the default behaviour for agents with no implementation.
  This behaviour consumes all messages and logs warnings when this happens.
  """

  require Logger

  use GenServer

  def init(_args) do
    {:ok, %{}}
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
