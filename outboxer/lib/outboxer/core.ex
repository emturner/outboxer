defmodule Outboxer.Core do
  defmodule Levels do
    use Agent
    alias Phoenix.PubSub

    def start_link(_opts) do
      Agent.start_link(fn -> %{"flextesa" => %{rollup: nil, cemented: nil}, "ghostnet" => %{rollup: nil, cemented: nil}} end, name: __MODULE__)
    end

    def get(network, key), do: Agent.get(__MODULE__, &(&1[network][key]))

    def put(network, key, value) do
      if key == :layer1 do
        Outboxer.Query.l1_set_finalised_level(network, value)
      else
        Agent.update(__MODULE__, &Map.put(&1, network, Map.put(&1[network], key, value)))
      end

      PubSub.broadcast(Outboxer.PubSub, "#{network}-levels", {key, value})
    end
  end

  defmodule Rollup do
    use Agent
    alias Phoenix.PubSub

    def start_link(_opts) do
      flex_nodes = Outboxer.Nodes.flextesa()
      ghost_nodes = Outboxer.Nodes.ghostnet_etherlink()
      flex_address = Outboxer.Rollup.address(flex_nodes)
      eth_address = Outboxer.Rollup.address(ghost_nodes)
      state = %{flex_nodes.network => {flex_address, []}, ghost_nodes.network => {eth_address, []}}
      Agent.start_link(fn -> state end, name: __MODULE__)
    end

    def address(network) do
      Agent.get(__MODULE__, fn %{^network => {address, _}} -> address end)
    end

    def messages(network) do
      Agent.get(__MODULE__, fn %{^network => {_, messages}} -> messages end)
    end

    def add_messages(network, messages) do
      Agent.update(__MODULE__, fn %{^network => {address, m}} = state -> %{state | network => {address, messages ++ m}} end)
      PubSub.broadcast(Outboxer.PubSub, "#{network}-outbox", {:outbox, messages})
    end
  end
end
