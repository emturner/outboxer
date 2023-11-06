defmodule OutboxerWeb.PageLive do
  use OutboxerWeb, :live_view
  alias Phoenix.PubSub

  def mount(_params, _conn, socket) do
    socket = assign(socket,
                    tezos_level: Outboxer.Core.Levels.get(:layer1),
                    rollup_address: Outboxer.Core.Rollup.address(),
                    rollup_finalised: Outboxer.Core.Levels.get(:finalised),
                    rollup_cemented: Outboxer.Core.Levels.get(:cemented),
                    outbox: Outboxer.Core.Rollup.messages(),
                    constants: Outboxer.Core.Constants.all())

    if connected?(socket) do
      PubSub.subscribe(Outboxer.PubSub, "levels")
      PubSub.subscribe(Outboxer.PubSub, "outbox")
    end

    {:ok, socket}
  end

  ####################
  # Execution handling
  ####################
  def handle_event("execute", %{"level" => level, "index" => index}, socket) do
    IO.inspect "Execution requested for level #{level} and index #{index}"

    proof = Outboxer.Rollup.proof(level, index)
    Outboxer.Layer1.execute(Outboxer.Core.Rollup.address(), proof)

    # TODO:
    # - show reciepts on success; disable execute button
    # - show error on failure; disable execute button if level expired

    {:noreply, socket}
  end

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
end
