defmodule HelloAgent.Counter do
  require Logger
  use GenServer, restart: :transient

  def init(state) do
    Logger.info("[#{state[:name]}] Starting")
    {:ok, ref} = :timer.send_interval(1_000, :hello)
    state = Map.put(state, :discovery, ref)
    {:ok, state}
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def handle_info(:hello, state) do
    pid = HelloAgent.Partner.hello()

    if pid != nil do
      {:ok, :cancel} = :timer.cancel(state[:discovery])
      Logger.info("[#{state[:name]}] found another agent #{inspect(pid)}")
      Logger.info("[#{state[:name]}] I'm #{inspect(self())}")

      Logger.info("[#{state[:name]}] Starting to count")
      :timer.send_interval(1_000, :count)
    end

    {:noreply, state}
  end

  def handle_info(:count, state) do
    Logger.info("[#{state[:name]}] count => #{state[:count]}")

    if state[:count] == 3 do
      Logger.info("[#{state[:name]}] orders Partner to die")
      HelloAgent.Partner.die()
      {:stop, :normal, state}
    else
      {:noreply, %{state | count: state[:count] + 1}}
    end
  end
end
