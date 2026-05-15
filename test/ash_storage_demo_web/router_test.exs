defmodule AshStorageDemoWeb.RouterTest do
  use AshStorageDemoWeb.ConnCase, async: false

  describe "public routes" do
    test "GET / renders HomeLive for guests", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "AshStorageDemo"
      assert response(conn, 200) =~ "data-role=\"nav-sign-in\""
    end
  end

  describe "auth-gated LiveViews redirect when signed out" do
    for path <- ~w(/profile /feed /storage-admin) do
      @path path

      test "GET #{@path} redirects to /sign-in", %{conn: conn} do
        conn = get(conn, @path)
        assert redirected_to(conn) =~ "/sign-in"
      end
    end
  end

  describe "auth-gated LiveViews load for signed-in users" do
    setup %{conn: conn} do
      user = user()
      {:ok, conn: log_in_user(conn, user), user: user}
    end

    for {path, marker} <- [
          {"/profile", "Your profile"},
          {"/feed", "Feed"},
          {"/storage-admin", "Storage admin"}
        ] do
      @path path
      @marker marker

      test "GET #{@path} renders for signed-in user", %{conn: conn} do
        {:ok, _view, html} = live(conn, @path)
        assert html =~ @marker
      end
    end
  end
end
