defmodule AshStorageDemoWeb.StorageAdminLive do
  @moduledoc """
  Admin LiveView for the storage backbone — KPI strip across the top,
  bytes-per-service / counts-per-content-type cards, orphan sweeper, and
  a recent-blobs list with analyzer pills.
  """
  use AshStorageDemoWeb, :live_view

  import AshStorageDemoWeb.StorageComponents
  import Ecto.Query
  alias AshStorageDemo.Repo
  alias AshStorageDemo.Storage.{Blob, Orphans}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, filter: "all") |> reload()}
  end

  @impl true
  def handle_event("purge-orphans", _, socket) do
    count = Orphans.purge_orphan_records()
    {:noreply, socket |> put_flash(:info, "Removed #{count} orphan blob record(s)") |> reload()}
  end

  def handle_event("filter", %{"kind" => kind}, socket) do
    {:noreply, assign(socket, filter: kind) |> reload()}
  end

  defp reload(socket) do
    blobs =
      Blob
      |> Ash.Query.sort(id: :desc)
      |> Ash.read!(page: [limit: 50, count: false], authorize?: false)
      |> page_results()
      |> filter_blobs(socket.assigns[:filter] || "all")

    stats = build_stats()
    orphan_count = length(Orphans.orphan_blobs())
    blob_total = Repo.aggregate("storage_blobs", :count, :id) || 0
    pending_count = pending_analyzer_count()

    socket
    |> assign(blobs: blobs)
    |> assign(stats: stats)
    |> assign(orphan_count: orphan_count)
    |> assign(blob_total: blob_total)
    |> assign(pending_count: pending_count)
  end

  defp page_results(%{results: results}), do: results
  defp page_results(list) when is_list(list), do: list

  defp filter_blobs(blobs, "all"), do: blobs

  defp filter_blobs(blobs, "images"),
    do: Enum.filter(blobs, &String.starts_with?(content_type_or(&1, ""), "image/"))

  defp filter_blobs(blobs, "video"),
    do: Enum.filter(blobs, &String.starts_with?(content_type_or(&1, ""), "video/"))

  defp filter_blobs(blobs, "docs"),
    do:
      Enum.filter(blobs, fn b ->
        ct = content_type_or(b, "")

        String.starts_with?(ct, "application/") or String.starts_with?(ct, "text/")
      end)

  defp filter_blobs(blobs, "variants"),
    do: Enum.filter(blobs, & &1.variant_of_blob_id)

  defp content_type_or(%{content_type: ct}, _) when is_binary(ct), do: ct
  defp content_type_or(_, default), do: default

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

    total_bytes = Enum.reduce(rows, 0, &(to_int(&1.bytes) + &2))

    by_service =
      rows
      |> Enum.group_by(& &1.service_name)
      |> Enum.map(fn {service, group} ->
        {service, Enum.reduce(group, 0, &(to_int(&1.bytes) + &2))}
      end)
      |> Enum.sort_by(fn {_, bytes} -> -bytes end)

    by_content_type =
      rows
      |> Enum.group_by(& &1.content_type)
      |> Enum.map(fn {ct, group} ->
        {ct || "(unknown)", Enum.reduce(group, 0, &(to_int(&1.count) + &2))}
      end)
      |> Enum.sort_by(fn {_, count} -> -count end)

    %{by_service: by_service, by_content_type: by_content_type, total_bytes: total_bytes}
  end

  defp pending_analyzer_count do
    # Loose heuristic: blobs whose analyzers map has any entry with status "pending".
    # We can't filter that in SQL portably, so we scan a recent slice.
    Blob
    |> Ash.Query.sort(id: :desc)
    |> Ash.read!(page: [limit: 200, count: false], authorize?: false)
    |> page_results()
    |> Enum.count(fn blob ->
      analyzers = blob.analyzers || %{}

      Enum.any?(analyzers, fn {_mod, info} -> info["status"] == "pending" end)
    end)
  end

  defp to_int(nil), do: 0
  defp to_int(%Decimal{} = d), do: Decimal.to_integer(d)
  defp to_int(n) when is_integer(n), do: n

  defp service_pct(_bytes, 0), do: 0
  defp service_pct(bytes, _total) when bytes <= 0, do: 0
  defp service_pct(bytes, total), do: round(bytes / total * 100)

  defp max_count(counts), do: counts |> Enum.map(&elem(&1, 1)) |> Enum.max(fn -> 1 end)

  defp content_type_pct(_count, 0), do: 0
  defp content_type_pct(count, max), do: round(count / max * 100)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} active="storage">
      <Layouts.back_button />
      <div class="page-head">
        <h1>Storage admin</h1>
        <p class="page-sub">
          Aggregate view across every host. For the per-resource UI see <a
            class="inline-link mono"
            href="/admin/"
          >/admin/</a>.
        </p>
      </div>

      <section class="kpi-row">
        <.kpi
          label="Total blobs"
          value={Integer.to_string(@blob_total)}
          hint={"#{length(@blobs)} shown"}
        />
        <.kpi
          label="Stored bytes"
          value={format_bytes(@stats.total_bytes)}
          hint={service_split(@stats.by_service)}
        />
        <.kpi
          label="Analyzer queue"
          value={"#{@pending_count} pending"}
          hint="rolling 200-blob sample"
          tone={(@pending_count > 0 && "wait") || nil}
        />
        <.kpi
          label="Orphans"
          value={Integer.to_string(@orphan_count)}
          hint="purgeable"
          tone={(@orphan_count > 0 && "warn") || nil}
        />
      </section>

      <section class="two-up">
        <article class="tile-card">
          <h2 class="tile-card-title">Bytes per service</h2>
          <ul :if={@stats.by_service != []} class="bar-list">
            <li :for={{service, bytes} <- @stats.by_service}>
              <div class="bar-meta">
                <span class="bar-name">
                  <.service_tag kind={service} /> <span class="mono">{service}</span>
                </span>
                <span class="bar-bytes">{format_bytes(bytes)}</span>
              </div>
              <div class="bar-track">
                <span class="bar-fill" style={"width: #{service_pct(bytes, @stats.total_bytes)}%;"} />
              </div>
            </li>
          </ul>
          <p :if={@stats.by_service == []} class="text-sm" style="color: var(--ink-3)">
            No blobs yet.
          </p>
        </article>

        <article class="tile-card">
          <h2 class="tile-card-title">Count per content-type</h2>
          <% max_ct = (@stats.by_content_type != [] && max_count(@stats.by_content_type)) || 1 %>
          <ul :if={@stats.by_content_type != []} class="ct-list">
            <li
              :for={{ct, count} <- @stats.by_content_type}
              class={ct == "(unknown)" && "is-muted"}
            >
              <span class="ct-name">{ct}</span>
              <span class="ct-rail">
                <span class="ct-fill" style={"width: #{content_type_pct(count, max_ct)}%;"} />
              </span>
              <span class="ct-count">{count}</span>
            </li>
          </ul>
          <p :if={@stats.by_content_type == []} class="text-sm" style="color: var(--ink-3)">
            No blobs yet.
          </p>
        </article>
      </section>

      <article class="orphan-bar">
        <div>
          <h2>Orphan blobs</h2>
          <p>Blob rows with no attachment in any of the three attachment tables.</p>
        </div>
        <div class="orphan-actions">
          <span class="orphan-count">{@orphan_count}</span>
          <button
            type="button"
            class="btn btn-error btn-sm"
            phx-click="purge-orphans"
            disabled={@orphan_count == 0}
            data-confirm="Drop orphan blob records?"
          >
            Purge orphan records
          </button>
        </div>
      </article>

      <section>
        <header class="blobs-head">
          <h2>Recent blobs</h2>
          <div class="theme-switch" role="group" aria-label="Filter">
            <button
              :for={
                {key, label} <- [
                  {"all", "All"},
                  {"images", "Images"},
                  {"video", "Video"},
                  {"docs", "Docs"},
                  {"variants", "Variants"}
                ]
              }
              type="button"
              phx-click="filter"
              phx-value-kind={key}
              class={@filter == key && "is-on"}
              style={"color: " <> (@filter == key && "var(--ink)" || "var(--ink-3)")}
            >
              {label}
            </button>
          </div>
        </header>

        <ul :if={@blobs != []} class="blob-list">
          <li :for={blob <- @blobs} class="blob">
            <div class="blob-head">
              <span class="blob-name">{blob.filename}</span>
              <div class="blob-tags">
                <span :if={blob.variant_of_blob_id} class="tag-variant">
                  variant · {blob.variant_name}
                </span>
                <span class="badge-mono">{blob.content_type || "?"}</span>
              </div>
            </div>
            <div class="blob-sub">
              <.service_tag kind={blob.service_name} />
              <span class="sep">·</span>
              <span class="mono">{format_bytes(blob.byte_size)}</span>
            </div>
            <.analyzer_pills blob={blob} />
            <.blob_metadata blob={blob} />
          </li>
        </ul>

        <p :if={@blobs == []} class="text-sm" style="color: var(--ink-3)">No blobs yet.</p>
      </section>
    </Layouts.app>
    """
  end

  defp service_split([]), do: nil

  defp service_split(services) do
    Enum.map_join(services, " · ", fn {svc, bytes} -> "#{svc} #{format_bytes(bytes)}" end)
  end
end
