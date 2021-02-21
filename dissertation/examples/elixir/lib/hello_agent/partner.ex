defmodule HelloAgent.Partner do
  require Logger
  use GenServer, restart: :transient

  def init(state) do
    Logger.info("[#{state[:name]}] Starting")
    {:ok, state}
  end

  def hello() do
    GenServer.call(__MODULE__, :hello)
  end

  def die() do
    GenServer.cast(__MODULE__, :die)
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def handle_call(:hello, _from, state) do
    Logger.info("[#{state[:name]}] Say hello!")
    {:reply, self(), state}
  end

  def handle_cast(:die, state) do
    Logger.info("[#{state[:name]}] is dying")
    {:stop, :normal, state}
  end
end
