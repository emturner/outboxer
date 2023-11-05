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
      Process.send_after(self(), :tezos_level, 100)
      Process.send_after(self(), :rollup_level, 100)
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

  ###################
  # TODO
  # The code below is all handling business logic for updating backend state
  # This should really live on the backed!!
  ###################
  def handle_info(:tezos_level, socket) do
    block_time = socket.assigns.constants.block_time_ms
    level = Outboxer.Layer1.level()
    Outboxer.Core.Levels.put(:layer1, level)
    socket = assign(socket, tezos_level: level)
    Process.send_after(self(), :tezos_level, block_time)

    {:noreply, socket}
  end

  def handle_info(:rollup_level, socket) do
    block_time = socket.assigns.constants.block_time_ms
    levels = Outboxer.Rollup.levels()
    outbox = Outboxer.Rollup.outbox_at(levels.finalised)

    Outboxer.Core.Rollup.add_messages(outbox)
    Outboxer.Core.Levels.put(:finalised, levels[:finalised])
    Outboxer.Core.Levels.put(:cemented, levels[:cemented])

    socket = assign(socket, rollup_levels: levels,
                            outbox: outbox ++ socket.assigns.outbox)


    Process.send_after(self(), :rollup_level, block_time)

    {:noreply, socket}
  end
end
