defmodule Outboxer.Rollup do
  @node "http://localhost:20010"

  def address() do
    %HTTPoison.Response{body: address} = fetch! "global/smart_rollup_address"
    Poison.decode! address
  end

  def levels() do
    %HTTPoison.Response{body: body} = HTTPoison.get! "http://localhost:20010/global/block/finalized/state_current_level"
    finalised = Poison.decode! body
    %HTTPoison.Response{body: body} = HTTPoison.get! "http://localhost:20010/global/block/cemented/state_current_level"
    cemented = Poison.decode! body
    %{finalised: finalised, cemented: cemented}
  end

  def outbox_at(level) do
    %HTTPoison.Response{body: body} = HTTPoison.get! "http://localhost:20010/global/block/finalized/outbox/#{level}/messages"
    (Poison.decode! body)
    |> Enum.map(fn %{"outbox_level" => l, "message_index" => i, "message" => %{"transactions" => t, "kind" => kind}} ->
    {l, i, kind, Poison.encode! t} end)
    |> Enum.to_list
    |> Enum.sort_by(fn {_, i, _, _} -> i end)
  end

  def fetch!(rpc), do: HTTPoison.get! "#{@node}/#{rpc}"
end
