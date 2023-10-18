defmodule OutboxerWeb.PageLive do
  use OutboxerWeb, :live_view

  def mount(_params, _conn, socket) do
    socket = assign(socket, tezos_level: "")
    if connected?(socket), do: Process.send_after(self(), :constants, 100)

    {:ok, socket}
  end

  def handle_info(:constants, socket) do
    proto_constants = proto_constants()
    socket = assign(socket, constants: proto_constants)
    Process.send_after(self(), :tezos_level, 100)
    {:noreply, socket}
  end

  def handle_info(:tezos_level, socket) do
    block_time = socket.assigns.constants.block_time_ms
    level = tezos_level()
    socket = assign(socket, tezos_level: level)
    Process.send_after(self(), :tezos_level, block_time)

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
end
