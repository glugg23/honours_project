defmodule HonoursTest do
  use ExUnit.Case
  doctest Honours

  test "greets the world" do
    assert Honours.hello() == :world
  end
end
