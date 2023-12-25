defmodule Outboxer.Rollup do
  def address(nodes) do
    fetch!(nodes, "global/smart_rollup_address")
  end

  def levels(nodes) do
    finalised = fetch!(nodes, "global/block/finalized/state_current_level")
    cemented =  fetch!(nodes, "global/block/cemented/state_current_level")
    %{finalised: finalised, cemented: cemented}
  end

  def outbox_at(nodes, level) do
    fetch!(nodes, "global/block/finalized/outbox/#{level}/messages")
    |> Enum.map(fn %{"outbox_level" => l, "message_index" => i, "message" => %{"transactions" => t, "kind" => kind}} ->
    {l, String.to_integer(i), kind, transcode t} end)
    |> Enum.to_list
    |> Enum.sort_by(fn {_, i, _, _} -> i end)
  end

  # FIXME: XXX
  def proof(level, index) do
    {res, 0} = System.cmd("/home/emma/sources/outboxer/scripts/srclient.sh",
               ["get", "proof", "for", "message", "#{index}", "of", "outbox", "at", "level", "#{level}"])

    Poison.decode! res
  end

  def transcode([]), do: []
  def transcode([%{"parameters" => parameters, "destination" => destination} | rest]) do
    parameters = Outboxer.Layer1.transcode_json_to_micheline(parameters)
    [%{destination: destination, parameters: parameters} | transcode(rest)]
  end
  def transcode(batch), do: Poison.encode! batch

  defp fetch!(%Outboxer.Nodes{rollup: node}, rpc) do
    %HTTPoison.Response{body: body} = HTTPoison.get! "#{node}/#{rpc}"
    IO.inspect("#{node} #{rpc} => #{body}")
    Poison.decode! body
  end
end
