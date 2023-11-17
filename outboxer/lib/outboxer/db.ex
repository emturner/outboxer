defmodule Outboxer.Db do
  defmodule Layer1 do
    use Ecto.Schema

    @primary_key {:network, :string, autogenerate: false}
    schema "layer1" do
      field(:finalised_level, :integer)
      field(:minimal_block_delay, :integer)
      field(:max_active_outbox_levels, :integer)
    end

    def changeset(network, params \\ %{}) do
      network
      |> Ecto.Changeset.cast(params, [:network, :finalised_level, :minimal_block_delay, :max_active_outbox_levels])
      |> Ecto.Changeset.unique_constraint(:network, name: :layer1_pkey)
    end
  end
end
