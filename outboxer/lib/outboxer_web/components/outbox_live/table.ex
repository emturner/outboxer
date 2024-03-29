defmodule OutboxerWeb.Components.OutboxLive.Table do
  use OutboxerWeb, :live_component

  alias Outboxer.Query

  @l1_fields [:finalised_level, :max_active_outbox_levels]

  def mount(socket) do
    {:ok, socket}
  end

  def update(updates, socket) do
    l1 = Query.l1(updates[:network], @l1_fields)

    socket = assign(socket,
                    network: updates[:network],
                    tezos_level: l1.finalised_level,
                    rollup_address: updates[:rollup_address],
                    rollup_finalised: updates[:rollup_finalised],
                    rollup_cemented: updates[:rollup_cemented],
                    outbox: updates[:outbox],
                    max_active_outbox_levels: l1.max_active_outbox_levels)

    {:ok, socket}
  end

  ####################
  # Event handling
  ####################
  def handle_event("execute", %{"level" => level, "index" => index}, socket) do
    IO.inspect "Execution requested for level #{level} and index #{index}"

    m = Enum.find(socket.assigns.outbox,
                  fn %{level: l, index: i} ->
                    "#{l}" == level and "#{i}" == index end)

    Outboxer.Core.Rollup.execute_message(socket.assigns.network, m)

    {:noreply, socket}
  end
end
