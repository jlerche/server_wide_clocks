defmodule KVClockTest do
  use ExUnit.Case

  alias ServerWideClock.KVClock, as: KVC

  def d1(), do: {[{{"a", 8}, "red"}, {{"b", 2}, "green"}], []}
  def d2(), do: {[], [{"a", 4}, {"b", 20}]}

  def d3(),
    do:
      {[{{"a", 1}, "black"}, {{"a", 3}, "red"}, {{"b", 1}, "green"}, {{"b", 2}, "green"}],
       [{"a", 4}, {"b", 7}]}

  def d4(),
    do:
      {[{{"a", 2}, "gray"}, {{"a", 3}, "red"}, {{"a", 5}, "red"}, {{"b", 2}, "green"}],
       [{"a", 5}, {"b", 5}]}

  def d5(), do: {[{{"a", 5}, "gray"}], [{"a", 5}, {"b", 5}, {"c", 4}]}

  test "values" do
    assert KVC.values(d1()) == ["red", "green"]
    assert KVC.values(d2()) == []
  end

  test "context" do
    assert KVC.context(d1()) == []
    assert KVC.context(d2()) == [{"a", 4}, {"b", 20}]
  end

  test "sync" do
    d34 = {[{{"a", 3}, "red"}, {{"a", 5}, "red"}, {{"b", 2}, "green"}], [{"a", 5}, {"b", 7}]}
    assert KVC.sync(d3(), d3()) == d3()
    assert KVC.sync(d4(), d4()) == d4()
    assert KVC.sync(d3(), d4()) == d34
  end

  test "add" do
    assert KVC.add([{"a", {5, 3}}], d1()) == [{"a", {8, 0}}, {"b", {0, 2}}]
  end
end
