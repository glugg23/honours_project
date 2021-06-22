defmodule SupplyChain do
  @moduledoc """
  Use this module for any functions regarding the whole system.
  """

  require Logger

  def get_config() do
    with {:ok, string} <- System.fetch_env("AGENT_TYPE"),
         {:ok, config} <- match_config_type(string) do
      config
    else
      :error ->
        Logger.critical(
          "AGENT_TYPE not in #{inspect(Application.get_env(:supply_chain, :agent_types) |> Enum.map(&to_string/1))}"
        )

        System.stop(1)
    end
  end

  defp match_config_type(string) do
    type = String.to_atom(string)
    valid_types = Application.get_env(:supply_chain, :agent_types)

    if type in valid_types do
      {:ok, type}
    else
      :error
    end
  end
end
