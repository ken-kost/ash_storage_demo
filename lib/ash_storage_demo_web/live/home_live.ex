defmodule AshStorageDemoWeb.HomeLive do
  use AshStorageDemoWeb, :live_view

  import Ecto.Query
  alias AshStorageDemo.Repo
  alias AshStorageDemo.Storage.VolumeUsage

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: VolumeUsage.subscribe()

    {:ok,
     socket
     |> assign(stats: gather_stats())
     |> assign(volume_usage: VolumeUsage.current())}
  end

  @impl true
  def handle_info({:volume_usage, %VolumeUsage{} = usage}, socket) do
    {:noreply, assign(socket, volume_usage: usage)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <section class="home-hero">
        <div class="hero-eyebrow">
          <span class="kbd">v0.1</span>
          <span>ash_storage · a polymorphic attachment layer for Ash</span>
        </div>

        <h1 class="hero-title">
          Storage that knows<br />
          <em>where</em> things live, <em>what</em> they are,<br />
          and <em>who</em> they belong to.
        </h1>

        <p class="hero-lede">
          One blob table. Many services. Pluggable analyzers. This demo wires a feed
          against S3 and local Disk so you can watch the pipeline run.
        </p>

        <dl class="feature-list" data-role="feature-list">
          <div class="feature-row">
            <dt>Multi-service routing</dt>
            <dd>
              <code>has_one_attached</code>/<code>has_many_attached</code> on
              <code>Post</code> route photos &amp; videos to <strong>S3</strong> and
              documents to <strong>Disk</strong> — service is per-attachment, not per-app.
              <.link navigate={feed_path(@current_user)} class="feature-try">
                Try in the feed →
              </.link>
            </dd>
          </div>
          <div class="feature-row">
            <dt>Analyzers</dt>
            <dd>
              Post-upload pipeline runs <em>FileInfo</em> (MIME sniffing),
              <em>ImageDimensions</em> (via :oban), <em>Exif</em>
              (writes <code>taken_at</code> / <code>camera</code> / <code>gps_*</code>
              back to the host), and <em>DominantColor</em> on avatars. Status pills
              show pending → complete / error / skipped.
              <.link navigate={profile_path(@current_user)} class="feature-try">
                Try on profile →
              </.link>
            </dd>
          </div>
          <div class="feature-row">
            <dt>Variants</dt>
            <dd>
              Derived blobs in three modes: <em>eager</em> (avatar small/medium/large),
              <em>:oban</em> (cover_image feed_size), <em>on-demand</em> (photo
              thumbnails, PDF previews, video posters). Custom variants too —
              see <code>OutlinedSticker</code>.
              <.link navigate={profile_path(@current_user)} class="feature-try">
                Try variants →
              </.link>
            </dd>
          </div>
          <div class="feature-row">
            <dt>Mirroring service</dt>
            <dd>
              Cover images use <code>AshStorage.Service.Mirror</code> — writes fan out
              to S3 + a Disk mirror, reads fall through on <code>:not_found</code>.
              <.link navigate={feed_path(@current_user)} class="feature-try">
                Upload a cover →
              </.link>
            </dd>
          </div>
          <div class="feature-row">
            <dt>Polymorphic attachments</dt>
            <dd>
              A single <code>PolyAttachment</code> table points at any host —
              <code>Post</code>, <code>Comment</code>, or <code>User</code> —
              via <code>Tag.has_many_attached :icons</code>.
              <a href="/admin/" class="feature-try">Browse in AshAdmin →</a>
            </dd>
          </div>
          <div class="feature-row">
            <dt>Orphan sweeper + admin</dt>
            <dd>
              Bytes per service, counts per content-type, blob inspector with full
              analyzer metadata, and a one-click purge for blob rows with no
              attachment in any host table (kept tidy by an <em>AshOban</em>
              recurring schedule).
              <.link navigate={storage_path(@current_user)} class="feature-try">
                Open storage admin →
              </.link>
            </dd>
          </div>
        </dl>

        <div class="hero-ctas">
          <.link
            :if={@current_user}
            navigate="/feed"
            class="btn btn-primary"
            data-role="home-cta-feed"
          >
            Open the feed →
          </.link>
          <.link
            :if={!@current_user}
            navigate="/sign-in"
            class="btn btn-primary"
            data-role="home-cta-sign-in"
          >
            Sign in to post →
          </.link>
          <.link
            :if={!@current_user}
            navigate="/register"
            class="btn btn-ghost"
            data-role="home-cta-register"
          >
            Register
          </.link>
          <a
            href="https://hexdocs.pm/ash_storage"
            target="_blank"
            class="btn btn-ghost"
          >
            Read the spec
          </a>
        </div>

        <div class="hero-stats">
          <div class="stat">
            <span class="stat-num">3</span>
            <span class="stat-lbl">
              attachment surfaces<br /><em>posts · users · documents</em>
            </span>
          </div>
          <div class="stat">
            <span class="stat-num">2</span>
            <span class="stat-lbl">services<br /><em>S3 · Disk</em></span>
          </div>
          <div class="stat">
            <span class="stat-num">4</span>
            <span class="stat-lbl">
              analyzers<br /><em>FileInfo · Exif · Variants · DominantColor</em>
            </span>
          </div>
        </div>

        <div class="volume-gauge" data-role="volume-gauge">
          <div class="volume-gauge-meta">
            <span class="volume-gauge-label">Shared volume</span>
            <span class="volume-gauge-bytes">
              {format_bytes(@volume_usage.used_bytes)} / {format_bytes(@volume_usage.total_bytes)}
              <span :if={@volume_usage.measured_at} class="volume-gauge-percent">
                · {format_percent(@volume_usage.percent)}
              </span>
            </span>
          </div>
          <div class="bar-track">
            <span
              class={["bar-fill", volume_tone(@volume_usage.percent)]}
              style={"width: #{bar_width(@volume_usage.percent)}%"}
            >
            </span>
          </div>
          <div class="volume-gauge-foot">
            <span :if={@volume_usage.measured_at}>
              {@volume_usage.object_count} objects · updated {Calendar.strftime(
                @volume_usage.measured_at,
                "%H:%M UTC"
              )}
            </span>
            <span :if={!@volume_usage.measured_at && !@volume_usage.error}>
              measuring…
            </span>
            <span :if={@volume_usage.error} class="volume-gauge-err">
              measurement unavailable
            </span>
          </div>
        </div>
      </section>

      <div class="home-grid">
        <.link navigate={feed_path(@current_user)} class="tile" data-role="tile-feed">
          <div class="tile-head">
            <span class="tile-num">01</span>
            <span class="tile-name">Feed</span>
          </div>
          <p class="tile-desc">
            Compose posts with cover image, photos, videos and documents.
            Watch analyzers fill in metadata in real time.
          </p>
          <span class="tile-meta">photos · videos → S3 &nbsp; documents → Disk</span>
        </.link>

        <.link navigate={profile_path(@current_user)} class="tile" data-role="tile-profile">
          <div class="tile-head">
            <span class="tile-num">02</span>
            <span class="tile-name">Profile</span>
          </div>
          <p class="tile-desc">
            Avatar and cover photo with dominant-color tinting, variants and signed URLs.
          </p>
          <span class="tile-meta">single-attachment slots · variant pipeline</span>
        </.link>

        <.link
          navigate={storage_path(@current_user)}
          class="tile"
          data-role="tile-storage"
        >
          <div class="tile-head">
            <span class="tile-num">03</span>
            <span class="tile-name">Storage admin</span>
          </div>
          <p class="tile-desc">
            Cross-service inventory. Bytes by service, counts by mime, orphan sweeper,
            blob inspector.
          </p>
          <span class="tile-meta">
            {format_count(@stats.blob_count)} blobs · {@stats.service_count} services
          </span>
        </.link>
      </div>
    </Layouts.app>
    """
  end

  defp feed_path(nil), do: "/sign-in"
  defp feed_path(_), do: "/feed"
  defp profile_path(nil), do: "/sign-in"
  defp profile_path(_), do: "/profile"
  defp storage_path(nil), do: "/sign-in"
  defp storage_path(_), do: "/storage-admin"

  defp gather_stats do
    try do
      blob_count = Repo.aggregate("storage_blobs", :count, :id) || 0

      services =
        from(b in "storage_blobs", select: count(b.service_name, :distinct))
        |> Repo.one()
        |> Kernel.||(0)

      %{blob_count: blob_count, service_count: services}
    rescue
      _ -> %{blob_count: 0, service_count: 0}
    end
  end

  defp format_count(n) when n >= 1_000, do: "#{Float.round(n / 1000, 1)}k"
  defp format_count(n), do: to_string(n)

  defp bar_width(percent) when is_number(percent), do: percent |> min(100.0) |> max(0.0)
  defp bar_width(_), do: 0.0

  defp format_percent(p) when is_number(p), do: "#{:erlang.float_to_binary(p * 1.0, decimals: 1)}%"
  defp format_percent(_), do: "—"

  defp volume_tone(p) when is_number(p) and p >= 90, do: "is-danger"
  defp volume_tone(p) when is_number(p) and p >= 70, do: "is-warn"
  defp volume_tone(_), do: "is-ok"

  @units ~w(B KB MB GB TB)
  defp format_bytes(n) when is_integer(n) and n >= 0 do
    {value, unit} = scale_bytes(n * 1.0, @units)

    cond do
      unit == "B" -> "#{trunc(value)} #{unit}"
      value >= 100 -> "#{Float.round(value, 0) |> trunc()} #{unit}"
      value >= 10 -> "#{:erlang.float_to_binary(value, decimals: 1)} #{unit}"
      true -> "#{:erlang.float_to_binary(value, decimals: 2)} #{unit}"
    end
  end

  defp format_bytes(_), do: "—"

  defp scale_bytes(value, [unit]), do: {value, unit}
  defp scale_bytes(value, [unit | _]) when value < 1024, do: {value, unit}
  defp scale_bytes(value, [_ | rest]), do: scale_bytes(value / 1024, rest)
end
