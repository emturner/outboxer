defmodule Outboxer.Core do
  defmodule Levels do
    use Agent
    alias Phoenix.PubSub

    def start_link(_opts) do
      Agent.start_link(fn -> %{rollup: nil, cemented: nil} end, name: __MODULE__)
    end

    def get(key), do: Agent.get(__MODULE__, &Map.get(&1, key))

    def put(key, value) do
      if key == :layer1 do
        Outboxer.Query.l1_set_finalised_level("flextesa", value)
      else
        Agent.update(__MODULE__, &Map.put(&1, key, value))
      end

      PubSub.broadcast(Outboxer.PubSub, "levels", {key, value})
    end
  end

  defmodule Rollup do
    use Agent
    alias Phoenix.PubSub

    def start_link(_opts) do
      address = Outboxer.Rollup.address()
      state = {address, []}
      Agent.start_link(fn -> state end, name: __MODULE__)
    end

    def address() do
      Agent.get(__MODULE__, fn {address, _} -> address end)
    end

    def messages() do
      Agent.get(__MODULE__, fn {_, messages} -> messages end)
    end

    def add_messages(messages) do
      Agent.update(__MODULE__, fn {a, m} -> {a, messages ++ m} end)
      PubSub.broadcast(Outboxer.PubSub, "outbox", {:outbox, messages})
    end
  end
end
