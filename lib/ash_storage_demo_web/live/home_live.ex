defmodule AshStorageDemoWeb.HomeLive do
  use AshStorageDemoWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, posts: [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <section class="space-y-6">
        <header class="space-y-2">
          <h1 class="text-3xl font-bold">AshStorageDemo</h1>
          <p class="text-base-content/70">
            A demo social feed exercising every <code>ash_storage</code> feature.
          </p>
        </header>

        <div
          :if={@posts == []}
          class="rounded-box border border-dashed border-base-300 p-8 text-center space-y-3"
        >
          <p class="text-lg font-medium">No posts yet</p>
          <p class="text-base-content/70">
            Posts will show up here as soon as the feed is wired up.
          </p>

          <div class="flex justify-center gap-2">
            <.link
              :if={@current_user}
              navigate="/feed"
              class="btn btn-primary btn-sm"
              data-role="home-cta-feed"
            >
              Go to feed
            </.link>
            <.link
              :if={!@current_user}
              navigate="/sign-in"
              class="btn btn-primary btn-sm"
              data-role="home-cta-sign-in"
            >
              Sign in to post
            </.link>
            <.link
              :if={!@current_user}
              navigate="/register"
              class="btn btn-ghost btn-sm"
              data-role="home-cta-register"
            >
              Register
            </.link>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end
end
