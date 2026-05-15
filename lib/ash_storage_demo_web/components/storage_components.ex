defmodule AshStorageDemoWeb.StorageComponents do
  @moduledoc """
  Shared function components for rendering AshStorage state in LiveViews.
  Vocabulary used across the app: status_pill (analyzer state), service_tag
  (S3 vs Disk), placeholder (missing image), kpi / field for stat cards.
  """
  use Phoenix.Component

  @doc """
  Per-analyzer status pill row — renders each analyzer with the same
  .pill / .pill-{ok,wait,err,mute} treatment as the design canvas.

      <.analyzer_pills blob={@blob} />
  """
  attr :blob, :any, required: true

  def analyzer_pills(assigns) do
    ~H"""
    <div :if={@blob && @blob.analyzers} class="blob-pills">
      <.status_pill
        :for={{mod, info} <- @blob.analyzers}
        label={short_module(mod)}
        kind={info["status"]}
      />
    </div>
    """
  end

  @doc """
  Single status pill. Pass `kind` as one of "complete", "pending", "error",
  "skipped". Unknown values render as muted.
  """
  attr :label, :string, required: true
  attr :kind, :any, default: "skipped"

  def status_pill(assigns) do
    {tone, text} = pill_tone(assigns.kind)
    assigns = assign(assigns, tone: tone, text: text)

    ~H"""
    <span class={["pill", "pill-" <> @tone]}>
      <span class="pill-label">{@label}</span>
      <span class="pill-sep">·</span>
      <span class="pill-status">{@text}</span>
    </span>
    """
  end

  @doc """
  Service tag — small monospace chip that says S3 (cloud icon) or Disk
  (disk icon). Pass `kind` as :s3, :disk, or the raw service name string.
  """
  attr :kind, :any, required: true

  def service_tag(assigns) do
    kind = normalize_service(assigns.kind)
    assigns = assign(assigns, kind: kind)

    ~H"""
    <span class={["svc", "svc-" <> @kind]}>
      <svg :if={@kind == "s3"} viewBox="0 0 24 24" width="12" height="12" fill="none" stroke="currentColor" stroke-width="1.7">
        <path d="M7 18a5 5 0 1 1 1.2-9.85A6 6 0 0 1 20 11a4 4 0 0 1-1 7.87" />
      </svg>
      <svg :if={@kind == "disk"} viewBox="0 0 24 24" width="12" height="12" fill="none" stroke="currentColor" stroke-width="1.7">
        <rect x="3" y="5" width="18" height="5" rx="1" />
        <rect x="3" y="14" width="18" height="5" rx="1" />
        <path d="M7 7.5h.01M7 16.5h.01" />
      </svg>
      <span>{service_label(@kind)}</span>
    </span>
    """
  end

  @doc """
  Renders the merged analyzer metadata map as a small key/value list.

      <.blob_metadata blob={@blob} />
  """
  attr :blob, :any, required: true

  def blob_metadata(assigns) do
    ~H"""
    <dl
      :if={@blob && @blob.metadata not in [nil, %{}]}
      class="blob-meta"
    >
      <%= for {k, v} <- Enum.sort(@blob.metadata) do %>
        <dt>{k}</dt>
        <dd>{format_value(v)}</dd>
      <% end %>
    </dl>
    """
  end

  @doc """
  Striped diagonal placeholder. Used in the design canvas in lieu of
  real imagery. Renders a soft tile with a centered monospace label.
  """
  attr :label, :string, required: true
  attr :height, :integer, default: 180

  def placeholder(assigns) do
    safe_id = "ph-" <> Base.url_encode64(:crypto.hash(:md5, assigns.label), padding: false)
    assigns = assign(assigns, safe_id: safe_id)

    ~H"""
    <div class="ph" style={"height: #{@height}px;"}>
      <svg class="ph-bg" preserveAspectRatio="none" viewBox="0 0 100 100">
        <defs>
          <pattern id={@safe_id} width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
            <line x1="0" y1="0" x2="0" y2="6" stroke="currentColor" stroke-width="1" opacity="0.35" />
          </pattern>
        </defs>
        <rect width="100" height="100" fill={"url(##{@safe_id})"} />
      </svg>
      <span class="ph-label">{@label}</span>
    </div>
    """
  end

  @doc """
  KPI cell used inside `.kpi-row`. Pass label / value / hint. Use `tone`
  to switch to a warning treatment.
  """
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :hint, :string, default: nil
  attr :tone, :string, default: nil, doc: "warn | wait | nil"

  def kpi(assigns) do
    ~H"""
    <div class={["kpi", @tone && "kpi-" <> @tone]}>
      <span class="kpi-label">{@label}</span>
      <span class="kpi-value">{@value}</span>
      <span :if={@hint} class="kpi-hint">{@hint}</span>
    </div>
    """
  end

  @doc """
  Single key/value cell. Used in `.panel-foot` strips on Profile, and
  anywhere we need monospace metadata rendered as a small panel.
  """
  attr :k, :string, required: true
  attr :v, :string, required: true

  def field(assigns) do
    ~H"""
    <div class="field">
      <span class="field-k">{@k}</span>
      <span class="field-v" title={@v}>{@v}</span>
    </div>
    """
  end

  @doc """
  Format a byte count for display. Reused across feed / profile / admin.
  """
  def format_bytes(nil), do: "0 B"
  def format_bytes(b) when b < 1024, do: "#{b} B"
  def format_bytes(b) when b < 1_048_576, do: "#{Float.round(b / 1024, 1)} KB"
  def format_bytes(b) when b < 1_073_741_824, do: "#{Float.round(b / 1_048_576, 1)} MB"
  def format_bytes(b), do: "#{Float.round(b / 1_073_741_824, 2)} GB"

  defp pill_tone("complete"), do: {"ok", "complete"}
  defp pill_tone("pending"), do: {"wait", "pending"}
  defp pill_tone("error"), do: {"err", "error"}
  defp pill_tone("skipped"), do: {"mute", "skipped"}
  defp pill_tone(other), do: {"mute", to_string(other || "unknown")}

  defp normalize_service(:s3), do: "s3"
  defp normalize_service(:disk), do: "disk"
  defp normalize_service(kind) when is_binary(kind) do
    cond do
      String.contains?(kind, "disk") -> "disk"
      String.contains?(kind, "s3") -> "s3"
      true -> "disk"
    end
  end
  defp normalize_service(kind), do: kind |> to_string() |> normalize_service()

  defp service_label("s3"), do: "S3"
  defp service_label("disk"), do: "Disk"
  defp service_label(other), do: to_string(other)

  defp short_module(mod) when is_binary(mod), do: mod |> String.split(".") |> List.last()
  defp short_module(mod), do: inspect(mod)

  defp format_value(v) when is_map(v), do: inspect(v)
  defp format_value(v) when is_list(v), do: inspect(v)
  defp format_value(v), do: to_string(v)
end
