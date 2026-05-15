defmodule AshStorageDemo.Repo.Migrations.CascadeVariantOfBlobId do
  @moduledoc """
  `storage_blobs.variant_of_blob_id` was generated without an ON DELETE clause
  (defaults to NO ACTION in Postgres). That blocks any destroy of a primary
  blob that still has variant rows referencing it — surfacing in the LiveView
  as `"would leave records behind"` when a user clicks Remove on an avatar that
  has eager variants. The reference dev migration in `ash_storage` itself sets
  ON DELETE CASCADE; the snapshot just didn't carry it through to consumers.
  """
  use Ecto.Migration

  def up do
    drop constraint(:storage_blobs, "storage_blobs_variant_of_blob_id_fkey")

    alter table(:storage_blobs) do
      modify :variant_of_blob_id,
             references(:storage_blobs,
               column: :id,
               name: "storage_blobs_variant_of_blob_id_fkey",
               type: :uuid,
               prefix: "public",
               on_delete: :delete_all
             )
    end
  end

  def down do
    drop constraint(:storage_blobs, "storage_blobs_variant_of_blob_id_fkey")

    alter table(:storage_blobs) do
      modify :variant_of_blob_id,
             references(:storage_blobs,
               column: :id,
               name: "storage_blobs_variant_of_blob_id_fkey",
               type: :uuid,
               prefix: "public"
             )
    end
  end
end
