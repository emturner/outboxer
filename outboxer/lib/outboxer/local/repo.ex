defmodule Outboxer.Local.Repo do
  use Ecto.Repo,
    otp_app: :outboxer,
    adapter: Ecto.Adapters.Postgres
end
