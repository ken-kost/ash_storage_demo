defmodule AshStorageDemoWeb.FeedLive do
  use AshStorageDemoWeb, :live_view

  import AshStorageDemoWeb.PostComponents
  import AshStorageDemoWeb.StorageComponents
  alias AshStorage.Operations
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
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(form: to_form(%{"body" => ""}, as: "post"))
     |> reload_posts()
     |> allow_upload(:cover_image,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: 16_000_000
     )
     |> allow_upload(:photos,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 6,
       max_file_size: 16_000_000
     )
     |> allow_upload(:videos,
       accept: ~w(.mp4 .mov .webm),
       max_entries: 2,
       max_file_size: 64_000_000
     )
     |> allow_upload(:documents,
       accept: ~w(.pdf .txt .md .csv),
       max_entries: 4,
       max_file_size: 16_000_000
     )}
  end

  @impl true
  def handle_event("validate", %{"post" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "post"))}
  end

  def handle_event("create", %{"post" => %{"body" => body}}, socket) do
    actor = socket.assigns.current_user

    with {:ok, post} <- Ash.create(Post, %{body: body}, actor: actor),
         {:ok, post} <- attach_uploads(socket, post, actor) do
      {:noreply,
       socket
       |> put_flash(:info, "Posted")
       |> assign(form: to_form(%{"body" => ""}, as: "post"))
       |> reload_posts()
       |> tap_post(post)}
    else
      {:error, error} ->
        {:noreply, put_flash(socket, :error, format_error(error))}
    end
  end

  def handle_event("detach-document", %{"post-id" => post_id, "blob-id" => blob_id}, socket) do
    actor = socket.assigns.current_user

    case fetch_post(post_id, actor) do
      {:ok, post} ->
        case Operations.detach(post, :documents, blob_id: blob_id, actor: actor) do
          {:ok, _} ->
            {:noreply, socket |> put_flash(:info, "Document unlinked") |> reload_posts()}

          {:error, e} ->
            {:noreply, put_flash(socket, :error, format_error(e))}
        end

      :error ->
        {:noreply, put_flash(socket, :error, "Post not found")}
    end
  end

  def handle_event("delete-post", %{"post-id" => post_id}, socket) do
    actor = socket.assigns.current_user

    with {:ok, post} <- fetch_post(post_id, actor),
         :ok <- Ash.destroy(post, actor: actor) do
      {:noreply, socket |> put_flash(:info, "Post deleted") |> reload_posts()}
    else
      {:error, e} ->
        {:noreply, put_flash(socket, :error, format_error(e))}

      :error ->
        {:noreply, put_flash(socket, :error, "Post not found")}
    end
  end

  def handle_event("toggle-hidden", %{"post-id" => post_id}, socket) do
    actor = socket.assigns.current_user

    with {:ok, post} <- fetch_post(post_id, actor),
         new_hidden = !post.hidden,
         {:ok, _post} <-
           Ash.update(post, %{hidden: new_hidden}, action: :set_hidden, actor: actor) do
      flash = if new_hidden, do: "Post hidden from public views", else: "Post is now public"
      {:noreply, socket |> put_flash(:info, flash) |> reload_posts()}
    else
      {:error, e} ->
        {:noreply, put_flash(socket, :error, format_error(e))}

      :error ->
        {:noreply, put_flash(socket, :error, "Post not found")}
    end
  end

  def handle_event("copy-link", _params, socket) do
    {:noreply, put_flash(socket, :info, "Link copied to clipboard")}
  end

  defp attach_uploads(socket, post, actor) do
    Enum.reduce_while(
      [:cover_image, :photos, :videos, :documents],
      {:ok, post},
      fn slot, {:ok, post} ->
        case consume_slot(socket, post, slot, actor) do
          {:ok, post} -> {:cont, {:ok, post}}
          {:error, error} -> {:halt, {:error, error}}
        end
      end
    )
  end

  defp consume_slot(socket, post, slot, actor) do
    results =
      consume_uploaded_entries(socket, slot, fn %{path: path}, entry ->
        bytes = File.read!(path)

        {:ok,
         Operations.attach(post, slot, bytes,
           filename: entry.client_name,
           content_type: entry.client_type,
           actor: actor
         )}
      end)

    failure =
      Enum.find_value(results, fn
        {:error, e} -> {:error, e}
        _ -> nil
      end)

    case failure do
      {:error, _} = err -> err
      nil -> {:ok, post}
    end
  end

  defp fetch_post(id, actor) do
    case Ash.get(Post, id, actor: actor) do
      {:ok, post} -> {:ok, Ash.load!(post, @load_spec, actor: actor)}
      _ -> :error
    end
  end

  defp reload_posts(socket) do
    actor = socket.assigns.current_user

    posts =
      Post
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.read!(page: [limit: 20, count: false], actor: actor)
      |> page_results()
      |> Ash.load!(@load_spec, actor: actor)

    assign(socket, posts: posts)
  end

  defp tap_post(socket, _post), do: socket

  defp page_results(%{results: results}), do: results
  defp page_results(list) when is_list(list), do: list

  defp format_error(%Ash.Error.Invalid{} = err), do: Exception.message(err)
  defp format_error(other), do: inspect(other)

  defp absolute_url(path), do: AshStorageDemoWeb.Endpoint.url() <> path

  defp slot_entries(upload), do: Enum.map(upload.entries, & &1.client_name)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} active="feed">
      <Layouts.back_button />
      <div class="page-head">
        <h1>Feed</h1>
        <p class="page-sub">
          <span>
            <svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M7 18a5 5 0 1 1 1.2-9.85A6 6 0 0 1 20 11a4 4 0 0 1-1 7.87" /></svg>
            photos · videos route to <strong>S3</strong>
          </span>
          <span class="sep">/</span>
          <span>
            <svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="1.7"><rect x="3" y="5" width="18" height="5" rx="1" /><rect x="3" y="14" width="18" height="5" rx="1" /></svg>
            documents route to <strong>Disk</strong>
          </span>
        </p>
        <div class="page-actions">
          <.link
            navigate={~p"/u/#{@current_user.id}"}
            class="btn-tiny"
            data-role="view-public-feed"
          >
            View public feed →
          </.link>
          <button
            type="button"
            class="btn-tiny"
            phx-click={
              JS.dispatch("clipboard-copy",
                detail: %{text: absolute_url(~p"/u/#{@current_user.id}")}
              )
              |> JS.push("copy-link")
            }
            data-role="feed-copy-link"
            title="Copy a shareable link to your public feed"
          >
            Copy feed link
          </button>
        </div>
      </div>

      <.form
        for={@form}
        phx-submit="create"
        phx-change="validate"
        class="composer"
      >
        <textarea
          name="post[body]"
          placeholder="What's on your mind?"
          class="composer-input"
        >{Phoenix.HTML.Form.input_value(@form, :body)}</textarea>

        <div class="composer-slots">
          <.composer_slot label="Cover image" hint=".jpg .png .webp · 16MB" svc={:s3} max="1" upload={@uploads.cover_image} />
          <.composer_slot label="Photos" hint="up to 6 · 16MB each" svc={:s3} max="6" upload={@uploads.photos} />
          <.composer_slot label="Videos" hint="up to 2 · 64MB each" svc={:s3} max="2" upload={@uploads.videos} />
          <.composer_slot label="Documents" hint=".pdf .txt .md .csv · 16MB" svc={:disk} max="4" upload={@uploads.documents} />
        </div>

        <div class="composer-foot">
          <span class="composer-hint">
            Drafts are not persisted. <kbd>⌘</kbd>+<kbd>↵</kbd> to post.
          </span>
          <button type="submit" class="btn btn-primary btn-sm">Post</button>
        </div>
      </.form>

      <div :if={@posts == []} class="feed-divider">
        <span>no posts yet</span>
        <span class="rule" />
        <span>be the <em>first</em></span>
      </div>

      <div :if={@posts != []} class="feed-divider">
        <span>{length(@posts)} {if length(@posts) == 1, do: "post", else: "posts"}</span>
        <span class="rule" />
        <span>sorted by <em>newest</em></span>
      </div>

      <.post_card
        :for={post <- @posts}
        post={post}
        owner?={post.author_id == @current_user.id}
        share_url={absolute_url(~p"/p/#{post.id}")}
      />
    </Layouts.app>
    """
  end

  attr :label, :string, required: true
  attr :hint, :string, required: true
  attr :svc, :atom, required: true
  attr :max, :string, required: true
  attr :upload, :any, required: true

  defp composer_slot(assigns) do
    files = slot_entries(assigns.upload)
    assigns = assign(assigns, files: files)

    ~H"""
    <div class={["slot", @files != [] && "has-files"]}>
      <div class="slot-head">
        <span class="slot-label">{@label}</span>
        <.service_tag kind={@svc} />
      </div>
      <label class="slot-drop" for={@upload.ref}>
        <%= if @files == [] do %>
          <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.7">
            <path d="M12 16V4M7 9l5-5 5 5M4 20h16" />
          </svg>
          <span>Drop or <u>browse</u></span>
        <% else %>
          <ul class="slot-files">
            <li :for={entry <- @upload.entries}>
              <span class="file-name">{entry.client_name}</span>
              <span class="text-xs" style="color: var(--ok)">{entry.progress}%</span>
            </li>
          </ul>
        <% end %>
        <.live_file_input upload={@upload} class="hidden" />
      </label>
      <div class="slot-foot">{@hint} · max {@max}</div>
      <div :for={entry <- @upload.entries} class="text-xs" style="color: var(--err)">
        <span :for={err <- upload_errors(@upload, entry)}>· {err}</span>
      </div>
    </div>
    """
  end
end
