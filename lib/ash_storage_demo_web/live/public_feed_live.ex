defmodule AshStorageDemoWeb.PublicFeedLive do
  @moduledoc """
  Public, read-only feed for a single user. Identified by the user's UUID
  in the URL — accessible to guests as well as signed-in users.
  """
  use AshStorageDemoWeb, :live_view

  require Ash.Query

  import AshStorageDemoWeb.PostComponents

  alias AshStorageDemo.Accounts.User
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

  @user_load_spec [:avatar_medium_url, :cover_photo_url]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    actor = socket.assigns[:current_user]

    case Ash.get(User, id, actor: actor) do
      {:ok, user} ->
        user = Ash.load!(user, @user_load_spec, actor: actor)

        {:ok,
         socket
         |> assign(:page_title, "@" <> to_string(user.email))
         |> assign(user: user, posts: load_posts(user, actor))}

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "User not found")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("copy-link", _params, socket) do
    {:noreply, put_flash(socket, :info, "Link copied to clipboard")}
  end

  defp load_posts(user, actor) do
    Post
    |> Ash.Query.filter(author_id == ^user.id)
    |> Ash.Query.sort(inserted_at: :desc)
    |> Ash.read!(page: [limit: 50, count: false], actor: actor)
    |> page_results()
    |> Ash.load!(@load_spec, actor: actor)
  end

  defp page_results(%{results: results}), do: results
  defp page_results(list) when is_list(list), do: list

  defp absolute_url(path), do: AshStorageDemoWeb.Endpoint.url() <> path

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <Layouts.back_button />
      <div
        :if={@user.cover_photo_url}
        class="feed-cover"
        data-role="feed-cover"
        style={"background-image: url('#{@user.cover_photo_url}');"}
      >
        <span
          :if={@user.avatar_medium_url}
          class="feed-cover-avatar"
          data-role="feed-cover-avatar"
        >
          <img src={@user.avatar_medium_url} alt="" />
        </span>
      </div>
      <div class="page-head">
        <h1>{to_string(@user.email)}</h1>
        <p class="page-sub">
          <span>Public feed · viewable by anyone with the link</span>
          <span class="sep">·</span>
          <span class="mono">user_{String.slice(@user.id, 0, 8)}</span>
        </p>
        <div class="page-actions">
          <button
            type="button"
            class="btn-tiny"
            phx-click={
              JS.dispatch("clipboard-copy",
                detail: %{text: absolute_url(~p"/u/#{@user.id}")}
              )
              |> JS.push("copy-link")
            }
            data-role="feed-copy-link"
          >
            Copy feed link
          </button>
        </div>
      </div>

      <div :if={@posts == []} class="feed-divider">
        <span>no posts yet</span>
        <span class="rule" />
        <span>this feed is <em>empty</em></span>
      </div>

      <div :if={@posts != []} class="feed-divider">
        <span>{length(@posts)} {if length(@posts) == 1, do: "post", else: "posts"}</span>
        <span class="rule" />
        <span>sorted by <em>newest</em></span>
      </div>

      <.post_card
        :for={post <- @posts}
        post={post}
        owner?={false}
        share_url={absolute_url(~p"/p/#{post.id}")}
      />
    </Layouts.app>
    """
  end
end
