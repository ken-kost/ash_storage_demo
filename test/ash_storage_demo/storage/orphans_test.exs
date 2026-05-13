defmodule AshStorageDemo.Storage.OrphansTest do
  use AshStorageDemo.DataCase, async: false

  alias AshStorage.Operations
  alias AshStorageDemo.Storage.{Blob, Orphans}

  test "orphan_blobs/0 returns blobs with no attachment in any table" do
    user = user()
    post = post(user)

    # 1. Attached blob — should NOT appear in orphans.
    {:ok, %{blob: linked}} =
      Operations.attach(post, :documents, "x",
        filename: "x.txt",
        content_type: "text/plain"
      )

    # 2. Manufactured orphan — detach the attachment row directly, leaving
    #    the blob behind without an owner. This is the exact shape the
    #    helper is supposed to surface.
    {:ok, %{blob: orphan}} =
      Operations.attach(post, :documents, "y",
        filename: "y.txt",
        content_type: "text/plain"
      )

    {:ok, _} = Operations.detach(post, :documents, blob_id: orphan.id)

    ids = Enum.map(Orphans.orphan_blobs(), & &1.id)
    refute linked.id in ids
    assert orphan.id in ids
  end

  test "purge_orphan_records/0 deletes orphan blob rows and returns count" do
    user = user()
    post = post(user)

    {:ok, %{blob: orphan}} =
      Operations.attach(post, :documents, "z",
        filename: "z.txt",
        content_type: "text/plain"
      )

    {:ok, _} = Operations.detach(post, :documents, blob_id: orphan.id)

    assert Orphans.purge_orphan_records() == 1
    assert {:error, _} = Ash.get(Blob, orphan.id, authorize?: false)
  end

  test "purge_orphan_records/0 is a no-op when nothing is orphaned" do
    assert Orphans.purge_orphan_records() == 0
  end
end
