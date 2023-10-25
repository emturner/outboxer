defmodule Outboxer.Rollup do
  @node "http://localhost:20010"

  def address() do
    fetch! "global/smart_rollup_address"
  end

  def levels() do
    finalised = fetch! "global/block/finalized/state_current_level"
    cemented =  fetch! "global/block/cemented/state_current_level"
    %{finalised: finalised, cemented: cemented}
  end

  def outbox_at(level) do
    (fetch! "global/block/finalized/outbox/#{level}/messages")
    |> Enum.map(fn %{"outbox_level" => l, "message_index" => i, "message" => %{"transactions" => t, "kind" => kind}} ->
    {l, i, kind, Poison.encode! t} end)
    |> Enum.to_list
    |> Enum.sort_by(fn {_, i, _, _} -> i end)
  end

  def proof(level, index) do
    {res, 0} = System.cmd("/home/emma/sources/outboxer/scripts/srclient.sh",
               ["get", "proof", "for", "message", "#{index}", "of", "outbox", "at", "level", "#{level}"])

    Poison.decode! res
  end

  def fetch!(rpc) do
    %HTTPoison.Response{body: body} = HTTPoison.get! "#{@node}/#{rpc}"
    Poison.decode! body
  end
end
