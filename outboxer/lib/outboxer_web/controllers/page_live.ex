defmodule OutboxerWeb.PageLive do
  use OutboxerWeb, :live_view

  def mount(_params, _conn, socket) do
    socket = assign(socket, tezos_level: "", rollup_address: "", rollup_levels: %{}, outbox: [])
    if connected?(socket) do
      Process.send_after(self(), :constants, 100)
      Process.send_after(self(), :rollup_address, 100)
    end

    {:ok, socket}
  end

  def handle_info(:constants, socket) do
    proto_constants = proto_constants()
    socket = assign(socket, constants: proto_constants)

    Process.send_after(self(), :tezos_level, 100)
    Process.send_after(self(), :rollup_level, 100)

    {:noreply, socket}
  end

  def handle_info(:tezos_level, socket) do
    block_time = socket.assigns.constants.block_time_ms
    level = tezos_level()
    socket = assign(socket, tezos_level: level)
    Process.send_after(self(), :tezos_level, block_time)

    {:noreply, socket}
  end

  def handle_info(:rollup_level, socket) do
    block_time = socket.assigns.constants.block_time_ms
    levels = rollup_levels()
    outbox = outbox_at(levels.finalised)

    socket = assign(socket, rollup_levels: levels,
                            outbox: new_outbox(socket.assigns.outbox, levels.finalised, outbox))

    Process.send_after(self(), :rollup_level, block_time)

    {:noreply, socket}
  end

  def new_outbox([], level, messages), do: [{level, messages}]
  def new_outbox([{prev, nil} | rest], level, messages), do: [{level, messages} | rest]
  def new_outbox(outbox, level, messages), do: [{level, messages} | outbox]

  def handle_info(:rollup_address, socket) do
    address = rollup_address()
    socket = assign(socket, rollup_address: address)

    {:noreply, socket}
  end

  def proto_constants() do
    %HTTPoison.Response{body: body} = HTTPoison.get! "http://localhost:20000/chains/main/blocks/head-1/context/constants"
    %{"minimal_block_delay" => block_time} = Poison.decode! body
    {block_time, _} = Integer.parse block_time
    %{block_time_ms: block_time * 1000}
  end

  def tezos_level() do
    %HTTPoison.Response{body: body} = HTTPoison.get! "http://localhost:20000/chains/main/blocks/head-1/header/shell"
    %{"level" => level} = Poison.decode! body
    level
  end

  def rollup_levels() do
    %HTTPoison.Response{body: body} = HTTPoison.get! "http://localhost:20010/global/block/finalized/state_current_level"
    finalised = Poison.decode! body
    %HTTPoison.Response{body: body} = HTTPoison.get! "http://localhost:20010/global/block/cemented/state_current_level"
    cemented = Poison.decode! body
    %{finalised: finalised, cemented: cemented}
  end

  def outbox_at(level) do
    %HTTPoison.Response{body: body} = HTTPoison.get! "http://localhost:20010/global/block/finalized/outbox/#{level}/messages"
    messages = Poison.decode! body
    if (not Enum.empty? messages), do: Poison.encode! messages
  end

  def rollup_address() do
    %HTTPoison.Response{body: address} = HTTPoison.get! "http://localhost:20010/global/smart_rollup_address"
    Poison.decode! address
  end
end
