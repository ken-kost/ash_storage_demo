defmodule AshStorageDemoWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AshStorageDemoWeb, :html

  embed_templates "layouts/*"

  @doc """
  Renders your app layout — top nav with brand mark, page links, segmented
  theme switch (light / dark / system), and user chip. Body slot is
  centered in a 1100px shell that matches the design canvas width.
  """
  attr :flash, :map, required: true
  attr :current_user, :map, default: nil
  attr :active, :string, default: nil, doc: "active nav: feed | profile | storage"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="nav-bar" data-role="app-nav">
      <.link navigate="/" class="brand">
        <span class="brand-logo" aria-hidden="true">
          <img src={~p"/images/ash-logo.svg"} alt="" />
          <svg
            class="brand-tray"
            viewBox="0 0 40 12"
            fill="none"
            stroke="currentColor"
            stroke-width="1.4"
          >
            <path d="M2 2 H38" stroke-linecap="round" />
            <path
              d="M4 2 L7 10 a2 2 0 0 0 2 1 H31 a2 2 0 0 0 2 -1 L36 2"
              stroke-linejoin="round"
              stroke-linecap="round"
            />
          </svg>
        </span>
        <span class="brand-name">Ashtray</span>
      </.link>
      <div class="nav-flash" aria-live="polite" data-role="nav-flash">
        <.inline_flash kind={:info} flash={@flash} />
        <.inline_flash kind={:error} flash={@flash} />
      </div>
      <nav class="nav-links">
        <.link
          :if={@current_user}
          navigate="/feed"
          class={["nav-link", @active == "feed" && "is-active"]}
          data-role="nav-feed"
        >
          Feed
        </.link>
        <.link
          :if={@current_user}
          navigate="/profile"
          class={["nav-link", @active == "profile" && "is-active"]}
          data-role="nav-profile"
        >
          Profile
        </.link>
        <.link
          :if={@current_user}
          navigate="/storage-admin"
          class={["nav-link", @active == "storage" && "is-active"]}
          data-role="nav-storage-admin"
        >
          Storage
        </.link>
        <span :if={@current_user} class="nav-sep" />
        <.theme_switch />
        <span :if={@current_user} class="user-chip" data-role="current-user">
          <span class="user-avatar">
            <img
              :if={user_avatar_url(@current_user)}
              src={user_avatar_url(@current_user)}
              alt=""
            />
            <span :if={!user_avatar_url(@current_user)}>{user_initial(@current_user)}</span>
          </span>
          <span class="user-email">{to_string(@current_user.email)}</span>
        </span>
        <.link
          :if={@current_user}
          href="/sign-out"
          method="get"
          class="sign-out-chip"
          data-role="nav-sign-out"
          aria-label="Sign out"
        >
          <svg
            viewBox="0 0 24 24"
            width="13"
            height="13"
            fill="none"
            stroke="currentColor"
            stroke-width="1.7"
          >
            <path d="M9 4H6a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h3" stroke-linecap="round" />
            <path d="M16 8l4 4-4 4M20 12H10" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          <span>Sign out</span>
        </.link>
        <.link
          :if={!@current_user}
          navigate="/sign-in"
          class="btn btn-primary btn-sm"
          data-role="nav-sign-in"
        >
          Sign in
        </.link>
        <.link
          :if={!@current_user}
          navigate="/register"
          class="btn btn-outline btn-sm"
          data-role="nav-register"
        >
          Register
        </.link>
      </nav>
    </header>

    <main class="app-main">
      <div class="app-shell">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.connection_flashes />
    """
  end

  @doc """
  Inline flash pill rendered inside the top nav. Auto-dismisses after a
  short timeout via the `FlashAutoHide` JS hook.
  """
  attr :kind, :atom, required: true
  attr :flash, :map, required: true

  def inline_flash(assigns) do
    msg = Phoenix.Flash.get(assigns.flash, assigns.kind)
    assigns = assign(assigns, msg: msg, id: "nav-flash-#{assigns.kind}")

    ~H"""
    <div
      :if={@msg}
      id={@id}
      role="alert"
      phx-hook="FlashAutoHide"
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> JS.hide(to: "##{@id}")}
      data-flash-kind={@kind}
      class={["nav-flash-pill", "nav-flash-" <> Atom.to_string(@kind)]}
    >
      <span class="nav-flash-icon" aria-hidden="true">
        <svg
          :if={@kind == :info}
          viewBox="0 0 24 24"
          width="13"
          height="13"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
        >
          <circle cx="12" cy="12" r="9" />
          <path d="M12 8h.01M11 12h1v5h1" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
        <svg
          :if={@kind == :error}
          viewBox="0 0 24 24"
          width="13"
          height="13"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
        >
          <circle cx="12" cy="12" r="9" />
          <path d="M12 7v6m0 3v.5" stroke-linecap="round" />
        </svg>
      </span>
      <span class="nav-flash-msg">{@msg}</span>
      <button type="button" class="nav-flash-close" aria-label="Dismiss">×</button>
    </div>
    """
  end

  @doc """
  Floating connection-status flashes — only show when the live socket is
  disconnected.
  """
  def connection_flashes(assigns) do
    ~H"""
    <div id="connection-flashes" aria-live="polite">
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a back link, used as a small header on every nested LiveView.
  """
  attr :to, :string, default: "/"
  attr :label, :string, default: "Back to home"

  def back_button(assigns) do
    ~H"""
    <.link navigate={@to} class="back-link" data-role="back-button">
      <svg
        viewBox="0 0 24 24"
        width="13"
        height="13"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
      >
        <path d="M15 6l-6 6 6 6" />
      </svg>
      <span>{@label}</span>
    </.link>
    """
  end

  @doc """
  Segmented theme switcher: light / dark / system. The pill indicator
  comes from CSS that targets [data-theme=…] on <html>, so no JS state
  is needed — `phx:set-theme` flips the attribute and storage entry.
  """
  def theme_switch(assigns) do
    ~H"""
    <div class="theme-switch" role="group" aria-label="Theme">
      <button
        type="button"
        aria-label="Light"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4" />
      </button>
      <button
        type="button"
        aria-label="Dark"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4" />
      </button>
      <button
        type="button"
        aria-label="High contrast"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-eye-micro" class="size-4" />
      </button>
    </div>
    """
  end

  defp user_initial(%{email: email}) do
    email |> to_string() |> String.first() |> Kernel.||("?") |> String.upcase()
  end

  defp user_initial(_), do: "?"

  defp user_avatar_url(%{avatar_small_url: url}) when is_binary(url) and url != "", do: url
  defp user_avatar_url(%{avatar_url: url}) when is_binary(url) and url != "", do: url
  defp user_avatar_url(_), do: nil
end
