defmodule OutboxerWeb.PageLive do
  use OutboxerWeb, :live_view
  alias Phoenix.PubSub

  @rollup_fields [:finalised_level, :cemented_level]

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
    tl = Outboxer.Query.l1_finalised_level(network)
    ra = address_from_network(network)
    %Outboxer.Db.Rollup{finalised_level: fl, cemented_level: cl}
                             = Outboxer.Query.rollup(ra, @rollup_fields)
    outbox = ra
    |> Outboxer.Query.rollup_outboxes
    |> Enum.map(&to_display_outboxes/1)

    assign(socket,
           network: network,
           tezos_level: tl,
           rollup_address: ra,
           rollup_finalised: fl,
           rollup_cemented: cl,
           outbox: outbox)
  end

  defp to_display_outboxes(%Outboxer.Db.Outbox{level: l, index: i, kind: k, contents: c}) do
    c = Poison.decode!(c)
    {l, i, k, c}
  end

  # FIXME
  defp address_from_network("flextesa"), do: "sr1HvQTFrxfiJNVmY98KvDGWvbouNrkU1kyP"
  defp address_from_network("ghostnet"), do: "sr1HFDt5ZwBVcXTgLA4wQ9vtwMH7EKU5vMFr"
end
