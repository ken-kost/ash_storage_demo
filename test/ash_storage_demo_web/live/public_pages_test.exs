defmodule AshStorageDemoWeb.PublicPagesTest do
  use AshStorageDemoWeb.ConnCase, async: false

  alias AshStorageDemo.Fixtures

  describe "/u/:id (PublicFeedLive)" do
    test "guests can view a user's public feed", %{conn: conn} do
      user = user()
      Fixtures.post(user, "first public post")
      Fixtures.post(user, "second public post")

      {:ok, view, html} = live(conn, ~p"/u/#{user.id}")

      # Renders the user's posts, but no composer.
      assert html =~ "first public post"
      assert html =~ "second public post"
      assert html =~ to_string(user.email)
      refute has_element?(view, ".composer")
      assert has_element?(view, "[data-role='feed-copy-link']")
      assert has_element?(view, "[data-role='post-copy-link']")
      assert has_element?(view, "[data-role='post-open-link']")
    end

    test "redirects to / for unknown user ids", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/"}}} =
               live(conn, ~p"/u/00000000-0000-0000-0000-000000000000")
    end

    test "copy-link event surfaces a flash toast", %{conn: conn} do
      user = user()
      Fixtures.post(user, "hi")

      {:ok, view, _} = live(conn, ~p"/u/#{user.id}")
      render_click(element(view, "[data-role='feed-copy-link']"))

      assert render(view) =~ "Link copied to clipboard"
    end
  end

  describe "/p/:id (PublicPostLive)" do
    test "guests can view a single post", %{conn: conn} do
      user = user()
      post = Fixtures.post(user, "shareable body text")

      {:ok, view, html} = live(conn, ~p"/p/#{post.id}")

      assert html =~ "shareable body text"
      assert html =~ to_string(user.email)
      assert has_element?(view, "[data-role='post-copy-link-top']")
      # The single-post page links back to the author's public feed.
      assert has_element?(view, "[data-role='post-author-link'][href='/u/" <> user.id <> "']")
    end

    test "redirects to / for unknown post ids", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/"}}} =
               live(conn, ~p"/p/00000000-0000-0000-0000-000000000000")
    end
  end
end
