defmodule Outboxer.Local.Repo.Migrations.CreateOutboxer do
  use Ecto.Migration

  def change do
    create table(:layer1, primary_key: false) do
      add :network, :string, primary_key: true
      add :finalised_level, :integer
      add :minimal_block_delay, :integer
      add :max_active_outbox_levels, :integer
    end

    create table(:rollups, primary_key: false) do
      add :address, :string, primary_key: true
      add :finalised_level, :integer
      add :cemented_level, :integer
    end

    create table(:outboxes) do
      add :rollup, references(:rollups, column: :address, type: :string)
      add :level, :integer
      add :index, :integer
      add :kind, :string
      add :contents, :text
    end
  end
end
