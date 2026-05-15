defmodule AshStorageDemo.Tagging.Tag do
  use Ash.Resource,
    otp_app: :ash_storage_demo,
    domain: AshStorageDemo.Tagging,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage]

  postgres do
    table "tags"
    repo AshStorageDemo.Repo
  end

  storage do
    blob_resource(AshStorageDemo.Storage.Blob)
    # PolyAttachment has no belongs_to_resource, so attaching from Tag.icons
    # writes `record_type: "AshStorageDemo.Tagging.Tag", record_id: tag.id`.
    attachment_resource(AshStorageDemo.Storage.PolyAttachment)

    service({AshStorage.Service.S3, Application.compile_env(:ash_storage_demo, :s3)})

    has_many_attached(:icons)
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:name, :taggable_type, :taggable_id]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      public? true
      allow_nil? false
      constraints max_length: 80
    end

    # Lightweight polymorphic association on the tag itself — lets the same
    # Tag flow attach to a Post, Comment, or User by storing the parent's
    # module name + id. Distinct from Storage.PolyAttachment's poly columns,
    # which target Tag.
    attribute :taggable_type, :string, public?: true, allow_nil?: false
    attribute :taggable_id, :uuid, public?: true, allow_nil?: false

    timestamps()
  end

  identities do
    identity :unique_per_target, [:name, :taggable_type, :taggable_id]
  end
end
