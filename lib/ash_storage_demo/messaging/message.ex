defmodule AshStorageDemo.Messaging.Message do
  use Ash.Resource,
    otp_app: :ash_storage_demo,
    domain: AshStorageDemo.Messaging,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage]

  postgres do
    table "messages"
    repo AshStorageDemo.Repo

    references do
      reference :sender, on_delete: :nilify
      reference :recipient, on_delete: :nilify
    end
  end

  storage do
    blob_resource(AshStorageDemo.Storage.Blob)
    attachment_resource(AshStorageDemo.Storage.Attachment)

    service({AshStorage.Service.S3, Application.compile_env(:ash_storage_demo, :s3)})

    # dependent: false — destroying a message leaves attached files behind.
    # An external retention job is expected to reap them later.
    has_many_attached(:files, dependent: false)
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:body, :recipient_id]
      change relate_actor(:sender, allow_nil?: true)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :body, :string do
      public? true
      allow_nil? false
      constraints max_length: 2_000
    end

    timestamps()
  end

  relationships do
    belongs_to :sender, AshStorageDemo.Accounts.User do
      allow_nil? true
      public? true
    end

    belongs_to :recipient, AshStorageDemo.Accounts.User do
      allow_nil? true
      public? true
    end
  end
end
