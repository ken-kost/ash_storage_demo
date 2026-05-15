defmodule AshStorageDemoWeb.StoragePlugsTest do
  use AshStorageDemoWeb.ConnCase, async: false

  describe "/files/documents (DiskServe)" do
    test "404s on missing keys", %{conn: conn} do
      conn = get(conn, "/files/documents/does-not-exist")
      assert response(conn, 404) =~ "Not Found"
    end

    test "404s with empty path", %{conn: conn} do
      conn = get(conn, "/files/documents/")
      # Phoenix collapses the trailing slash to no path-info; DiskServe 404s.
      assert conn.status in [404]
    end
  end

  describe "/files/cover_images_mirror (DiskServe, mirror secondary)" do
    test "404s on missing keys", %{conn: conn} do
      conn = get(conn, "/files/cover_images_mirror/does-not-exist")
      assert response(conn, 404) =~ "Not Found"
    end
  end

  describe "/media (Proxy)" do
    # MinIO isn't reachable in this env. We still expect the plug to mount
    # and respond — the failure surfaces as a 5xx or a Req error, not a 404.
    test "request reaches the plug (returns non-404 even though S3 is down)", %{conn: conn} do
      conn = get(conn, "/media/anything")
      assert conn.status != 404
    end
  end

  describe "/r (Redirect)" do
    test "request reaches the plug", %{conn: conn} do
      conn = get(conn, "/r/anything")
      # Without a secret configured this should just 302 to the underlying
      # service's url/2 result (an S3 presigned URL).
      assert conn.status in [302, 303, 307]
    end
  end
end
