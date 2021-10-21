defmodule Request do
  @moduledoc """
  A simple struct to store the state of an order request.
  """

  @enforce_keys [:type, :quantity, :price, :round]
  defstruct [
    :type,
    :quantity,
    :price,
    :round
  ]

  def new(type, quantity, price, round) do
    %Request{
      type: type,
      quantity: quantity,
      price: price,
      round: round
    }
  end

  def compare(request1, request2) do
    cond do
      request1.price > request2.price -> :gt
      request1.price === request2.price -> :eq
      request1.price < request2.price -> :lt
    end
  end
end
