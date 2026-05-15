defmodule AshStorageDemo.Storage.Blob do
  use Ash.Resource,
    domain: AshStorageDemo.Storage,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage.BlobResource]

  postgres do
    table "storage_blobs"
    repo AshStorageDemo.Repo
  end

  blob do
  end

  attributes do
    uuid_primary_key :id
  end
end
