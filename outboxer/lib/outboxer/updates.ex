defmodule Outboxer.Updates do
  use GenServer

  @l1_fields [:finalised_level, :minimal_block_delay]
  @rollup_fields [:finalised_level, :cemented_level]

  def init(state) do
    setup_l1_constants(state.nodes)
    address = setup_rollup(state.nodes)

    %{finalised_level: tezos_level, minimal_block_delay: bt}
                        = Outboxer.Query.l1(state.nodes.network, @l1_fields)

    %{finalised_level: rollup_level, cemented_level: cemented_level}
                        = Outboxer.Query.rollup(address, @rollup_fields)

    state = %{ state | tezos_level: tezos_level,
                       block_time_ms: bt,
                       rollup_level: rollup_level,
                       rollup_cemented: cemented_level,
                       rollup_address: address}

    fetch_next_tezos_level(bt)

    {:ok, state}
  end

  def start_link(name: name, nodes: nodes) do
    GenServer.start_link(
      __MODULE__,
      %{tezos_level: nil,
        block_time_ms: nil,
        rollup_level: nil,
        rollup_cemented: nil,
        rollup_address: nil,
        nodes: nodes},
      name: name)
  end

  def handle_info(:tezos_level, %{tezos_level: tezos_level, block_time_ms: block_time} = state) do
    level = Outboxer.Layer1.level(state.nodes)

    if level > tezos_level do
      Outboxer.Core.Levels.update(state.nodes.network, :layer1, level)

      index_rollup_at(level)
      fetch_next_tezos_level(block_time)
    else
      fetch_next_tezos_level(1000)
    end

    {:noreply, %{state | tezos_level: level}}
  end

  def handle_info(:wait_for_rollup_level, %{rollup_level: nil} = state) do
    # TODO: improve startup procedure
    %{finalised: finalised, cemented: cemented} = Outboxer.Rollup.levels(state.nodes)

    for l <- cemented..finalised do
      index_rollup_outbox_at(l)
    end

    {:noreply, %{ state | rollup_level: finalised, rollup_cemented: cemented}}
  end

  def handle_info(:wait_for_rollup_level, state) do
    if state.tezos_level > state.rollup_level do
      %{finalised: finalised, cemented: cemented} = Outboxer.Rollup.levels(state.nodes)

      if state.rollup_cemented == nil or cemented > state.rollup_cemented do
        Outboxer.Core.Levels.update(state.nodes.network, {state.rollup_address, :cemented}, cemented)
      end

      if finalised > state.rollup_level do
        Outboxer.Core.Levels.update(state.nodes.network, {state.rollup_address, :rollup}, finalised)

        for l <- (state.rollup_level + 1)..finalised do
          index_rollup_outbox_at(l)
        end
      end
      {:noreply, %{state | rollup_cemented: cemented, rollup_level: finalised}}
    else
      {:noreply, state}
    end
  end

  def handle_info({:index_outbox, level}, state) do
    outbox = Outboxer.Rollup.outbox_at(state.nodes, level)
    Outboxer.Core.Rollup.add_messages(state.nodes.network, outbox)

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

  defp setup_l1_constants(nodes) do
    c = Outboxer.Layer1.proto_constants(nodes)

    %Outboxer.Db.Layer1{network: nodes.network}
    |> Outboxer.Db.Layer1.changeset(%{minimal_block_delay: c.block_time_ms,
                                      max_active_outbox_levels: c.max_active_outbox_levels})
    |> Outboxer.Local.Repo.insert_or_update
    c
  end

  defp setup_rollup(nodes) do
    address = Outboxer.Rollup.address(nodes)

    %Outboxer.Db.Rollup{address: address}
    |> Outboxer.Db.Rollup.changeset(%{})
    |> Outboxer.Local.Repo.insert_or_update

    address
  end
end
