defmodule ServerWideClock.KVClock do
  @moduledoc """
  Elixir implementation of the key-value clock, the so called dotted causal
  container
  """

  alias ServerWideClock.VersionVector, as: VV
  alias ServerWideClock.NodeClock, as: NC

  def new(), do: {:orddict.new(), VV.new()}

  def values({dots, _vv}), do: for({_, value} <- dots, do: value)

  def context({_dots, vv}), do: vv

  def sync({dots1, vv1}, {dots2, vv2}) do
    func_merge = fn _dot, val, val -> val end
    merged_dots = :orddict.merge(func_merge, dots1, dots2)
    func_filter = fn {id, counter}, _val -> counter > min(VV.get(id, vv1), VV.get(id, vv2)) end
    filtered_dots = :orddict.filter(func_filter, merged_dots)
    keys1 = :orddict.fetch_keys(dots1)
    pred_filter = fn dot, _val -> Enum.member?(keys1, dot) end
    filtered_dots2 = :orddict.filter(pred_filter, dots2)
    dots = :orddict.merge(func_merge, filtered_dots, filtered_dots2)
    {dots, VV.join(vv1, vv2)}
  end

  def add(bvv, {versions, _vv}) do
    dots = :orddict.fetch_keys(versions)
    Enum.reduce(dots, bvv, fn dot, acc -> NC.add(acc, dot) end)
  end

  def add({dots, vv}, dot, value) do
    {:orddict.store(dot, value, dots), VV.add(vv, dot)}
  end

  def discard({dots, vv}, context) do
    func_filter = fn {id, counter}, _val -> counter > VV.get(id, context) end
    {:orddict.filter(func_filter, dots), VV.join(vv, context)}
  end

  def fill({dots, vv}, bvv) do
    func = fn id, acc ->
      {base, _dots_from_bvv} = NC.get(id, bvv)
      VV.add(acc, {id, base})
    end

    {dots, Enum.reduce(NC.ids(bvv), vv, func)}
  end

  def fill({dots, vv}, bvv, ids) do
    ids2 = MapSet.to_list(MapSet.intersection(MapSet.new(NC.ids(bvv)), MapSet.new(ids)))

    func = fn id, acc ->
      {base, _dots_from_bvv} = NC.get(id, bvv)
      VV.add(acc, {id, base})
    end

    {dots, Enum.reduce(ids2, vv, func)}
  end
end
