defmodule AshStorageDemoWeb.DiskServeRuntime do
  @moduledoc """
  Thin wrapper around `AshStorage.Plug.DiskServe` that resolves its `:root`
  at request time from `Application.fetch_env!(:ash_storage_demo, :disk_storage)`.

  `AshStorage.Plug.DiskServe.init/1` captures `:root` at compile time, so a
  literal `forward "/files/documents", AshStorage.Plug.DiskServe, root: "priv/storage/documents"`
  would always read from the dev-default path even when the runtime config
  (driven by `DISK_STORAGE_ROOT` on Fly) writes uploads to a mounted volume.
  This wrapper bridges that gap.
  """

  @behaviour Plug

  @impl true
  def init(opts), do: %{name: Keyword.fetch!(opts, :name)}

  @impl true
  def call(conn, %{name: name}) do
    root =
      :ash_storage_demo
      |> Application.fetch_env!(:disk_storage)
      |> Keyword.fetch!(name)

    AshStorage.Plug.DiskServe.call(conn, AshStorage.Plug.DiskServe.init(root: root))
  end
end
