defmodule OutboxerWeb.PageLive do
  use OutboxerWeb, :live_view

  def mount(_params, _conn, socket) do
    socket = assign(socket,
                    tezos_level: Outboxer.Core.Levels.get(:layer1),
                    rollup_address: Outboxer.Core.Rollup.address(),
                    rollup_levels: %{finalised: Outboxer.Core.Levels.get(:finalised),
                                     cemented: Outboxer.Core.Levels.get(:cemented)},
                    outbox: Outboxer.Core.Rollup.messages(),
                    constants: Outboxer.Core.Constants.all())

    if connected?(socket) do
      Process.send_after(self(), :fetch, 100)
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

  def handle_info(:fetch, socket) do
    block_time = socket.assigns.constants.block_time_ms

    socket = assign(socket,
                    tezos_level: Outboxer.Core.Levels.get(:layer1),
                    rollup_levels: %{
                      finalised: Outboxer.Core.Levels.get(:rollup),
                      cemented: Outboxer.Core.Levels.get(:cemented)
                    },
                    outbox: Outboxer.Core.Rollup.messages())

    Process.send_after(self(), :fetch, block_time)
    {:noreply, socket}
  end
end
