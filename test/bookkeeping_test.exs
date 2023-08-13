defmodule BookkeepingTest do
  use ExUnit.Case
  doctest Bookkeeping

  test "greets the world" do
    assert Bookkeeping.hello() == :world
  end
end
