defmodule Outboxer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OutboxerWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:outboxer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Outboxer.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Outboxer.Finch},
      # Start a worker by calling: Outboxer.Worker.start_link(arg)
      # {Outboxer.Worker, arg},
      # Start to serve requests, typically the last entry
      OutboxerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Outboxer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OutboxerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
