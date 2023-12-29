defmodule Outboxer.Local.Repo.Migrations.OutboxIsExecuted do
  use Ecto.Migration

  # Operation hash (if successfull)
  # bool: true if applied, false if application failed

  def change do
    alter table(:outboxes) do
      add :executed, :bool
      add :op_hash, :char, size: 51
    end
  end
end
