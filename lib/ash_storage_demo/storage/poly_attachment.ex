defmodule AshStorageDemo.Storage.PolyAttachment do
  @moduledoc """
  Polymorphic attachment resource — no `belongs_to_resource` entries, so
  AshStorage materialises `record_type` + `record_id` columns and uses
  those to link attachments to their parent. Used by `Tagging.Tag.icons`
  to demonstrate the third attachment flavour from the AshStorage docs.
  """
  use Ash.Resource,
    domain: AshStorageDemo.Storage,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage.AttachmentResource]

  postgres do
    table "storage_poly_attachments"
    repo AshStorageDemo.Repo
  end

  attachment do
    blob_resource(AshStorageDemo.Storage.Blob)
  end

  attributes do
    uuid_primary_key :id
  end
end
