defmodule VersionVectorTest do
  use ExUnit.Case
  doctest ServerWideClock.VersionVector

  alias ServerWideClock.VersionVector, as: VV

  test "min key" do
    a_0 = [{"a", 2}]
    a_1 = [{"a", 2}, {"b", 4}, {"c", 4}]
    a_2 = [{"a", 5}, {"b", 4}, {"c", 4}]
    a_3 = [{"a", 4}, {"b", 4}, {"c", 4}]
    a_4 = [{"a", 5}, {"b", 14}, {"c", 4}]
    assert "a" == VV.min_key(a_0)
    assert "a" == VV.min_key(a_1)
    assert "b" == VV.min_key(a_2)
    assert "a" == VV.min_key(a_3)
    assert "c" == VV.min_key(a_4)
  end

  test "reset counters" do
    e = []
    a_0 = [{"a", 2}]
    a_1 = [{"a", 2}, {"b", 4}, {"c", 4}]
    assert VV.reset_counters(e) == e
    assert VV.reset_counters(a_0) == [{"a", 0}]
    assert VV.reset_counters(a_1) == [{"a", 0}, {"b", 0}, {"c", 0}]
  end

  test "delete key" do
    e = []
    a_0 = [{"a", 2}]
    a_1 = [{"a", 2}, {"b", 4}, {"c", 4}]
    assert VV.delete_key(e, "a") == e
    assert VV.delete_key(a_0, "a") == e
    assert VV.delete_key(a_0, "b") == a_0
    assert VV.delete_key(a_1, "a") == [{"b", 4}, {"c", 4}]
  end

  test "join" do
    a_0 = [{"a", 4}]
    a_1 = [{"a", 2}, {"b", 4}, {"c", 4}]
    a_2 = [{"a", 1}, {"z", 10}]
    assert VV.join(a_0, a_1) == [{"a", 4}, {"b", 4}, {"c", 4}]
    assert VV.left_join(a_0, a_1) == a_0
    assert VV.left_join(a_0, a_2) == a_0
  end
end
