defmodule AshStorageDemoWeb.PublicPostLive do
  @moduledoc """
  Public, read-only single-post page. Accessible to guests and signed-in
  users alike via the post's UUID.
  """
  use AshStorageDemoWeb, :live_view

  import AshStorageDemoWeb.PostComponents

  alias AshStorageDemo.Feed.Post
  alias Phoenix.LiveView.JS

  @load_spec [
    :cover_image,
    :cover_image_url,
    photos: [:url, :blob],
    videos: [:url, :blob],
    documents: [:url, :blob],
    author: [:email, :avatar_small_url]
  ]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    actor = socket.assigns[:current_user]

    case Ash.get(Post, id, actor: actor) do
      {:ok, post} ->
        post = Ash.load!(post, @load_spec, actor: actor)

        {:ok,
         socket
         |> assign(:page_title, "post_" <> short_id(post.id))
         |> assign(post: post)}

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Post not found")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("copy-link", _params, socket) do
    {:noreply, put_flash(socket, :info, "Link copied to clipboard")}
  end

  defp absolute_url(path), do: AshStorageDemoWeb.Endpoint.url() <> path

  defp short_id(id) when is_binary(id), do: String.slice(id, 0, 8)
  defp short_id(_), do: ""

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <Layouts.back_button />
      <div class="page-head">
        <h1>Post</h1>
        <p class="page-sub">
          <span>Public link · shareable</span>
          <span :if={@post.author} class="sep">·</span>
          <span :if={@post.author}>
            by
            <.link
              navigate={~p"/u/#{@post.author.id}"}
              class="inline-link"
              data-role="post-author-link"
            >
              {to_string(@post.author.email)}
            </.link>
          </span>
        </p>
        <div class="page-actions">
          <button
            type="button"
            class="btn-tiny"
            phx-click={
              JS.dispatch("clipboard-copy",
                detail: %{text: absolute_url(~p"/p/#{@post.id}")}
              )
              |> JS.push("copy-link")
            }
            data-role="post-copy-link-top"
          >
            Copy post link
          </button>
        </div>
      </div>

      <.post_card
        post={@post}
        owner?={false}
        share_url={absolute_url(~p"/p/#{@post.id}")}
        linkable_header={false}
      />
    </Layouts.app>
    """
  end
end
