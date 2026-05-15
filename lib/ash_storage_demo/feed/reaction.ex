defmodule AshStorageDemo.Feed.Reaction do
  use Ash.Resource,
    otp_app: :ash_storage_demo,
    domain: AshStorageDemo.Feed,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage]

  postgres do
    table "reactions"
    repo AshStorageDemo.Repo

    references do
      reference :post, on_delete: :delete
      reference :author, on_delete: :nilify
    end
  end

  storage do
    blob_resource(AshStorageDemo.Storage.Blob)
    attachment_resource(AshStorageDemo.Storage.StickerAttachment)

    service({AshStorage.Service.S3, Application.compile_env(:ash_storage_demo, :s3)})

    has_one_attached :sticker do
      variant(:outlined, {AshStorageDemo.Variants.OutlinedSticker, radius: 4})
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:emoji, :post_id]
      change relate_actor(:author, allow_nil?: true)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :emoji, :string do
      public? true
      allow_nil? false
      constraints max_length: 8
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
