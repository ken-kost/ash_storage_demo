defmodule AshStorageDemo.Storage.VolumeUsage.Worker do
  @moduledoc """
  Periodic Oban job that refreshes the cached volume usage. Scheduled via
  `Oban.Plugins.Cron` in `config/config.exs`.
  """

  use Oban.Worker, queue: :default, max_attempts: 1

  alias AshStorageDemo.Storage.VolumeUsage

  @impl Oban.Worker
  def perform(_job) do
    case VolumeUsage.refresh() do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
