defmodule AshStorageDemoWeb.ProfileLiveTest do
  use AshStorageDemoWeb.ConnCase, async: false

  alias AshStorage.Operations

  setup %{conn: conn} do
    user = user()
    {:ok, conn: log_in_user(conn, user), user: user}
  end

  test "renders Avatar + Cover photo panels with a back button", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/profile")

    assert html =~ "Your profile"
    assert html =~ "Avatar"
    assert html =~ "Cover photo"
    assert has_element?(view, "[data-role='back-button']")
  end

  test "renders the current cover_photo when one is attached", %{conn: conn, user: user} do
    {:ok, _} =
      Operations.attach(user, :cover_photo, png_bytes(),
        filename: "c.png",
        content_type: "image/png",
        authorize?: false
      )

    {:ok, _view, html} = live(conn, ~p"/profile")
    assert html =~ "Remove"
  end

  test "purge-cover_photo removes the attachment", %{conn: conn, user: user} do
    {:ok, _} =
      Operations.attach(user, :cover_photo, png_bytes(),
        filename: "c.png",
        content_type: "image/png",
        authorize?: false
      )

    {:ok, view, _} = live(conn, ~p"/profile")

    render_click(view, "purge-cover_photo", %{})

    refute has_element?(view, "img[alt='Cover photo']")
    user = Ash.load!(user, [:cover_photo_url], authorize?: false, reuse_values?: false)
    assert is_nil(user.cover_photo_url)
  end
end
