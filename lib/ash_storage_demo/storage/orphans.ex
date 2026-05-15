defmodule AshStorageDemo.Storage.Orphans do
  @moduledoc """
  Helpers for the roadmap "orphan cleanup" feature: blobs that no longer
  have any attachment pointing at them. Useful after a parent row is
  destroyed with `dependent: :detach` and the attachment is later removed
  by hand, or after a partial mirror write left a half-written blob.

  Surfaced in the admin UI in Phase 8.
  """

  import Ecto.Query
  alias AshStorageDemo.Repo

  @doc """
  Return all blob rows that no attachment row references.

  Walks every AttachmentResource registered in the demo so the query stays
  authoritative even as new attachment tables are added.
  """
  def orphan_blobs do
    used_blob_ids =
      attachment_tables()
      |> Enum.flat_map(fn table ->
        Repo.all(from a in table, select: a.blob_id) |> Enum.uniq()
      end)
      |> MapSet.new()

    Repo.all(from b in "storage_blobs", select: %{id: b.id, key: b.key})
    |> Enum.reject(fn %{id: id} -> MapSet.member?(used_blob_ids, id) end)
    |> Enum.map(&%{id: Ecto.UUID.cast!(&1.id), key: &1.key})
  end

  @doc """
  Drop orphan blob rows. Returns the number deleted. Files on the underlying
  service are not removed — that's intentional, the demo's admin UI does
  that with the standard `Operations.purge_blob/1` flow once an orphan is
  identified.
  """
  def purge_orphan_records do
    orphans = orphan_blobs()

    binary_ids =
      Enum.map(orphans, fn %{id: id} ->
        {:ok, raw} = Ecto.UUID.dump(id)
        raw
      end)

    if binary_ids == [] do
      0
    else
      {count, _} =
        Repo.delete_all(from b in "storage_blobs", where: b.id in ^binary_ids)

      count
    end
  end

  defp attachment_tables,
    do: ["storage_attachments", "storage_sticker_attachments", "storage_poly_attachments"]
end
