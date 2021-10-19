defmodule Request do
  @enforce_keys [:type, :quantity, :price]
  defstruct [
    :type,
    :quantity,
    :price
  ]

  def new(type, quantity, price) do
    %Request{
      type: type,
      quantity: quantity,
      price: price
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
