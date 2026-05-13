defmodule AshStorageDemo.Storage.Attachment do
  use Ash.Resource,
    domain: AshStorageDemo.Storage,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage.AttachmentResource]

  postgres do
    table "storage_attachments"
    repo AshStorageDemo.Repo

    references do
      reference :user, on_delete: :delete
      reference :post, on_delete: :delete
    end
  end

  attachment do
    blob_resource(AshStorageDemo.Storage.Blob)
    belongs_to_resource(:user, AshStorageDemo.Accounts.User)
    belongs_to_resource(:post, AshStorageDemo.Feed.Post)
  end

  attributes do
    uuid_primary_key :id
  end
end
