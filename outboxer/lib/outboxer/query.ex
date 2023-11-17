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
end
