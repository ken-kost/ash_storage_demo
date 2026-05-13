defmodule AshStorageDemoWeb.StorageAdminLive do
  @moduledoc """
  Admin LiveView for the storage backbone: lists every blob with its
  service, byte size, analyzer status pills, and a purge-orphan button.

  Counts orphan blobs (blob rows with no attachment in any of the three
  attachment tables) and lets an operator drop them in one click.
  """
  use AshStorageDemoWeb, :live_view

  import AshStorageDemoWeb.StorageComponents
  import Ecto.Query
  alias AshStorageDemo.Repo
  alias AshStorageDemo.Storage.{Blob, Orphans}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, reload(socket)}
  end

  @impl true
  def handle_event("purge-orphans", _, socket) do
    count = Orphans.purge_orphan_records()
    {:noreply, socket |> put_flash(:info, "Removed #{count} orphan blob record(s)") |> reload()}
  end

  defp reload(socket) do
    blobs =
      Blob
      |> Ash.Query.sort(id: :desc)
      |> Ash.read!(page: [limit: 50, count: false], authorize?: false)
      |> page_results()

    stats = build_stats()
    orphan_count = length(Orphans.orphan_blobs())

    socket
    |> assign(blobs: blobs)
    |> assign(stats: stats)
    |> assign(orphan_count: orphan_count)
  end

  defp page_results(%{results: results}), do: results
  defp page_results(list) when is_list(list), do: list

  defp build_stats do
    rows =
      from(b in "storage_blobs",
        group_by: [b.service_name, b.content_type],
        select: %{
          service_name: b.service_name,
          content_type: b.content_type,
          count: count(b.id),
          bytes: coalesce(sum(b.byte_size), 0)
        }
      )
      |> Repo.all()

    %{
      by_service:
        rows
        |> Enum.group_by(& &1.service_name)
        |> Enum.map(fn {service, group} ->
          {service, Enum.reduce(group, 0, &(to_int(&1.bytes) + &2))}
        end)
        |> Enum.sort_by(fn {_, bytes} -> -bytes end),
      by_content_type:
        rows
        |> Enum.group_by(& &1.content_type)
        |> Enum.map(fn {ct, group} ->
          {ct || "(unknown)", Enum.reduce(group, 0, &(to_int(&1.count) + &2))}
        end)
        |> Enum.sort_by(fn {_, count} -> -count end)
    }
  end

  defp to_int(nil), do: 0
  defp to_int(%Decimal{} = d), do: Decimal.to_integer(d)
  defp to_int(n) when is_integer(n), do: n

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <section class="space-y-8">
        <Layouts.back_button />
        <header class="space-y-1">
          <h1 class="text-3xl font-bold">Storage admin</h1>
          <p class="text-base-content/70">
            Aggregate view across every host. See <a class="link" href="/admin/">/admin/</a>
            for the per-resource AshAdmin UI.
          </p>
        </header>

        <section class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <article class="rounded-box border border-base-300 p-4">
            <h2 class="font-semibold mb-2">Bytes per service</h2>
            <ul class="text-sm space-y-1">
              <li :for={{service, bytes} <- @stats.by_service} class="flex justify-between">
                <span>{service}</span>
                <span class="font-mono">{format_bytes(bytes)}</span>
              </li>
              <li :if={@stats.by_service == []} class="text-base-content/60">No blobs yet.</li>
            </ul>
          </article>

          <article class="rounded-box border border-base-300 p-4">
            <h2 class="font-semibold mb-2">Count per content-type</h2>
            <ul class="text-sm space-y-1">
              <li :for={{ct, count} <- @stats.by_content_type} class="flex justify-between">
                <span>{ct}</span>
                <span class="font-mono">{count}</span>
              </li>
              <li :if={@stats.by_content_type == []} class="text-base-content/60">No blobs yet.</li>
            </ul>
          </article>
        </section>

        <section class="rounded-box border border-base-300 p-4 flex items-center justify-between">
          <div>
            <h2 class="font-semibold">Orphan blobs</h2>
            <p class="text-sm text-base-content/70">
              Blob rows with no attachment in any of the three attachment tables.
            </p>
          </div>
          <div class="flex items-center gap-3">
            <span class="badge badge-warning">{@orphan_count}</span>
            <button
              type="button"
              class="btn btn-sm btn-error"
              phx-click="purge-orphans"
              disabled={@orphan_count == 0}
              data-confirm="Drop orphan blob records?"
            >
              Purge orphan records
            </button>
          </div>
        </section>

        <section>
          <h2 class="font-semibold mb-2">Recent blobs</h2>
          <ul class="space-y-3">
            <li :for={blob <- @blobs} class="rounded-box border border-base-300 p-3 space-y-2">
              <div class="flex items-center justify-between text-sm">
                <span class="font-mono break-all">{blob.filename}</span>
                <span class="badge badge-sm badge-outline">{blob.content_type || "?"}</span>
              </div>
              <div class="flex items-center gap-2 text-xs text-base-content/70">
                <span>{blob.service_name}</span>
                <span>·</span>
                <span>{format_bytes(blob.byte_size)}</span>
                <span :if={blob.variant_of_blob_id}>· variant: {blob.variant_name}</span>
              </div>
              <.analyzer_pills blob={blob} />
              <.blob_metadata blob={blob} />
            </li>
            <li :if={@blobs == []} class="text-base-content/60 text-sm">No blobs yet.</li>
          </ul>
        </section>
      </section>
    </Layouts.app>
    """
  end

  defp format_bytes(nil), do: "0 B"
  defp format_bytes(b) when b < 1024, do: "#{b} B"
  defp format_bytes(b) when b < 1_048_576, do: "#{Float.round(b / 1024, 1)} KB"
  defp format_bytes(b) when b < 1_073_741_824, do: "#{Float.round(b / 1_048_576, 1)} MB"
  defp format_bytes(b), do: "#{Float.round(b / 1_073_741_824, 2)} GB"
end
