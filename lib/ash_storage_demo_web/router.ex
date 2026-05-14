defmodule AshStorageDemoWeb.Router do
  use AshStorageDemoWeb, :router

  import Oban.Web.Router
  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AshStorageDemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/", AshStorageDemoWeb do
    pipe_through :browser

    ash_authentication_live_session :authenticated_routes,
      on_mount: [{AshStorageDemoWeb.LiveUserAuth, :live_user_optional}] do
      live "/", HomeLive
      live "/u/:id", PublicFeedLive
      live "/p/:id", PublicPostLive
    end

    ash_authentication_live_session :require_authenticated,
      on_mount: [{AshStorageDemoWeb.LiveUserAuth, :live_user_required}] do
      live "/profile", ProfileLive
      live "/feed", FeedLive
      live "/storage-admin", StorageAdminLive
    end
  end

  forward "/files/documents", AshStorage.Plug.DiskServe, root: "priv/storage/documents"

  forward "/files/cover_images_mirror", AshStorage.Plug.DiskServe,
    root: "priv/storage/cover_images_mirror"

  forward "/media", AshStorage.Plug.Proxy,
    service: {AshStorage.Service.S3, Application.compile_env(:ash_storage_demo, :s3)}

  # Alternative S3 access pattern: issue an HTTP redirect to a presigned
  # service URL instead of streaming bytes through the app. FeedLive exposes
  # a toggle that flips rendered URLs between /media (proxy) and /r (redirect)
  # for comparison.
  forward "/r", AshStorage.Plug.Redirect,
    service: {AshStorage.Service.S3, Application.compile_env(:ash_storage_demo, :s3)}

  scope "/", AshStorageDemoWeb do
    pipe_through :browser

    auth_routes AuthController, AshStorageDemo.Accounts.User, path: "/auth"
    sign_out_route AuthController

    sign_in_route register_path: "/register",
                  auth_routes_prefix: "/auth",
                  on_mount: [{AshStorageDemoWeb.LiveUserAuth, :live_no_user}],
                  overrides: [
                    AshStorageDemoWeb.AuthOverrides,
                    Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI
                  ]
  end

  # Other scopes may use custom stacks.
  # scope "/api", AshStorageDemoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ash_storage_demo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AshStorageDemoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

    scope "/" do
      pipe_through :browser

      oban_dashboard("/oban")
    end
  end

  if Application.compile_env(:ash_storage_demo, :dev_routes) do
    import AshAdmin.Router

    scope "/admin" do
      pipe_through :browser

      ash_admin "/"
    end
  end
end
