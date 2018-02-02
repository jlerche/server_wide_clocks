defmodule ServerWideClock.NodeClock do
  @moduledoc """
  Elixir implementation of the node clock, which is a Bitmapped Version Vector.
  Uses Erlang orddict, ordered dictionary, under the hood.
  """

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
  @spec ids(bvv) :: [ServerWideClock.id]
  def ids(bvv) do
    :orddict.fetch_keys(bvv)
  end

  @doc """
  Returns the entry of a BVV associated with an id.
  """
  @spec get(ServerWideClock.id, bvv) :: ServerWideClock.entry
  def get(key, bvv) do
    case :orddict.find(key, bvv) do
      {:ok, entry} ->
        entry
      :error ->
        {0, 0}
    end
  end

  @doc """
  Normalizes entry pair.
  """
  @spec norm(ServerWideClock.entry) :: ServerWideClock.entry
  def norm({base, bitmap}) do
    case rem(bitmap, 2) do
      0 -> {base, bitmap}
      1 -> norm({base + 1, :erlang.bsr(bitmap, 1)})
    end
  end

  @doc """
  Returns the sequence numbers for the dots represented by an entry
  """
  @spec values(ServerWideClock.entry) :: [ServerWideClock.counter]
  def values({base, bitmap}) do
    Enum.to_list(1..base) ++ values(base, bitmap, [])
  end

  @spec values(ServerWideClock.counter, ServerWideClock.counter, [ServerWideClock.counter]) :: [ServerWideClock.counter]
  defp values(_, 0, acc) do
    Enum.reverse(acc)
  end

  defp values(base, bitmap, acc) do
    increm_base = base + 1
    case rem(bitmap, 2) do
      0 -> values(increm_base, :erlang.bsr(bitmap, 1), acc)
      1 -> values(increm_base, :erlang.bsr(bitmap, 1), [increm_base | acc])
    end
  end

  def missing_dots(bvv1, bvv2, id_list) do
    {}
  end

end
