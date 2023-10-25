defmodule OutboxerWeb.PageLive do
  use OutboxerWeb, :live_view

  def mount(_params, _conn, socket) do
    socket = assign(socket,
                    tezos_level: Outboxer.Core.Levels.get(:layer1),
                    rollup_address: Outboxer.Core.Rollup.address(),
                    rollup_levels: %{finalised: Outboxer.Core.Levels.get(:finalised),
                                     cemented: Outboxer.Core.Levels.get(:cemented)},
                    outbox: Outboxer.Core.Rollup.messages())

    if connected?(socket) do
      Process.send_after(self(), :constants, 100)
    end

    {:ok, socket}
  end

  def handle_info(:constants, socket) do
    block_time = Outboxer.Core.Constants.get(:block_time_ms)

    constants = %{block_time_ms: block_time}

    Process.send_after(self(), :tezos_level, 100)
    Process.send_after(self(), :rollup_level, 100)

    socket = assign(socket, constants: constants)
    {:noreply, socket}
  end

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
