defmodule Outboxer.Core do
  defmodule Levels do
    alias Phoenix.PubSub

    def update(network, key, value) do
      case key do
        :layer1 ->
          Outboxer.Query.l1_set_finalised_level(network, value)
          PubSub.broadcast(Outboxer.PubSub, "#{network}-levels", {:layer1, value})
        {address, :rollup} ->
          Outboxer.Query.rollup_set_finalised_level(address, value)
          PubSub.broadcast(Outboxer.PubSub, "#{network}-levels", {:rollup, value})
        {address, :cemented} ->
          Outboxer.Query.rollup_set_cemented_level(address, value)
          PubSub.broadcast(Outboxer.PubSub, "#{network}-levels", {:cemented, value})
      end
    end
  end

  defmodule Rollup do
    alias Phoenix.PubSub

    @executed_regex ~r/Operation hash is \'(.*?)\'/

    def add_messages(network, messages) do
      messages = Enum.map(messages, &Outboxer.Query.rollup_set_outbox/1)
      PubSub.broadcast(Outboxer.PubSub, "#{network}-outbox", {:outbox, messages})
    end

    def execute_message(network, %Outboxer.Message{} = m) do

      proof = Outboxer.Rollup.proof(network, m.level, m.index)
      res = Outboxer.Layer1.execute(network, m.rollup, proof)

      m = case res do
        {output, 0} ->
          hash = op_hash_from_result(output)
          %{ m | execution_successful: true, operation_hash: hash }
        _ -> %{ m | execution_successful: false, operation_hash: nil }
      end
      # FIXME: handle already executed

      Outboxer.Query.rollup_set_execution_status(m)
      PubSub.broadcast(Outboxer.PubSub, "#{network}-outbox", {:executed, m})
    end

    defp op_hash_from_result(output) do
      case Regex.run(@executed_regex, output) do
        [_, hash] -> hash
        _ -> nil
      end
    end
  end
end
