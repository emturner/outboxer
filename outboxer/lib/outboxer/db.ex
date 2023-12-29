defmodule Outboxer.Db do
  defmodule Layer1 do
    use Ecto.Schema

    @primary_key {:network, :string, autogenerate: false}
    schema "layer1" do
      field :finalised_level, :integer 
      field :minimal_block_delay, :integer 
      field :max_active_outbox_levels, :integer 
    end

    def changeset(network, params \\ %{}) do
      network
      |> Ecto.Changeset.cast(params, [:network, :finalised_level, :minimal_block_delay, :max_active_outbox_levels])
      |> Ecto.Changeset.unique_constraint(:network, name: :layer1_pkey)
    end
  end

  defmodule Rollup do
    use Ecto.Schema

    @primary_key {:address, :string, autogenerate: false}
    schema "rollups" do
      field :finalised_level, :integer 
      field :cemented_level, :integer 
    end

    def changeset(address, params \\ %{}) do
      address
      |> Ecto.Changeset.cast(params, [:address, :finalised_level, :cemented_level])
      |> Ecto.Changeset.unique_constraint(:address, name: :rollups_pkey)
    end
  end

  defmodule Outbox do
    use Ecto.Schema

    schema "outboxes" do
      field :level, :integer 
      field :index, :integer 
      field :kind, :string
      field :contents, :string
      field :executed, :boolean
      field :op_hash, :string

      belongs_to :rollups, Outbox, foreign_key: :rollup, references: :address, type: :string
    end

    def changeset(%__MODULE__{} = id, params \\ %{}) do
      id
      |> Ecto.Changeset.cast(params, [:id, :executed, :op_hash])
      |> IO.inspect
    end
  end
end
