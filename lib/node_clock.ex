defmodule ServerWideClock.NodeClock do
  @moduledoc """
  Elixir implementation of the node clock, which is a Bitmapped Version Vector.
  Uses Erlang orddict, ordered dictionary, under the hood.
  """
  @compile if Mix.env() == :test, do: :export_all

  require Bitwise

  @type bvv :: [{key :: ServerWideClock.id(), entry :: ServerWideClock.entry()}]

  @doc """
  Creates an empty BVV (erlang orddict)
  """
  @spec new() :: bvv
  def new() do
    :orddict.new()
  end

  @doc """
  Returns the keys of the BVV, which will be the node ids.
  """
  @spec ids(bvv) :: [ServerWideClock.id()]
  def ids(bvv) do
    :orddict.fetch_keys(bvv)
  end

  @doc """
  Returns the entry of a BVV associated with an id.
  """
  @spec get(ServerWideClock.id(), bvv) :: ServerWideClock.entry()
  def get(key, bvv) do
    case :orddict.find(key, bvv) do
      {:ok, entry} -> entry
      :error -> {0, 0}
    end
  end

  @doc """
  Normalizes entry pair.
  """
  @spec norm(ServerWideClock.entry()) :: ServerWideClock.entry()
  def norm({base, bitmap}) do
    case rem(bitmap, 2) do
      0 -> {base, bitmap}
      1 -> norm({base + 1, Bitwise.bsr(bitmap, 1)})
    end
  end

  @doc """
  Returns the sequence numbers for the dots represented by an entry
  """
  @spec values(ServerWideClock.entry()) :: [ServerWideClock.counter()]
  def values({base, bitmap}) do
    :lists.seq(1, base) ++ values(base, bitmap, [])
  end

  @spec values(ServerWideClock.counter(), ServerWideClock.counter(), [ServerWideClock.counter()]) ::
          [ServerWideClock.counter()]
  defp values(_, 0, acc) do
    Enum.reverse(acc)
  end

  defp values(base, bitmap, acc) do
    increm_base = base + 1

    case rem(bitmap, 2) do
      0 -> values(increm_base, Bitwise.bsr(bitmap, 1), acc)
      1 -> values(increm_base, Bitwise.bsr(bitmap, 1), [increm_base | acc])
    end
  end

  @spec missing_dots(bvv, bvv, [ServerWideClock.id()]) :: [
          {ServerWideClock.id(), [ServerWideClock.counter()]}
        ]
  def missing_dots(bvv1, bvv2, id_list) do
    func = fn key, val, acc ->
      with true <- Enum.member?(id_list, key),
           {:ok, val2} <- :orddict.find(key, bvv2),
           [] <- subtract_dots(val, val2) do
        acc
      else
        false -> acc
        :error -> [{key, values(val)} | acc]
        val_diff when is_list(val_diff) -> [{key, val_diff} | acc]
      end
    end

    :orddict.fold(func, [], bvv1)
  end

  defp subtract_dots({base1, bitmap1}, {base2, bitmap2}) when base1 > base2 do
    dots1 = Enum.to_list((base2 + 1)..base1) ++ values(base1, bitmap1, [])
    dots2 = values(base2, bitmap2, [])
    :ordsets.subtract(dots1, dots2)
  end

  defp subtract_dots({base1, bitmap1}, {base2, bitmap2}) when base1 <= base2 do
    dots1 = values(base1, bitmap1, [])
    dots2 = Enum.to_list((base1 + 1)..base2) ++ values(base2, bitmap2, [])
    :ordsets.subtract(dots1, dots2)
  end

  def add(bvv, {id, counter}) do
    initial = add_aux({0, 0}, counter)
    func = fn entry -> add_aux(entry, counter) end
    :orddict.update(id, func, initial, bvv)
  end

  defp add_aux({base, bitmap}, m_base) do
    case base < m_base do
      false ->
        norm({base, bitmap})

      true ->
        m = Bitwise.bor(bitmap, Bitwise.bsl(1, m_base - base - 1))
        norm({base, m})
    end
  end

  def merge(bvv1, bvv2) do
    func_merge = fn _id, entry1, entry2 -> join_aux(entry1, entry2) end
    norm_bvv(:orddict.merge(func_merge, bvv1, bvv2))
  end

  def join(bvv1, bvv2) do
    keys = :orddict.fetch_keys(bvv1)
    func_filter = fn id, _entry -> Enum.member?(keys, id) end
    bvv2 = :orddict.filter(func_filter, bvv2)
    func_merge = fn _id, entry1, entry2 -> join_aux(entry1, entry2) end
    norm_bvv(:orddict.merge(func_merge, bvv1, bvv2))
  end

  def base(bvv) do
    bvv = norm_bvv(bvv)
    func = fn _id, {base, _bitmap} -> {base, 0} end
    :orddict.map(func, bvv)
  end

  def event(bvv, id) do
    counter =
      case :orddict.find(id, bvv) do
        {:ok, {base, 0}} -> base + 1
        :error -> 1
      end

    {counter, add(bvv, {id, counter})}
  end

  def store_entry(_id, {0, 0}, bvv) do
    bvv
  end

  def store_entry(id, entry = {base, 0}, bvv) do
    case :orddict.find(id, bvv) do
      {:ok, {base2, _}} when base2 >= base -> bvv
      {:ok, {base2, _}} when base2 < base -> :orddict.store(id, entry, bvv)
      :error -> :orddict.store(id, entry, bvv)
    end
  end

  defp norm_bvv(bvv) do
    func_map = fn _id, entry -> norm(entry) end
    bvv = :orddict.map(func_map, bvv)
    func_filter = fn _id, entry -> entry != {0, 0} end
    :orddict.filter(func_filter, bvv)
  end

  defp join_aux({base1, bitmap1}, {base2, bitmap2}) do
    case base1 >= base2 do
      true -> {base1, Bitwise.bor(bitmap1, Bitwise.bsr(bitmap2, base1 - base2))}
      false -> {base2, Bitwise.bor(bitmap2, Bitwise.bsr(bitmap1, base2 - base1))}
    end
  end
end
