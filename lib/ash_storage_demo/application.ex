defmodule AshStorageDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AshStorageDemoWeb.Telemetry,
      AshStorageDemo.Repo,
      {DNSCluster, query: Application.get_env(:ash_storage_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AshStorageDemo.PubSub},
      # Start a worker by calling: AshStorageDemo.Worker.start_link(arg)
      # {AshStorageDemo.Worker, arg},
      # Start to serve requests, typically the last entry
      AshStorageDemoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AshStorageDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AshStorageDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
