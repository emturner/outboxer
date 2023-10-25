defmodule Outboxer.Layer1 do
  @node "http://localhost:20000"

  def level() do
    %HTTPoison.Response{body: body} = fetch! "header/shell"
    %{"level" => level} = Poison.decode! body
    level
  end

  def proto_constants() do
    %HTTPoison.Response{body: body} = fetch! "context/constants"
    %{"minimal_block_delay" => block_time} = Poison.decode! body
    {block_time, _} = Integer.parse block_time
    %{block_time_ms: block_time * 1000}
  end

  def outbox_at(level) do
    %HTTPoison.Response{body: body} = HTTPoison.get! "http://localhost:20010/global/block/finalized/outbox/#{level}/messages"
    (Poison.decode! body)
    |> Enum.map(fn %{"outbox_level" => l, "message_index" => i, "message" => %{"transactions" => t, "kind" => kind}} ->
    {l, i, kind, Poison.encode! t} end)
    |> Enum.to_list
    |> Enum.sort_by(fn {_, i, _, _} -> i end)
  end

  def fetch!(rpc), do: HTTPoison.get! "#{@node}/chains/main/blocks/head-1/#{rpc}"
end
