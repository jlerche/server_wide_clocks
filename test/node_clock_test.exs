defmodule NodeClockTest do
  use ExUnit.Case
  doctest ServerWideClock.NodeClock

  alias ServerWideClock.NodeClock

  test "norm" do
    assert NodeClock.norm({5, 3}) == {7, 0}
    assert NodeClock.norm({5, 2}) == {5, 2}
    assert NodeClock.norm_bvv([{"a", {0, 0}}]) == []
    assert NodeClock.norm_bvv([{"a", {5, 3}}]), [{"a"}, {7, 0}]
  end

  test "values" do
    assert Enum.sort(NodeClock.values({0, 0})) == Enum.sort([])
    assert Enum.sort(NodeClock.values({5, 3})) == Enum.sort([1, 2, 3, 4, 5, 6, 7])
    assert Enum.sort(NodeClock.values({2, 5})) == Enum.sort([1, 2, 3, 5])
  end

  test "missing dots" do
    b1 = [
      {"a", {12, 0}},
      {"b", {7, 0}},
      {"c", {4, 0}},
      {"d", {5, 0}},
      {"e", {5, 0}},
      {"f", {7, 10}},
      {"g", {5, 10}},
      {"h", {5, 14}}
    ]

    b2 = [
      {"a", {5, 14}},
      {"b", {5, 14}},
      {"c", {5, 14}},
      {"d", {5, 14}},
      {"e", {15, 0}},
      {"f", {5, 14}},
      {"g", {7, 10}},
      {"h", {7, 10}}
    ]

    assert Enum.sort(NodeClock.missing_dots(b1, b2, [])) == []

    assert Enum.sort(NodeClock.missing_dots(b1, b2, ["a", "b", "c", "d", "e", "f", "g", "h"])) ==
             [{"a", [6, 10, 11, 12]}, {"b", [6]}, {"f", [6, 11]}, {"h", [8]}]
  end
end
