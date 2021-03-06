defmodule LiveViewCounter.Count do
  use GenServer

  alias Phoenix.PubSub

  @name :count_server

  @start_value 0

  def fly_region do
    System.get_env("FLY_REGION", "unknown")
  end

  def topic do
    "count"
  end

  def name, do: {:global, {fly_region(), @name}}

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, @start_value, name: name())
  end

  def incr() do
    GenServer.call(name(), :incr)
  end

  def decr() do
    GenServer.call(name(), :decr)
  end

  def current(name \\ name(), with_region \\ false) do
    GenServer.call(name, {:current, %{with_region: with_region}})
  end

  def via_node(node), do: {@name, node}

  def init(start_count) do
    Process.register(self(), @name)
    {:ok, start_count}
  end

  def handle_call({:current, opts}, _from, count) do
    reply = if Map.get(opts, :with_region), do: {fly_region(), count}, else: count

    {:reply, reply, count}
  end

  def handle_call(:incr, _from, count) do
    make_change(count, +1)
  end

  def handle_call(:decr, _from, count) do
    make_change(count, -1)
  end

  defp make_change(count, change) do
    new_count = count + change
    PubSub.broadcast(LiveViewCounter.PubSub, topic(), {:count, new_count, :region, fly_region()})
    {:reply, new_count, new_count}
  end
end
