defmodule ServerWideClock do
  @moduledoc """
  Documentation for ServerWideClock.
  """
  @type id :: term()
  @type counter :: non_neg_integer()
  @type entry :: {counter(), counter()}

  def hello do
    :world
  end
end
