defmodule AshStorageDemo.Feed.Post do
  use Ash.Resource,
    otp_app: :ash_storage_demo,
    domain: AshStorageDemo.Feed,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage]

  postgres do
    table "posts"
    repo AshStorageDemo.Repo

    references do
      reference :author, on_delete: :nilify
    end
  end

  storage do
    blob_resource(AshStorageDemo.Storage.Blob)
    attachment_resource(AshStorageDemo.Storage.Attachment)

    service({AshStorage.Service.S3, Application.compile_env(:ash_storage_demo, :s3)})

    has_one_attached(:cover_image)

    has_many_attached(:photos)

    has_many_attached(:videos)

    has_many_attached(:documents,
      service:
        {AshStorage.Service.Disk, root: "priv/storage/documents", base_url: "/files/documents"},
      dependent: :detach
    )
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:body]
      change relate_actor(:author, allow_nil?: true)
    end

    update :update do
      primary? true
      accept [:body]
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
    belongs_to :author, AshStorageDemo.Accounts.User do
      allow_nil? true
      public? true
    end
  end
end
