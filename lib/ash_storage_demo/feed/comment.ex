defmodule AshStorageDemo.Feed.Comment do
  use Ash.Resource,
    otp_app: :ash_storage_demo,
    domain: AshStorageDemo.Feed,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage]

  postgres do
    table "comments"
    repo AshStorageDemo.Repo

    references do
      reference :post, on_delete: :delete
      reference :author, on_delete: :nilify
    end
  end

  storage do
    blob_resource(AshStorageDemo.Storage.Blob)
    attachment_resource(AshStorageDemo.Storage.Attachment)

    service({AshStorage.Service.Disk, root: "priv/storage/comments", base_url: "/files/comments"})

    has_many_attached(:attachments)
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:body, :post_id]
      change relate_actor(:author, allow_nil?: true)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :body, :string do
      public? true
      allow_nil? false
      constraints max_length: 1_000
    end

    timestamps()
  end

  relationships do
    belongs_to :post, AshStorageDemo.Feed.Post do
      allow_nil? false
      public? true
    end

    belongs_to :author, AshStorageDemo.Accounts.User do
      allow_nil? true
      public? true
    end
  end
end
