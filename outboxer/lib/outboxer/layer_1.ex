defmodule Outboxer.Layer1 do
  @node "http://localhost:20000"

  def level() do
    %{"level" => level} = fetch! "header/shell"
    level
  end

  def proto_constants() do
    %{"minimal_block_delay" => block_time,
    "smart_rollup_max_active_outbox_levels" => max_active} = fetch! "context/constants"

    {block_time, _} = Integer.parse(block_time)

    %{block_time_ms: block_time * 1000, max_active_outbox_levels: max_active}
  end

  # TODO: calculate/lower bound on burn cap
  def execute(rollup, %{"proof" => proof, "commitment_hash" => hash}) do
    System.cmd("/home/emma/sources/outboxer/scripts/oclient.sh",
      ["execute", "outbox", "message", "of", "smart", "rollup", rollup,
        "from", "alice", "for", "commitment", "hash", hash,
          "and", "output", "proof", proof, "--burn-cap", "1"])
    |> IO.inspect
  end

  def transcode_json_to_micheline(json) do
    {res, 0} = System.cmd("/home/emma/sources/outboxer/scripts/oclient.sh",
                          (["convert", "data", "#{Poison.encode! json}", "from", "JSON", "to", "michelson"] |> IO.inspect))
    res
  end

  def fetch!(rpc) do
    %HTTPoison.Response{body: body} = HTTPoison.get! "#{@node}/chains/main/blocks/head-1/#{rpc}"
    Poison.decode! body
  end
end
