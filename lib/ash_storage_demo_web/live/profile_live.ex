defmodule AshStorageDemoWeb.ProfileLive do
  use AshStorageDemoWeb, :live_view

  import AshStorageDemoWeb.StorageComponents
  alias AshStorage.Operations

  @load_spec [
    :avatar_url,
    :avatar_small_url,
    :avatar_medium_url,
    :avatar_large_url,
    :cover_photo_url,
    avatar: :blob,
    cover_photo: :blob
  ]

  @impl true
  def mount(_params, _session, socket) do
    user = Ash.load!(socket.assigns.current_user, @load_spec, authorize?: false)

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

    case consume_uploaded_entries(socket, attachment, fn %{path: path}, entry ->
           bytes = File.read!(path)

           {:ok,
            Operations.attach(socket.assigns.user, attachment, bytes,
              filename: entry.client_name,
              content_type: entry.client_type,
              authorize?: false
            )}
         end) do
      [{:ok, _}] ->
        {:noreply, socket |> put_flash(:info, "#{format_field(field)} updated") |> reload_user()}

      [{:error, error}] ->
        {:noreply, put_flash(socket, :error, format_error(error))}

      [] ->
        {:noreply, put_flash(socket, :error, "Pick a file first")}
    end
  end

  def handle_event("purge-" <> field, _params, socket) when field in ["avatar", "cover_photo"] do
    attachment = String.to_existing_atom(field)

    case Operations.purge(socket.assigns.user, attachment, authorize?: false) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "#{format_field(field)} removed") |> reload_user()}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, format_error(error))}
    end
  end

  defp reload_user(socket) do
    user = Ash.load!(socket.assigns.user, @load_spec, reuse_values?: false, authorize?: false)
    assign(socket, user: user)
  end

  defp dominant_color(%{blob: %{metadata: %{"dominant_color" => hex}}}) when is_binary(hex),
    do: hex

  defp dominant_color(_), do: nil

  defp format_field("avatar"), do: "Avatar"
  defp format_field("cover_photo"), do: "Cover photo"

  defp format_error(%Ash.Error.Invalid{} = err), do: Exception.message(err)
  defp format_error(other), do: inspect(other)

  defp short_id(nil), do: "—"

  defp short_id(id) when is_binary(id) do
    case String.length(id) do
      len when len > 12 ->
        String.slice(id, 0, 7) <> "…" <> String.slice(id, -4, 4)

      _ ->
        id
    end
  end

  defp short_id(other), do: inspect(other)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} active="profile">
      <Layouts.back_button />
      <div class="page-head">
        <h1>Your profile</h1>
        <p class="page-sub">
          Single-attachment slots. Uploads land on <strong>S3</strong>, then a variant
          chain emits thumbnails and a dominant-color sample.
        </p>
      </div>

      <.avatar_panel user={@user} upload={@uploads.avatar} tint={dominant_color(@user.avatar)} />
      <.cover_panel user={@user} upload={@uploads.cover_photo} />
    </Layouts.app>
    """
  end

  attr :user, :any, required: true
  attr :upload, :any, required: true
  attr :tint, :string, default: nil

  defp avatar_panel(assigns) do
    ~H"""
    <article class="panel" data-role="avatar-panel">
      <header class="panel-head">
        <div>
          <h2>Avatar</h2>
          <span class="panel-sub">256×256 square · auto-cropped variants generated</span>
        </div>
        <div class="panel-tools">
          <span :if={@tint} class="color-chip" style={"--chip-color: #{@tint};"}>
            <span>{@tint}</span>
          </span>
          <a :if={@user.avatar_url} class="link-quiet" href={@user.avatar_url} target="_blank">
            View current
          </a>
          <button
            :if={@user.avatar}
            type="button"
            class="link-quiet danger"
            phx-click="purge-avatar"
            data-confirm="Remove avatar?"
          >
            Remove
          </button>
        </div>
      </header>

      <div class="panel-body avatar-body">
        <div class="avatar-preview" style={@tint && "background: #{@tint};"}>
          <img :if={@user.avatar_url} src={@user.avatar_url} alt="avatar" />
          <span :if={!@user.avatar_url}>{initial(@user)}</span>
        </div>
        <div class="avatar-variants">
          <.variant_tile
            size="lg"
            label="original"
            px="1024"
            url={@user.avatar_large_url}
            tint={@tint}
            initial={initial(@user)}
          />
          <.variant_tile
            size="md"
            label="display"
            px="256"
            url={@user.avatar_medium_url}
            tint={@tint}
            initial={initial(@user)}
          />
          <.variant_tile
            size="sm"
            label="medium"
            px="64"
            url={@user.avatar_small_url}
            tint={@tint}
            initial={initial(@user)}
          />
          <.variant_tile
            size="xs"
            label="small"
            px="24"
            url={@user.avatar_small_url}
            tint={@tint}
            initial={initial(@user)}
          />
        </div>
      </div>

      <form
        id="upload-form-avatar"
        phx-change="validate"
        phx-submit="upload-avatar"
        class="panel-upload"
      >
        <label class="file-input-zone" for={@upload.ref}>
          <svg
            viewBox="0 0 24 24"
            width="14"
            height="14"
            fill="none"
            stroke="currentColor"
            stroke-width="1.7"
          >
            <path d="M12 16V4M7 9l5-5 5 5M4 20h16" />
          </svg>
          <span>Drop a new avatar, or <u>browse</u></span>
          <span class="file-hint">.jpg .png .webp · max 8MB</span>
          <.live_file_input upload={@upload} class="hidden" />
        </label>
        <button type="submit" class="btn btn-primary btn-sm">Upload</button>
      </form>

      <div :for={entry <- @upload.entries} class="text-sm mb-3">
        <progress class="progress progress-primary w-full" value={entry.progress} max="100" />
        <span class="font-mono text-xs">{entry.client_name}</span>
        <span :for={err <- upload_errors(@upload, entry)} class="text-error text-xs">
          · {error_to_string(err)}
        </span>
      </div>

      <footer :if={@user.avatar} class="panel-foot">
        <.field k="blob_id" v={short_id(@user.avatar.blob && @user.avatar.blob.id)} />
        <.field
          k="service"
          v={(@user.avatar.blob && to_string(@user.avatar.blob.service_name)) || "—"}
        />
        <.field
          k="content_type"
          v={(@user.avatar.blob && @user.avatar.blob.content_type) || "—"}
        />
        <.field
          k="byte_size"
          v={format_bytes(@user.avatar.blob && @user.avatar.blob.byte_size)}
        />
      </footer>
    </article>
    """
  end

  attr :user, :any, required: true
  attr :upload, :any, required: true

  defp cover_panel(assigns) do
    ~H"""
    <article class="panel" data-role="cover-panel">
      <header class="panel-head">
        <div>
          <h2>Cover photo</h2>
          <span class="panel-sub">1600×400 wide · single attachment</span>
        </div>
        <div class="panel-tools">
          <a
            :if={@user.cover_photo_url}
            class="link-quiet"
            href={@user.cover_photo_url}
            target="_blank"
          >
            View current
          </a>
          <button
            :if={@user.cover_photo}
            type="button"
            class="link-quiet danger"
            phx-click="purge-cover_photo"
            data-confirm="Remove cover photo?"
          >
            Remove
          </button>
        </div>
      </header>

      <div class="panel-body">
        <img
          :if={@user.cover_photo_url}
          src={@user.cover_photo_url}
          alt="cover"
          class="post-cover"
        />
        <.placeholder :if={!@user.cover_photo_url} label="cover · 1600×400 · jpeg" height={170} />
      </div>

      <form
        id="upload-form-cover_photo"
        phx-change="validate"
        phx-submit="upload-cover_photo"
        class="panel-upload"
      >
        <label class="file-input-zone" for={@upload.ref}>
          <svg
            viewBox="0 0 24 24"
            width="14"
            height="14"
            fill="none"
            stroke="currentColor"
            stroke-width="1.7"
          >
            <path d="M12 16V4M7 9l5-5 5 5M4 20h16" />
          </svg>
          <span>Drop a new cover, or <u>browse</u></span>
          <span class="file-hint">.jpg .png .webp · max 16MB</span>
          <.live_file_input upload={@upload} class="hidden" />
        </label>
        <button type="submit" class="btn btn-primary btn-sm">Upload</button>
      </form>

      <div :for={entry <- @upload.entries} class="text-sm mb-3">
        <progress class="progress progress-primary w-full" value={entry.progress} max="100" />
        <span class="font-mono text-xs">{entry.client_name}</span>
        <span :for={err <- upload_errors(@upload, entry)} class="text-error text-xs">
          · {error_to_string(err)}
        </span>
      </div>

      <footer :if={@user.cover_photo} class="panel-foot">
        <.field k="blob_id" v={short_id(@user.cover_photo.blob && @user.cover_photo.blob.id)} />
        <.field
          k="service"
          v={(@user.cover_photo.blob && to_string(@user.cover_photo.blob.service_name)) || "—"}
        />
        <.field
          k="content_type"
          v={(@user.cover_photo.blob && @user.cover_photo.blob.content_type) || "—"}
        />
        <.field
          k="byte_size"
          v={format_bytes(@user.cover_photo.blob && @user.cover_photo.blob.byte_size)}
        />
      </footer>
    </article>
    """
  end

  attr :size, :string, required: true
  attr :label, :string, required: true
  attr :px, :string, required: true
  attr :url, :string, default: nil
  attr :tint, :string, default: nil
  attr :initial, :string, default: "?"

  defp variant_tile(assigns) do
    ~H"""
    <div class={["variant", "size-" <> @size]}>
      <div class="variant-tile" style={@tint && "background: #{@tint};"}>
        <img :if={@url} src={@url} alt={@label} />
        <span :if={!@url}>{@initial}</span>
      </div>
      <span class="variant-label">{@label}</span>
      <span class="variant-size mono">{@px}px</span>
    </div>
    """
  end

  defp initial(%{email: email}) when not is_nil(email) do
    email |> to_string() |> String.first() |> Kernel.||("?") |> String.upcase()
  end

  defp initial(_), do: "?"

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "Unsupported type"
  defp error_to_string(:too_many_files), do: "Only one file"
  defp error_to_string(other), do: to_string(other)
end
