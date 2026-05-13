defmodule AshStorageDemoWeb.FeedLive do
  use AshStorageDemoWeb, :live_view

  import AshStorageDemoWeb.StorageComponents
  alias AshStorage.Operations
  alias AshStorageDemo.Feed.Post

  @load_spec [
    :cover_image,
    :cover_image_url,
    photos: [:url, :blob],
    videos: [:url, :blob],
    documents: [:url, :blob],
    author: [:email]
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
         {:ok, post} <- attach_uploads(socket, post) do
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
    case fetch_post(post_id) do
      {:ok, post} ->
        case Operations.detach(post, :documents, blob_id: blob_id) do
          {:ok, _} ->
            {:noreply, socket |> put_flash(:info, "Document unlinked") |> reload_posts()}

          {:error, e} ->
            {:noreply, put_flash(socket, :error, format_error(e))}
        end

      :error ->
        {:noreply, put_flash(socket, :error, "Post not found")}
    end
  end

  def handle_event("purge-photos", %{"post-id" => post_id}, socket) do
    case fetch_post(post_id) do
      {:ok, post} ->
        case Operations.purge(post, :photos, all: true) do
          {:ok, _} -> {:noreply, socket |> put_flash(:info, "Photos cleared") |> reload_posts()}
          {:error, e} -> {:noreply, put_flash(socket, :error, format_error(e))}
        end

      :error ->
        {:noreply, put_flash(socket, :error, "Post not found")}
    end
  end

  defp attach_uploads(socket, post) do
    Enum.reduce_while(
      [:cover_image, :photos, :videos, :documents],
      {:ok, post},
      fn slot, {:ok, post} ->
        case consume_slot(socket, post, slot) do
          {:ok, post} -> {:cont, {:ok, post}}
          {:error, error} -> {:halt, {:error, error}}
        end
      end
    )
  end

  defp consume_slot(socket, post, slot) do
    results =
      consume_uploaded_entries(socket, slot, fn %{path: path}, entry ->
        bytes = File.read!(path)

        {:ok,
         Operations.attach(post, slot, bytes,
           filename: entry.client_name,
           content_type: entry.client_type
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

  defp fetch_post(id) do
    case Ash.get(Post, id) do
      {:ok, post} -> {:ok, Ash.load!(post, @load_spec)}
      _ -> :error
    end
  end

  defp reload_posts(socket) do
    posts =
      Post
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.Query.limit(20)
      |> Ash.read!()
      |> Ash.load!(@load_spec)

    assign(socket, posts: posts)
  end

  defp tap_post(socket, _post), do: socket

  defp format_error(%Ash.Error.Invalid{} = err), do: Exception.message(err)
  defp format_error(other), do: inspect(other)

  defp mime_badge(blob) do
    # Prefer the detected content_type from the FileInfo analyzer when it
    # disagrees with the upload header — that's the whole point of sniffing.
    detected = blob.metadata && blob.metadata["detected_content_type"]
    detected || blob.content_type || "unknown"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <section class="space-y-8">
        <header class="space-y-1">
          <h1 class="text-3xl font-bold">Feed</h1>
          <p class="text-base-content/70">
            Photos and videos go to S3; documents go to local Disk. <code>/media/*</code>
            proxies S3 reads, <code>/files/documents/*</code>
            serves signed Disk URLs.
          </p>
        </header>

        <.form
          for={@form}
          phx-submit="create"
          phx-change="validate"
          class="rounded-box border border-base-300 p-4 space-y-3"
        >
          <textarea
            name="post[body]"
            placeholder="What's on your mind?"
            class="textarea textarea-bordered w-full"
            rows="2"
          >{Phoenix.HTML.Form.input_value(@form, :body)}</textarea>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
            <.upload_picker label="Cover image (S3)" upload={@uploads.cover_image} />
            <.upload_picker label="Photos (S3, many)" upload={@uploads.photos} />
            <.upload_picker label="Videos (S3, many)" upload={@uploads.videos} />
            <.upload_picker label="Documents (Disk, many)" upload={@uploads.documents} />
          </div>

          <button type="submit" class="btn btn-primary btn-sm">Post</button>
        </.form>

        <div
          :if={@posts == []}
          class="rounded-box border border-dashed border-base-300 p-8 text-center text-base-content/70"
        >
          No posts yet. Be the first.
        </div>

        <article :for={post <- @posts} class="rounded-box border border-base-300 p-4 space-y-3">
          <header class="flex items-baseline justify-between">
            <span class="font-medium">{post.author && post.author.email}</span>
            <time class="text-xs text-base-content/60">
              {Calendar.strftime(post.inserted_at, "%Y-%m-%d %H:%M")}
            </time>
          </header>

          <p class="whitespace-pre-wrap">{post.body}</p>

          <img
            :if={post.cover_image_url}
            src={post.cover_image_url}
            alt="cover"
            class="rounded-box max-h-72 object-cover w-full"
          />

          <div :if={post.photos != []} class="space-y-2">
            <div class="flex items-center justify-between text-sm">
              <span>Photos ({length(post.photos)})</span>
              <button
                type="button"
                class="link link-error text-xs"
                phx-click="purge-photos"
                phx-value-post-id={post.id}
                data-confirm="Delete all photos?"
              >
                Clear all
              </button>
            </div>
            <div class="grid grid-cols-3 gap-2">
              <img
                :for={photo <- post.photos}
                src={photo.url}
                class="rounded-box h-24 w-full object-cover"
              />
            </div>
          </div>

          <div :if={post.videos != []} class="space-y-1 text-sm">
            <span>Videos ({length(post.videos)})</span>
            <ul class="list-disc list-inside">
              <li :for={vid <- post.videos}>
                <a href={vid.url} target="_blank" class="link">{vid.blob.filename}</a>
              </li>
            </ul>
          </div>

          <dl
            :if={post.taken_at || post.camera || post.gps_lat}
            class="text-xs grid grid-cols-[max-content_1fr] gap-x-3"
          >
            <dt :if={post.taken_at} class="font-medium">Taken at</dt>
            <dd :if={post.taken_at}>{post.taken_at}</dd>
            <dt :if={post.camera} class="font-medium">Camera</dt>
            <dd :if={post.camera}>{post.camera}</dd>
            <dt :if={post.gps_lat} class="font-medium">GPS</dt>
            <dd :if={post.gps_lat}>{post.gps_lat}, {post.gps_lng}</dd>
          </dl>

          <div :if={post.documents != []} class="space-y-1 text-sm">
            <span>Documents ({length(post.documents)})</span>
            <ul class="space-y-1">
              <li :for={doc <- post.documents} class="flex flex-col gap-1">
                <div class="flex items-center justify-between gap-2">
                  <span class="flex items-center gap-2">
                    <a href={doc.url} class="link" target="_blank">{doc.blob.filename}</a>
                    <span class="badge badge-sm badge-outline">{mime_badge(doc.blob)}</span>
                  </span>
                  <button
                    type="button"
                    class="btn btn-ghost btn-xs"
                    phx-click="detach-document"
                    phx-value-post-id={post.id}
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
      </section>
    </Layouts.app>
    """
  end

  attr :label, :string, required: true
  attr :upload, :any, required: true

  defp upload_picker(assigns) do
    ~H"""
    <label class="space-y-1 block">
      <span class="font-medium">{@label}</span>
      <.live_file_input upload={@upload} class="file-input file-input-bordered file-input-sm w-full" />
      <div :for={entry <- @upload.entries} class="text-xs">
        <span>{entry.client_name}</span>
        <span :for={err <- upload_errors(@upload, entry)} class="text-error">· {err}</span>
      </div>
    </label>
    """
  end
end
