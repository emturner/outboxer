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

    def add_messages(network, messages) do
      for m <- messages do
        Outboxer.Query.rollup_set_outbox(m)
      end

      PubSub.broadcast(Outboxer.PubSub, "#{network}-outbox", {:outbox, messages})
    end
  end
end
