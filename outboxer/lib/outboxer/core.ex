defmodule Outboxer.Core do
  defmodule Constants do
    use Agent

    def start_link(_opts) do
      Agent.start_link(&Outboxer.Layer1.proto_constants/0, name: __MODULE__)
    end

    def get(constant) do
      Agent.get(__MODULE__, &Map.get(&1, constant))
    end

    def all() do
      Agent.get(__MODULE__, &(&1))
    end
  end

  defmodule Levels do
    use Agent

    def start_link(_opts) do
      Agent.start_link(fn -> %{layer1: nil, rollup: nil, cemented: nil} end,
                       name: __MODULE__)
    end

    def get(key), do: Agent.get(__MODULE__, &Map.get(&1, key))

    def put(key, value), do: Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  defmodule Rollup do
    use Agent

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
    end
  end
end
