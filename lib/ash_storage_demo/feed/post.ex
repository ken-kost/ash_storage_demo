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

    has_one_attached :cover_image do
      # Mirror S3 (primary) → Disk (secondary). Reads consult S3 first and fall
      # through to Disk on :not_found; writes fan out to both. Demonstrates
      # the upstream `AshStorage.Service.Mirror` roadmap item.
      service(
        {AshStorage.Service.S3,
         Application.compile_env(:ash_storage_demo, :s3) ++
           [
             mirrors: [
               {AshStorage.Service.Disk,
                root: "priv/storage/cover_images_mirror", base_url: "/files/cover_images_mirror"}
             ]
           ]}
      )

      analyzer(AshStorageDemo.Analyzers.FileInfo)
      analyzer(AshStorageDemo.Analyzers.ImageDimensions)

      variant(:feed_size, {AshStorageDemo.Variants.Image, width: 1200}, generate: :oban)
    end

    has_many_attached :photos do
      analyzer(AshStorageDemo.Analyzers.FileInfo)
      analyzer(AshStorageDemo.Analyzers.ImageDimensions, analyze: :oban)

      analyzer(AshStorageDemo.Analyzers.Exif,
        write_attributes: [
          taken_at: :taken_at,
          camera: :camera,
          gps_lat: :gps_lat,
          gps_lng: :gps_lng
        ]
      )

      # generate: :on_demand is the default — first URL load triggers it.
      variant(:thumb, {AshStorageDemo.Variants.Image, width: 300})
    end

    has_many_attached :videos do
      analyzer(AshStorageDemo.Analyzers.FileInfo)

      variant(:poster, {AshStorageDemo.Variants.VideoPoster, at: 1.0})
    end

    has_many_attached :documents do
      service(
        {AshStorage.Service.Disk, root: "priv/storage/documents", base_url: "/files/documents"}
      )

      dependent(:detach)

      analyzer(AshStorageDemo.Analyzers.FileInfo)

      variant(:preview, {AshStorageDemo.Variants.PdfPreview, width: 400})
    end
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

    # Populated by the Exif analyzer's `write_attributes` when a photo is
    # attached. These are best-effort and stay nil for photos without EXIF.
    attribute :taken_at, :string, public?: true
    attribute :camera, :string, public?: true
    attribute :gps_lat, :float, public?: true
    attribute :gps_lng, :float, public?: true

    timestamps()
  end

  relationships do
    belongs_to :author, AshStorageDemo.Accounts.User do
      allow_nil? true
      public? true
    end
  end
end
