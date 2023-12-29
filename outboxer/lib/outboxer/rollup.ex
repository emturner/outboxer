defmodule Outboxer.Rollup do
  def address(nodes) do
    fetch!(nodes, "global/smart_rollup_address")
  end

  def levels(nodes) do
    finalised = fetch!(nodes, "global/block/finalized/state_current_level")
    cemented =  fetch!(nodes, "global/block/cemented/state_current_level")
    %{finalised: finalised, cemented: cemented}
  end

  def outbox_at(nodes, address, level) do
    fetch!(nodes, "global/block/finalized/outbox/#{level}/messages")
    |> Enum.map(fn %{"outbox_level" => l, "message_index" => i, "message" => %{"transactions" => t, "kind" => kind}} ->
      %Outboxer.Message{
        rollup: address,
        level: l,
        index: String.to_integer(i),
        kind: kind,
        contents: transcode(t)
      } end)
    |> Enum.to_list
    |> Enum.sort_by(&(&1.index))
  end

  def proof("flextesa", level, index) do
    {res, 0} = System.cmd("/home/emma/sources/outboxer/scripts/srclient.sh",
                          ["get", "proof", "for", "message", "#{index}", "of", "outbox",
                           "at", "level", "#{level}"])

    Poison.decode! res
  end

  def proof("ghostnet", level, index) do
    # nodes = Outboxer.Nodes.ghostnet_etherlink()
    # res = fetch!(nodes, "global/block/head/helpers/proofs/outbox/#{level}/messages?index=#{index}")
    # |> IO.inspect
    # res = Poison.decode! res
    # |> IO.inspect
    # %{ res | proof: "0x" <> res.proof }

    {res, 0} = System.cmd("/home/emma/sources/outboxer/scripts/ghost-srclient.sh",
                          ["get", "proof", "for", "message", "#{index}", "of", "outbox",
                           "at", "level", "#{level}"])

    Poison.decode! res
  end

  def transcode(batch), do: batch |> Enum.map(&to_transfer/1)

  defp to_transfer(%{"parameters" => p, "destination" => d}) do
    p = Outboxer.Layer1.transcode_json_to_micheline(p)
    %Outboxer.Message.Transfer{parameters: p, destination: d}
  end

  defp fetch!(%Outboxer.Nodes{rollup: node}, rpc) do
    %HTTPoison.Response{body: body} = HTTPoison.get! "#{node}/#{rpc}"
    IO.inspect("#{node} #{rpc} => #{body}")
    Poison.decode! body
  end
end
