defmodule AshStorageDemoWeb.StorageAdminLiveTest do
  use AshStorageDemoWeb.ConnCase, async: false

  alias AshStorage.Operations
  alias AshStorageDemo.Fixtures

  setup %{conn: conn} do
    user = user()
    {:ok, conn: log_in_user(conn, user), user: user}
  end

  test "renders headers and zero stats with no blobs", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/storage-admin")
    assert html =~ "Storage admin"
    assert html =~ "Bytes per service"
    assert html =~ "Count per content-type"
    assert html =~ "Orphan blobs"
    assert has_element?(view, "[data-role='back-button']")
    assert html =~ "No blobs yet."
  end

  test "shows blobs and bumps orphan count after a detach", %{conn: conn, user: user} do
    p = Fixtures.post(user)

    {:ok, %{blob: blob}} =
      Operations.attach(p, :documents, "hi",
        filename: "k.txt",
        content_type: "text/plain",
        actor: user
      )

    {:ok, _view, html} = live(conn, ~p"/storage-admin")
    assert html =~ "k.txt"

    {:ok, _} = Operations.detach(p, :documents, blob_id: blob.id, actor: user)

    # Re-render after detach by re-running the mount; the LiveView itself
    # has no auto-refresh, but the purge button is the user-facing action.
    {:ok, _view2, html2} = live(conn, ~p"/storage-admin")
    assert html2 =~ "Orphan blobs"
    # Click the purge button — should drop the orphan and show success flash.
    {:ok, view3, _} = live(conn, ~p"/storage-admin")
    html3 = render_click(view3, "purge-orphans", %{})
    assert html3 =~ "Removed 1 orphan blob record"
  end
end
