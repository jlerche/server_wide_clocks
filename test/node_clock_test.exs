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

    assert Enum.sort(NodeClock.missing_dots(b1, b2, ["a", "c", "d", "e", "f", "g", "h"])) == [
             {"a", [6, 10, 11, 12]},
             {"f", [6, 11]},
             {"h", [8]}
           ]

    assert Enum.sort(NodeClock.missing_dots([{"a", {2, 2}}, {"b", {3, 0}}], [], ["a"])) == [
             {"a", [1, 2, 4]}
           ]

    assert Enum.sort(NodeClock.missing_dots([{"a", {2, 2}}, {"b", {3, 0}}], [], ["a", "b"])) == [
             {"a", [1, 2, 4]},
             {"b", [1, 2, 3]}
           ]

    assert NodeClock.missing_dots([], b1, ["a", "b", "c", "d", "e", "f", "g", "h"]) == []
  end

  test "subtract dots" do
    assert NodeClock.subtract_dots({12, 0}, {5, 14}) == [6, 10, 11, 12]
    assert NodeClock.subtract_dots({7, 0}, {5, 14}) == [6]
    assert NodeClock.subtract_dots({4, 0}, {5, 14}) == []
    assert NodeClock.subtract_dots({5, 0}, {5, 14}) == []
    assert NodeClock.subtract_dots({5, 0}, {15, 0}) == []
    assert NodeClock.subtract_dots({7, 10}, {5, 14}) == [6, 11]
    assert NodeClock.subtract_dots({5, 10}, {7, 10}) == []
    assert NodeClock.subtract_dots({5, 14}, {7, 10}) == [8]
  end

  test "add" do
    bvv = [{"a", {5, 3}}]
    assert NodeClock.add(bvv, {"b", 0}) == [{"a", {5, 3}}, {"b", {0, 0}}]
    assert NodeClock.add(bvv, {"a", 1}) == [{"a", {7, 0}}]
    assert NodeClock.add(bvv, {"a", 8}) == [{"a", {8, 0}}]
    assert NodeClock.add(bvv, {"b", 8}) == [{"a", {5, 3}}, {"b", {0, 128}}]
  end

  test "add aux" do
    assert NodeClock.add_aux({5, 3}, 8) == {8, 0}
    assert NodeClock.add_aux({5, 3}, 7) == {7, 0}
    assert NodeClock.add_aux({5, 3}, 4) == {7, 0}
    assert NodeClock.add_aux({2, 5}, 4) == {5, 0}
    assert NodeClock.add_aux({2, 5}, 6) == {3, 6}
    assert NodeClock.add_aux({2, 4}, 6) == {2, 12}
  end

  test "merge" do
    assert NodeClock.merge([{"a", {5, 3}}], [{"a", {2, 4}}]) == [{"a", {7, 0}}]
    assert NodeClock.merge([{"a", {5, 3}}], [{"b", {2, 4}}]) == [{"a", {7, 0}}, {"b", {2, 4}}]
  end
end
