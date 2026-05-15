defmodule AshStorageDemoWeb.PostComponents do
  @moduledoc """
  Shared rendering for `AshStorageDemo.Feed.Post`. Used by `FeedLive` with
  owner controls, and by the public `PublicFeedLive` / `PublicPostLive`
  pages without them.
  """
  use Phoenix.Component
  use AshStorageDemoWeb, :verified_routes

  alias Phoenix.LiveView.JS
  import AshStorageDemoWeb.StorageComponents

  attr :post, :any, required: true
  attr :owner?, :boolean, default: false, doc: "Owner sees Delete + Hidden toggle"
  attr :share_url, :string, default: nil, doc: "Absolute URL for the post"
  attr :linkable_header, :boolean, default: true, doc: "Link post id to /p/:id"

  def post_card(assigns) do
    ~H"""
    <article class={["post", @post.hidden && "post-hidden"]} data-role="post" id={"post-" <> @post.id}>
      <header class="post-head">
        <span class="post-author">
          <span class="post-avatar">
            <img
              :if={author_avatar_url(@post.author)}
              src={author_avatar_url(@post.author)}
              alt=""
            />
            <span :if={!author_avatar_url(@post.author)}>{author_initial(@post.author)}</span>
          </span>
          <span>
            <span class="post-name">{@post.author && to_string(@post.author.email)}</span>
            <span class="post-time">{format_time(@post.inserted_at)}</span>
          </span>
        </span>
        <span class="post-actions">
          <span :if={@post.hidden} class="post-hidden-pill" data-role="post-hidden-pill">
            Hidden
          </span>
          <.link
            :if={@linkable_header}
            navigate={~p"/p/#{@post.id}"}
            class="post-id post-id-link"
            data-role="post-open-link"
          >
            post_<span class="mono">{short_id(@post.id)}</span>
          </.link>
          <span :if={!@linkable_header} class="post-id">
            post_<span class="mono">{short_id(@post.id)}</span>
          </span>
          <button
            :if={@share_url}
            type="button"
            class="btn-tiny"
            phx-click={
              JS.dispatch("clipboard-copy", detail: %{text: @share_url})
              |> JS.push("copy-link", value: %{url: @share_url})
            }
            data-role="post-copy-link"
            data-clipboard-text={@share_url}
            title="Copy public post link"
          >
            Copy link
          </button>
          <label
            :if={@owner?}
            class="post-hide-toggle"
            data-role="post-hide-toggle"
            title="Hide this post from public views"
          >
            <input
              type="checkbox"
              checked={@post.hidden}
              phx-click="toggle-hidden"
              phx-value-post-id={@post.id}
            />
            <span>Hidden</span>
          </label>
          <button
            :if={@owner?}
            type="button"
            class="btn-tiny btn-tiny-danger"
            phx-click="delete-post"
            phx-value-post-id={@post.id}
            data-role="post-delete"
            data-confirm="Delete this post and all attached files? This cannot be undone."
          >
            Delete
          </button>
        </span>
      </header>

      <p class="post-body">{@post.body}</p>

      <img
        :if={@post.cover_image_url}
        src={@post.cover_image_url}
        alt="cover"
        class="post-cover"
      />

      <div :if={@post.photos != []} class="post-section">
        <div class="post-section-head">
          <span>Photos <em>({length(@post.photos)})</em></span>
        </div>
        <div class="photo-grid">
          <img :for={photo <- @post.photos} src={photo.url} alt="photo" />
        </div>
      </div>

      <dl
        :if={@post.taken_at || @post.camera || @post.gps_lat}
        class="post-meta"
      >
        <%= if @post.taken_at do %>
          <dt>Taken at</dt>
          <dd class="mono">{@post.taken_at}</dd>
        <% end %>
        <%= if @post.camera do %>
          <dt>Camera</dt>
          <dd class="mono">{@post.camera}</dd>
        <% end %>
        <%= if @post.gps_lat do %>
          <dt>GPS</dt>
          <dd class="mono">{@post.gps_lat}, {@post.gps_lng}</dd>
        <% end %>
      </dl>

      <div :if={@post.videos != []} class="post-section">
        <div class="post-section-head">
          <span>Videos <em>({length(@post.videos)})</em></span>
        </div>
        <ul class="video-list">
          <li :for={vid <- @post.videos}>
            <video
              class="post-video"
              controls
              preload="metadata"
              src={vid.url}
            />
            <div class="doc-row">
              <a class="doc-link" href={vid.url} target="_blank">
                <svg
                  viewBox="0 0 24 24"
                  width="14"
                  height="14"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="1.7"
                >
                  <rect x="3" y="6" width="13" height="12" rx="2" />
                  <path d="m16 10 5-3v10l-5-3z" />
                </svg>
                {vid.blob && vid.blob.filename}
              </a>
              <.service_tag kind={:s3} />
            </div>
          </li>
        </ul>
      </div>

      <div :if={@post.documents != []} class="post-section">
        <div class="post-section-head">
          <span>Documents <em>({length(@post.documents)})</em></span>
        </div>
        <ul class="doc-list">
          <li :for={doc <- @post.documents}>
            <div class="doc-row">
              <a class="doc-link" href={doc.url} target="_blank">
                <svg
                  viewBox="0 0 24 24"
                  width="14"
                  height="14"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="1.7"
                >
                  <path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z" />
                  <path d="M14 3v6h6M8 13h8M8 17h6" />
                </svg>
                {doc.blob && doc.blob.filename}
              </a>
              <%= case mime_badge(doc.blob) do %>
                <% {declared, nil} -> %>
                  <span class="badge-mono">{declared}</span>
                <% {declared, detected} -> %>
                  <span class="badge-mono">
                    {declared}
                    <span class="badge-detected">→ {detected}</span>
                  </span>
              <% end %>
              <.service_tag kind={:disk} />
              <button
                :if={@owner?}
                type="button"
                class="btn-tiny"
                phx-click="detach-document"
                phx-value-post-id={@post.id}
                phx-value-blob-id={doc.blob.id}
              >
                Unlink
              </button>
            </div>
            <.analyzer_pills blob={doc.blob} />
          </li>
        </ul>
      </div>
    </article>
    """
  end

  defp mime_badge(blob) do
    detected = blob.metadata && blob.metadata["detected_content_type"]
    declared = blob.content_type || "unknown"

    if detected && detected != declared do
      {declared, detected}
    else
      {declared, nil}
    end
  end

  defp short_id(id) when is_binary(id) do
    case String.length(id) do
      len when len > 12 -> String.slice(id, 0, 8)
      _ -> id
    end
  end

  defp short_id(other), do: inspect(other)

  defp author_initial(%{email: email}) when not is_nil(email) do
    email |> to_string() |> String.first() |> Kernel.||("?") |> String.upcase()
  end

  defp author_initial(_), do: "?"

  defp author_avatar_url(%{avatar_small_url: url}) when is_binary(url) and url != "", do: url
  defp author_avatar_url(_), do: nil

  defp format_time(%{__struct__: _} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  defp format_time(_), do: ""
end
