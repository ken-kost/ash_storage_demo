defmodule AshStorageDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        AshStorageDemoWeb.Telemetry,
        AshStorageDemo.Repo,
        {DNSCluster, query: Application.get_env(:ash_storage_demo, :dns_cluster_query) || :ignore},
        {Oban,
         AshOban.config(
           Application.fetch_env!(:ash_storage_demo, :ash_domains),
           Application.fetch_env!(:ash_storage_demo, Oban)
         )},
        {Phoenix.PubSub, name: AshStorageDemo.PubSub},
        # Start a worker by calling: AshStorageDemo.Worker.start_link(arg)
        # {AshStorageDemo.Worker, arg},
        # Start to serve requests, typically the last entry
        AshStorageDemoWeb.Endpoint,
        {AshAuthentication.Supervisor, [otp_app: :ash_storage_demo]}
      ] ++ volume_usage_initial_fetch()

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

  # Cron fires every 5 minutes; this Task fills the cache once on boot so
  # the home page has a value immediately after a fresh deploy. Disabled in
  # test (no MinIO running, no point talking to S3 from CI).
  defp volume_usage_initial_fetch do
    if Application.get_env(:ash_storage_demo, :volume_usage_boot_fetch?, true) do
      [
        Supervisor.child_spec(
          {Task, fn -> AshStorageDemo.Storage.VolumeUsage.refresh() end},
          id: :volume_usage_initial_fetch,
          restart: :temporary
        )
      ]
    else
      []
    end
  end
end
