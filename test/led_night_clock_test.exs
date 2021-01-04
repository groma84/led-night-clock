defmodule LedNightClockTest do
  use ExUnit.Case
  doctest LedNightClock

  test "greets the world" do
    assert LedNightClock.hello() == :world
  end
end
