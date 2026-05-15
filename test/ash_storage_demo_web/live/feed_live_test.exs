defmodule AshStorageDemoWeb.FeedLiveTest do
  use AshStorageDemoWeb.ConnCase, async: false

  alias AshStorage.Operations
  alias AshStorageDemo.Feed.Post
  alias AshStorageDemo.Fixtures

  setup %{conn: conn} do
    user = user()
    {:ok, conn: log_in_user(conn, user), user: user}
  end

  test "renders the post composer and empty-feed message", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/feed")
    assert html =~ "Feed"
    assert html =~ "no posts yet"
    assert has_element?(view, "[data-role='back-button']")
    assert has_element?(view, "button", "Post")
  end

  test "submitting the composer creates a Post and re-renders the timeline", %{conn: conn} do
    {:ok, view, _} = live(conn, ~p"/feed")

    view
    |> form("#upload-form-feed, form", post: %{body: "hello world"})
    |> render_submit()

    assert render(view) =~ "hello world"

    assert [%Post{body: "hello world"}] =
             Post |> Ash.read!(authorize?: false)
  end

  test "lists existing posts with attached documents and renders detach button", %{
    conn: conn,
    user: user
  } do
    p = Fixtures.post(user, "with doc")

    {:ok, _} =
      Operations.attach(p, :documents, "hi",
        filename: "notes.txt",
        content_type: "text/plain",
        actor: user
      )

    {:ok, view, html} = live(conn, ~p"/feed")

    assert html =~ "with doc"
    assert html =~ "notes.txt"
    assert has_element?(view, "button", "Unlink")
  end

  test "renders Copy-link buttons and a link to the public feed", %{conn: conn, user: user} do
    Fixtures.post(user, "shareable")

    {:ok, view, _} = live(conn, ~p"/feed")

    assert has_element?(view, "[data-role='feed-copy-link']")
    assert has_element?(view, "[data-role='post-copy-link']")
    assert has_element?(view, "[data-role='view-public-feed']")
    assert has_element?(view, "[data-role='post-open-link'][href='/p/" <> "#{Enum.at(Ash.read!(Post, authorize?: false), 0).id}']")
  end

  test "copy-link event sets the flash so the toast pill renders", %{conn: conn, user: user} do
    Fixtures.post(user, "shareable")

    {:ok, view, _} = live(conn, ~p"/feed")

    render_click(element(view, "[data-role='feed-copy-link']"))

    assert render(view) =~ "Link copied to clipboard"
  end
end
