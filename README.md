# ServerWideClock

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `server_wide_clock` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:server_wide_clock, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/server_wide_clock](https://hexdocs.pm/server_wide_clock).


# Reading material
[Server wide clocks paper](http://haslab.uminho.pt/tome/files/global_logical_clocks.pdf)

[DottedDB paper](http://haslab.uminho.pt/tome/files/dotteddb_srds.pdf)

# Implementation details
`peers(i)`: Periodically, an anti-entropy protocol is started by a shard/vnode `i`. Unlike `riak_core` where each vnode is an erlang process, `libring` shards are just entries in the ring so the state machine processes here won't be aware _which_ shard it is. A sensible sync period is ~100ms. We can randomly pick a shard that maps to the process and then undergo the usual anti entropy protocol as described in the paper. We can then set the sync period as 100ms/(shard_num). The peers of the shard are then the N-1 leading and trailing shards in the ring, where N is the replication number (separate from the sharding number, which ins `libring` is the weight).
