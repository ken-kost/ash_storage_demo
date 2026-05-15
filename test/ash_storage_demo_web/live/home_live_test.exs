defmodule AshStorageDemoWeb.HomeLiveTest do
  use AshStorageDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "GET / renders the empty-feed placeholder", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~ "AshStorageDemo"
    assert html =~ "No posts yet"
  end
end
