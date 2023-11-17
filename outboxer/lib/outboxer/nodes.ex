defmodule Outboxer.Nodes do
  defstruct [:network, :l1, :rollup]

  @flextesa_l1 "http://localhost:20000"
  @flextesa_rollup "http://localhost:20010"

  @ghostnet_l1 "http://et-tanpi-0:8733"
  @ghostnet_etherlink "http://et-tanpi-0:8932"

  def flextesa() do
    %Outboxer.Nodes{network: "flextesa", l1: @flextesa_l1, rollup: @flextesa_rollup}
  end

  def ghostnet_etherlink() do
    %Outboxer.Nodes{network: "ghostnet", l1: @ghostnet_l1, rollup: @ghostnet_etherlink}
  end
end
