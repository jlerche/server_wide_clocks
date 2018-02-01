defmodule ServerWideClockTest do
  use ExUnit.Case
  doctest ServerWideClock

  test "greets the world" do
    assert ServerWideClock.hello() == :world
  end
end
