defmodule OutboxerWeb.PageLive do
  use OutboxerWeb, :live_view
  alias Phoenix.PubSub

  def mount(_params, _conn, socket) do
    network = "flextesa"

    if connected?(socket) do
      PubSub.subscribe(Outboxer.PubSub, "#{network}-levels")
      PubSub.subscribe(Outboxer.PubSub, "#{network}-outbox")
    end

    {:ok, init(socket, network)}
  end

  ####################
  # Event handling
  ####################
  def handle_event("select-network", %{"network" => network}, socket) do
    IO.inspect("switched network #{network}")
    old_network = socket.assigns.network

    res = if network <> old_network do
      PubSub.unsubscribe(Outboxer.PubSub, "#{old_network}-levels")
      PubSub.unsubscribe(Outboxer.PubSub, "#{old_network}-outbox")

      {:noreply, init(socket, network)}
    else
      {:noreply, socket}
    end

    PubSub.subscribe(Outboxer.PubSub, "#{network}-levels")
    PubSub.subscribe(Outboxer.PubSub, "#{network}-outbox")

    res
  end

  ###############
  # PubSub events
  ###############

  def handle_info({:layer1, x}, socket) do
    {:noreply, assign(socket, tezos_level: x)}
  end
  def handle_info({:rollup, x}, socket) do
    {:noreply, assign(socket, rollup_finalised: x)}
  end
  def handle_info({:cemented, x}, socket) do
    {:noreply, assign(socket, rollup_cemented: x)}
  end
  def handle_info({:outbox, []}, socket), do: {:noreply, socket}
  def handle_info({:outbox, new_messages}, socket) do
    {:noreply, assign(socket, outbox: new_messages ++ socket.assigns.outbox)}
  end

  defp init(socket, network) do
    assign(socket,
           network: network,
           tezos_level: Outboxer.Core.Levels.get(network, :layer1),
           rollup_address: Outboxer.Core.Rollup.address(network),
           rollup_finalised: Outboxer.Core.Levels.get(network, :rollup),
           rollup_cemented: Outboxer.Core.Levels.get(network, :cemented),
           outbox: Outboxer.Core.Rollup.messages(network))
  end
end
