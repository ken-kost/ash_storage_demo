defmodule AshStorageDemo.Feed.Story do
  use Ash.Resource,
    otp_app: :ash_storage_demo,
    domain: AshStorageDemo.Feed,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage]

  postgres do
    table "stories"
    repo AshStorageDemo.Repo

    references do
      reference :author, on_delete: :nilify
    end
  end

  storage do
    blob_resource(AshStorageDemo.Storage.Blob)
    attachment_resource(AshStorageDemo.Storage.Attachment)

    service({AshStorage.Service.S3, Application.compile_env(:ash_storage_demo, :s3)})

    # dependent: :purge is the default — files are removed when the story
    # is destroyed (regular destroy; soft destroy actions would skip this).
    has_one_attached(:media)
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept []

      change fn changeset, _ ->
        expires_at = DateTime.utc_now() |> DateTime.add(24, :hour)
        Ash.Changeset.change_attribute(changeset, :expires_at, expires_at)
      end

      change relate_actor(:author, allow_nil?: true)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :expires_at, :utc_datetime_usec do
      public? true
      allow_nil? false
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
