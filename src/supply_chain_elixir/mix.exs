defmodule SupplyChain.MixProject do
  use Mix.Project

  def project do
    [
      app: :supply_chain,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {SupplyChain.Application, []}
    ]
  end

  defp deps do
    [
      {:libcluster, "~> 3.2"},
      {:credo, "~> 1.5", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end
end
