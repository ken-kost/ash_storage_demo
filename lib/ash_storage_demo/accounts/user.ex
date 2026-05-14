defmodule AshStorageDemo.Accounts.User do
  use Ash.Resource,
    otp_app: :ash_storage_demo,
    domain: AshStorageDemo.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication, AshStorage]

  authentication do
    add_ons do
      log_out_everywhere do
        apply_on_password_change? true
      end
    end

    tokens do
      enabled? true
      token_resource AshStorageDemo.Accounts.Token
      signing_secret AshStorageDemo.Secrets
      store_all_tokens? true
      require_token_presence_for_authentication? true
    end

    strategies do
      password :password do
        identity_field :email
      end

      remember_me :remember_me
    end
  end

  postgres do
    table "users"
    repo AshStorageDemo.Repo
  end

  storage do
    blob_resource(AshStorageDemo.Storage.Blob)
    attachment_resource(AshStorageDemo.Storage.Attachment)

    service({AshStorage.Service.S3, Application.compile_env(:ash_storage_demo, :s3)})

    has_one_attached :avatar do
      analyzer(AshStorageDemo.Analyzers.FileInfo)
      analyzer(AshStorageDemo.Analyzers.ImageDimensions)
      analyzer(AshStorageDemo.Analyzers.DominantColor)

      variant(:small, {AshStorageDemo.Variants.Image, width: 64, height: 64, crop: :center},
        generate: :eager
      )

      variant(:medium, {AshStorageDemo.Variants.Image, width: 256, height: 256, crop: :center},
        generate: :eager
      )

      variant(:large, {AshStorageDemo.Variants.Image, width: 1024, height: 1024, crop: :center},
        generate: :eager
      )
    end

    has_one_attached :cover_photo do
      analyzer(AshStorageDemo.Analyzers.FileInfo)
      analyzer(AshStorageDemo.Analyzers.ImageDimensions)
    end
  end

  actions do
    defaults [:read]

    read :get_by_subject do
      description "Get a user by the subject claim in a JWT"
      argument :subject, :string, allow_nil?: false
      get? true
      prepare AshAuthentication.Preparations.FilterBySubject
    end

    read :get_by_email do
      description "Looks up a user by their email"
      get_by :email
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :hashed_password, :string do
      allow_nil? false
      sensitive? true
    end
  end

  identities do
    identity :unique_email, [:email]
  end
end
