defmodule Outboxer.Query do
  import Ecto.Query

  def l1_finalised_level(network) do
    (from l1 in Outboxer.Db.Layer1,
        where: l1.network == ^network,
        select: l1.finalised_level)
    |> Outboxer.Local.Repo.one
  end

  def l1_set_finalised_level(network, level) do
    %Outboxer.Db.Layer1{network: network}
    |> Outboxer.Db.Layer1.changeset(%{finalised_level: level})
    |> Outboxer.Local.Repo.update
  end

  def l1(network, fields) do
    (from l1 in Outboxer.Db.Layer1,
          where: l1.network == ^network,
          select: ^fields)
    |> Outboxer.Local.Repo.one
  end

  def rollup_finalised_level(address) do
    (from rollup in Outboxer.Db.Rollup,
      where: rollup.address == ^address,
      select: rollup.finalised_level)
    |> Outboxer.Local.Repo.one
  end

  def rollup_set_finalised_level(address, level) do
    %Outboxer.Db.Rollup{address: address}
    |> Outboxer.Db.Rollup.changeset(%{finalised_level: level})
    |> Outboxer.Local.Repo.update
  end

  def rollup_cemented_level(address) do
    (from rollup in Outboxer.Db.Rollup,
      where: rollup.address == ^address,
      select: rollup.cemented_level)
    |> Outboxer.Local.Repo.one
  end

  def rollup_set_cemented_level(address, level) do
    %Outboxer.Db.Rollup{address: address}
    |> Outboxer.Db.Rollup.changeset(%{cemented_level: level})
    |> Outboxer.Local.Repo.update
  end

  def rollup(address, fields) do
    (from l1 in Outboxer.Db.Rollup,
          where: l1.address == ^address,
          select: ^fields)
    |> Outboxer.Local.Repo.one
  end

  def rollup_set_outbox(%Outboxer.Message{} = message) do 
    message
    |> Outboxer.Message.to_db
    |> Outboxer.Local.Repo.insert
    |> (fn {:ok, %{id: id}} ->  %{ message | id: id} end).()
  end

  def rollup_outboxes(address) do
    (from o in Outboxer.Db.Outbox,
      where: o.rollup == ^address,
      order_by: [desc: :level, desc: :index],
      limit: 30)
    |> Outboxer.Local.Repo.all
    |> Enum.map(&Outboxer.Message.from_db/1)
  end

  def rollup_set_execution_status(%Outboxer.Message{id: id} = message) do
    params = message |> Outboxer.Message.to_db |> Map.from_struct
    %Outboxer.Db.Outbox{id: id}
    |> Outboxer.Db.Outbox.changeset(params)
    |> Outboxer.Local.Repo.update
  end
end
