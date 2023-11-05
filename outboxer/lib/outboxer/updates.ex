defmodule Outboxer.Updates do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{
      tezos_level: Outboxer.Core.Levels.get(:layer1),
      rollup_level: Outboxer.Core.Levels.get(:rollup),
      rollup_cemented: Outboxer.Core.Levels.get(:cemented),
      block_time_ms: Outboxer.Core.Constants.get(:block_time_ms)
    })
  end

  def init(%{block_time_ms: block_time_ms} = state) do
    fetch_next_tezos_level(block_time_ms)
    {:ok, state}
  end

  def handle_info(:tezos_level, %{tezos_level: tezos_level, block_time_ms: block_time} = state) do
    level = Outboxer.Layer1.level()

    if level > tezos_level do
      Outboxer.Core.Levels.put(:layer1, level)

      index_rollup_at(level)
      fetch_next_tezos_level(block_time)
    else
      fetch_next_tezos_level(1000)
    end

    {:noreply, %{state | tezos_level: level}}
  end

  def handle_info(:wait_for_rollup_level, %{rollup_level: nil} = state) do
    # TODO: improve startup procedure
    %{finalised: finalised, cemented: cemented} = Outboxer.Rollup.levels()
    {:noreply, %{ state | rollup_level: finalised, rollup_cemented: cemented}}
  end

  def handle_info(:wait_for_rollup_level, state) when state.tezos_level > state.rollup_level do
    %{finalised: finalised, cemented: cemented} = Outboxer.Rollup.levels()

    if cemented > state.rollup_cemented or state.rollup_cemented == nil do
      Outboxer.Core.Levels.put(:cemented, cemented)
    end

    if finalised > state.rollup_level do
      Outboxer.Core.Levels.put(:rollup, finalised)

      for l <- (state.rollup_level + 1)..finalised do
        index_rollup_outbox_at(l)
      end
    end

    {:noreply, %{state | rollup_cemented: cemented, rollup_level: finalised}}
  end

  def handle_info({:index_outbox, level}, state) do
    outbox = Outboxer.Rollup.outbox_at(level)
    Outboxer.Core.Rollup.add_messages(outbox)

    {:noreply, state}
  end

  def handle_info(msg, state) do
    IO.inspect({"UNHANDLED", msg, state})
    {:noreply, state}
  end

  defp fetch_next_tezos_level(wait) do
    Process.send_after(self(), :tezos_level, wait)
  end

  defp index_rollup_at(_level) do
    Process.send_after(self(), :wait_for_rollup_level, 100)
  end

  defp index_rollup_outbox_at(level) do
    send(self(), {:index_outbox, level})
  end
end
