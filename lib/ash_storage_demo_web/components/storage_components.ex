defmodule AshStorageDemoWeb.StorageComponents do
  @moduledoc """
  Shared function components for rendering AshStorage state in LiveViews.
  Keeps analyzer pills, blob metadata, and badge styling consistent across
  FeedLive, ProfileLive, and the admin views.
  """
  use Phoenix.Component

  @doc """
  Per-analyzer status pill. Renders the status (`pending` / `complete` /
  `error` / `skipped`) with a colour matching state.

      <.analyzer_pills blob={@blob} />
  """
  attr :blob, :any, required: true

  def analyzer_pills(assigns) do
    ~H"""
    <div :if={@blob && @blob.analyzers} class="flex flex-wrap gap-1 text-xs">
      <span
        :for={{mod, info} <- @blob.analyzers}
        class={["badge badge-sm", status_class(info["status"])]}
        title={short_module(mod) <> ": " <> (info["status"] || "unknown")}
      >
        {short_module(mod)} · {info["status"]}
      </span>
    </div>
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
      class="grid grid-cols-[max-content_1fr] gap-x-3 text-xs"
    >
      <%= for {k, v} <- Enum.sort(@blob.metadata) do %>
        <dt class="font-medium">{k}</dt>
        <dd class="break-all">{format_value(v)}</dd>
      <% end %>
    </dl>
    """
  end

  defp status_class("complete"), do: "badge-success badge-outline"
  defp status_class("pending"), do: "badge-warning badge-outline"
  defp status_class("error"), do: "badge-error badge-outline"
  defp status_class("skipped"), do: "badge-ghost"
  defp status_class(_), do: "badge-ghost"

  defp short_module(mod) when is_binary(mod), do: mod |> String.split(".") |> List.last()
  defp short_module(mod), do: inspect(mod)

  defp format_value(v) when is_map(v), do: inspect(v)
  defp format_value(v) when is_list(v), do: inspect(v)
  defp format_value(v), do: to_string(v)
end
