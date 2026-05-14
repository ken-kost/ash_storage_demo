import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/ash_storage_demo start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :ash_storage_demo, AshStorageDemoWeb.Endpoint, server: true
end

config :ash_storage_demo, AshStorageDemoWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

# Default S3-backed config for AshStorage services. In dev this points at the
# local MinIO container from docker-compose.yml; production overrides the env
# vars to point at a real S3 bucket.
config :ash_storage_demo, :s3,
  bucket: System.get_env("S3_BUCKET", "ash-storage-demo"),
  region: System.get_env("S3_REGION", "us-east-1"),
  access_key_id: System.get_env("S3_KEY", "minioadmin"),
  secret_access_key: System.get_env("S3_SECRET", "minioadmin"),
  endpoint_url: System.get_env("S3_ENDPOINT", "http://localhost:19000")

if config_env() == :prod do
  # Per-host Application env overrides for the AshStorage resources. ash_storage's
  # Info.attachment_service/2 (see deps/ash_storage/lib/ash_storage/info.ex) checks
  # `Application.fetch_env(otp_app, resource)` before consulting the DSL-baked
  # `service({...})` tuple, so this is the supported way to swap S3 creds at
  # runtime without rebuilding the release. The resource DSLs still capture
  # `Application.compile_env(:ash_storage_demo, :s3)` at build time (with the dev
  # defaults from config.exs); these overrides win for every host listed below.
  prod_s3_opts = [
    bucket: System.fetch_env!("S3_BUCKET"),
    region: System.get_env("S3_REGION", "us-east-1"),
    access_key_id: System.fetch_env!("S3_KEY"),
    secret_access_key: System.fetch_env!("S3_SECRET"),
    endpoint_url: System.fetch_env!("S3_ENDPOINT")
  ]

  prod_s3_storage = [storage: [service: {AshStorage.Service.S3, prod_s3_opts}]]

  config :ash_storage_demo, AshStorageDemo.Accounts.User, prod_s3_storage
  config :ash_storage_demo, AshStorageDemo.Feed.Reaction, prod_s3_storage
  config :ash_storage_demo, AshStorageDemo.Feed.Story, prod_s3_storage
  config :ash_storage_demo, AshStorageDemo.Messaging.Message, prod_s3_storage
  config :ash_storage_demo, AshStorageDemo.Tagging.Tag, prod_s3_storage

  # Post needs per-attachment overrides for the two Disk-using attachments:
  # `cover_image` (S3 primary + Disk mirror) and `documents` (Disk only). Both
  # write under DISK_STORAGE_ROOT so a Fly volume mounted at e.g. /data/storage
  # keeps the bytes across redeploys instead of landing on the container's
  # ephemeral filesystem. `photos` / `videos` inherit the resource-level S3
  # override above.
  disk_root = System.get_env("DISK_STORAGE_ROOT", "priv/storage")

  cover_images_mirror_disk =
    {AshStorage.Service.Disk,
     root: Path.join(disk_root, "cover_images_mirror"), base_url: "/files/cover_images_mirror"}

  documents_disk =
    {AshStorage.Service.Disk,
     root: Path.join(disk_root, "documents"), base_url: "/files/documents"}

  config :ash_storage_demo, AshStorageDemo.Feed.Post,
    storage: [
      service: {AshStorage.Service.S3, prod_s3_opts},
      has_one_attached: [
        cover_image: [
          service: {AshStorage.Service.S3, prod_s3_opts ++ [mirrors: [cover_images_mirror_disk]]}
        ]
      ],
      has_many_attached: [
        documents: [service: documents_disk]
      ]
    ]

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :ash_storage_demo, AshStorageDemo.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :ash_storage_demo, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :ash_storage_demo, AshStorageDemoWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  config :ash_storage_demo,
    token_signing_secret:
      System.get_env("TOKEN_SIGNING_SECRET") ||
        raise("Missing environment variable `TOKEN_SIGNING_SECRET`!")

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :ash_storage_demo, AshStorageDemoWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :ash_storage_demo, AshStorageDemoWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :ash_storage_demo, AshStorageDemo.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
