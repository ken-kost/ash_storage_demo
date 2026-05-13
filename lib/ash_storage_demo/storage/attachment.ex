defmodule AshStorageDemo.Storage.Attachment do
  use Ash.Resource,
    domain: AshStorageDemo.Storage,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage.AttachmentResource]

  postgres do
    table "storage_attachments"
    repo AshStorageDemo.Repo
  end

  attachment do
    blob_resource(AshStorageDemo.Storage.Blob)
  end

  attributes do
    uuid_primary_key :id
  end
end
