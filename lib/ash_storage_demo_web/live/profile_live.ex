defmodule AshStorageDemoWeb.ProfileLive do
  use AshStorageDemoWeb, :live_view

  alias AshStorage.Operations

  @impl true
  def mount(_params, _session, socket) do
    user =
      socket.assigns.current_user
      |> Ash.load!([:avatar, :avatar_url, :cover_photo, :cover_photo_url])

    {:ok,
     socket
     |> assign(user: user)
     |> allow_upload(:avatar,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: 8_000_000
     )
     |> allow_upload(:cover_photo,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: 16_000_000
     )}
  end

  @impl true
  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def handle_event("upload-" <> field, _params, socket) when field in ["avatar", "cover_photo"] do
    attachment = String.to_existing_atom(field)
    upload_key = attachment

    case consume_uploaded_entries(socket, upload_key, fn %{path: path}, entry ->
           bytes = File.read!(path)

           {:ok,
            Operations.attach(socket.assigns.user, attachment, bytes,
              filename: entry.client_name,
              content_type: entry.client_type
            )}
         end) do
      [{:ok, _}] ->
        {:noreply,
         socket
         |> put_flash(:info, "#{format_field(field)} updated")
         |> reload_user()}

      [{:error, error}] ->
        {:noreply, put_flash(socket, :error, format_error(error))}

      [] ->
        {:noreply, put_flash(socket, :error, "Pick a file first")}
    end
  end

  def handle_event("purge-" <> field, _params, socket) when field in ["avatar", "cover_photo"] do
    attachment = String.to_existing_atom(field)

    case Operations.purge(socket.assigns.user, attachment) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{format_field(field)} removed")
         |> reload_user()}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, format_error(error))}
    end
  end

  defp reload_user(socket) do
    user =
      socket.assigns.user
      |> Ash.load!([:avatar, :avatar_url, :cover_photo, :cover_photo_url], reuse_values?: false)

    assign(socket, user: user)
  end

  defp format_field("avatar"), do: "Avatar"
  defp format_field("cover_photo"), do: "Cover photo"

  defp format_error(%Ash.Error.Invalid{} = err), do: Exception.message(err)
  defp format_error(other), do: inspect(other)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <section class="space-y-8">
        <header class="space-y-1">
          <h1 class="text-3xl font-bold">Your profile</h1>
          <p class="text-base-content/70">
            Avatar and cover photo upload directly to the configured AshStorage S3 service.
          </p>
        </header>

        <.attachment_panel
          title="Avatar"
          upload={@uploads.avatar}
          url={@user.avatar_url}
          field="avatar"
        />

        <.attachment_panel
          title="Cover photo"
          upload={@uploads.cover_photo}
          url={@user.cover_photo_url}
          field="cover_photo"
        />
      </section>
    </Layouts.app>
    """
  end

  attr :title, :string, required: true
  attr :upload, :any, required: true
  attr :url, :string, default: nil
  attr :field, :string, required: true

  defp attachment_panel(assigns) do
    ~H"""
    <article class="rounded-box border border-base-300 p-6 space-y-4">
      <header class="flex items-center justify-between">
        <h2 class="text-xl font-semibold">{@title}</h2>
        <div :if={@url} class="flex items-center gap-2">
          <a href={@url} class="link link-primary text-sm" target="_blank">View current</a>
          <button
            type="button"
            class="btn btn-ghost btn-xs"
            phx-click={"purge-" <> @field}
            data-confirm={"Remove " <> String.downcase(@title) <> "?"}
          >
            Remove
          </button>
        </div>
      </header>

      <div :if={@url} class="bg-base-200 rounded-box p-2 max-w-sm">
        <img src={@url} alt={@title} class="rounded-box max-h-48 object-cover" />
      </div>

      <form
        id={"upload-form-" <> @field}
        phx-change="validate"
        phx-submit={"upload-" <> @field}
        class="space-y-3"
      >
        <.live_file_input upload={@upload} class="file-input file-input-bordered w-full" />
        <div :for={entry <- @upload.entries} class="text-sm">
          <progress class="progress progress-primary w-full" value={entry.progress} max="100" />
          <span>{entry.client_name}</span>
          <span :for={err <- upload_errors(@upload, entry)} class="text-error">
            · {error_to_string(err)}
          </span>
        </div>
        <button type="submit" class="btn btn-primary btn-sm">Upload</button>
      </form>
    </article>
    """
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "Unsupported type"
  defp error_to_string(:too_many_files), do: "Only one file"
  defp error_to_string(other), do: to_string(other)
end
