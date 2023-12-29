defmodule Outboxer.Message do
  defstruct [:id, :rollup, :level, :index, :kind, :contents,
             :execution_successful, :operation_hash]

  def from_db(%Outboxer.Db.Outbox{id: id, rollup: r, level: l, index: i, kind: k, contents: c,
                                  executed: e, op_hash: o}) do
    %__MODULE__{
      id: id,
      rollup: r,
      level: l,
      index: i,
      kind: k,
      execution_successful: e,
      operation_hash: o,
      contents: c |> Poison.decode! |> Enum.map(&__MODULE__.Transfer.from/1)
    }
  end

  def to_db(%__MODULE__{id: id, rollup: r, level: l, index: i, kind: k, contents: c,
                        execution_successful: e, operation_hash: o}) do
    %Outboxer.Db.Outbox{
      id: id,
      rollup: r,
      level: l,
      index: i,
      kind: k,
      executed: e,
      op_hash: o,
      contents: Poison.encode!(c)
    }
  end

  defmodule Transfer do
    defstruct [:destination, :parameters]

    def from(%{"destination" => d, "parameters" => p}) do
      %__MODULE__{destination: d, parameters: p}
    end
  end
end
