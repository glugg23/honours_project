defmodule HelloAgent.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {HelloAgent.Counter, %{name: "COUNTER", count: 0}},
      {HelloAgent.Partner, %{name: "PARTNER"}}
    ]

    opts = [strategy: :one_for_all, name: HelloAgent.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
