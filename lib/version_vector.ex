defmodule ServerWideClock.VersionVector do
  @moduledoc """
  Elixir implementation of a version vector using an Erlang orddict
  """
  @compile if Mix.env() == :test, do: :export_all

  @type vv :: [{key :: ServerWideClock.id(), entry :: ServerWideClock.counter()}]

  @doc """
  Creates new empty version vector
  """
  @spec new() :: vv
  def new(), do: :orddict.new()

  @doc """
  Fetches all the ids from the input version vector
  """
  @spec ids(vv) :: [ServerWideClock.id()]
  def ids(vv), do: :orddict.fetch_keys(vv)

  @doc """
  Checks if given id is in the given version vector
  """
  @spec is_key(vv, ServerWideClock.id()) :: boolean
  def is_key(vv, id), do: :orddict.is_key(id, vv)

  @doc """
  Returns the counter associated with the id for the given version vector.
  Returns 0 otherwise
  """
  @spec get(ServerWideClock.id(), vv) :: ServerWideClock.counter()
  def get(id, vv) do
    case :orddict.find(id, vv) do
      :error -> 0
      {:ok, counter} -> counter
    end
  end

  @doc """
  Join two version vectors, take maximum counter if an entry is present in both.
  """
  def join(vv1, vv2) do
    func = fn _id, counter1, counter2 -> max(counter1, counter2) end
    :orddict.merge(func, vv1, vv2)
  end

  @doc """
  Joins two version vectors, takes maximum counter if entry is in both
   and taking the entry in vv1 but not vv2.
  """
  def left_join(vv1, vv2) do
    ids_1 = :orddict.fetch_keys(vv1)
    func_filter = fn id, _ -> Enum.member?(id, ids_1) end
    vv2_filter = :orddict.filter(func_filter, vv2)
    join(vv1, vv2_filter)
  end

  @doc """
  Applies boolean function to the entries in the given version vector,
  removing them if the function evaluates to false
  """
  def filter(func, vv), do: :orddict.filter(func, vv)

  @doc """
  Adds an entry {id, counter} to the given version vector, taking the maximum
  of both counters if entry already exists
  """
  def add(vv, {id, counter}) do
    func = fn c -> max(c, counter) end
    :orddict.update(id, func, counter, vv)
  end

  @doc """
  Returns the minimum counter from the entries of the version vector
  """
  def min(vv) do
    ids(vv)
    |> Enum.map(&:orddict.fetch(&1, vv))
    |> Enum.min()
  end

  @doc """
  Returns the key with the minimum counter associated with it
  """
  def min_key(vv) do
    func = fn key, value, {mkey, mval} ->
      case value < mval do
        true -> {key, value}
        false -> {mkey, mval}
      end
    end

    [head | tail] = vv
    {min_key, _min_val} = :orddict.fold(func, head, tail)
    min_key
  end

  @doc """
  Returns the version vector with the same ids, but counters set to 0
  """
  def reset_counters(vv), do: :orddict.map(fn _id, _counter -> 0 end, vv)

  @doc """
  Returns the version vector without the entry with the given key
  """
  def delete_key(vv, key), do: :orddict.erase(key, vv)
end
