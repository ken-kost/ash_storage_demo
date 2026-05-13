# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :cinder, default_theme: "modern"
config :ash_oban, pro?: false

config :ash_storage_demo, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [
    default: 10,
    blob_purge_blob: 5,
    blob_run_pending_analyzers: 5,
    blob_run_pending_variants: 5
  ],
  repo: AshStorageDemo.Repo,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"*/5 * * * *", AshStorageDemo.Storage.VolumeUsage.Worker}
     ]}
  ]

config :ash,
  allow_forbidden_field_for_relationships_by_default?: true,
  include_embedded_source_by_default?: false,
  show_keysets_for_all_actions?: false,
  default_page_type: :keyset,
  policies: [no_filter_static_forbidden_reads?: false],
  keep_read_action_loads_when_loading?: false,
  default_actions_require_atomic?: true,
  read_action_after_action_hooks_in_order?: true,
  bulk_actions_default_to_errors?: true,
  transaction_rollback_on_error?: true,
  redact_sensitive_values_in_errors?: true,
  known_types: [AshPostgres.Timestamptz, AshPostgres.TimestamptzUsec]

config :spark,
  formatter: [
    remove_parens?: true,
    "Ash.Resource": [
      section_order: [
        :admin,
        :authentication,
        :token,
        :user_identity,
        :postgres,
        :resource,
        :code_interface,
        :actions,
        :policies,
        :pub_sub,
        :preparations,
        :changes,
        :validations,
        :multitenancy,
        :attributes,
        :relationships,
        :calculations,
        :aggregates,
        :identities
      ]
    ],
    "Ash.Domain": [
      section_order: [:admin, :resources, :policies, :authorization, :domain, :execution]
    ]
  ]

config :ash_storage_demo,
  ecto_repos: [AshStorageDemo.Repo],
  generators: [timestamp_type: :utc_datetime],
  ash_domains: [
    AshStorageDemo.Accounts,
    AshStorageDemo.Storage,
    AshStorageDemo.Feed,
    AshStorageDemo.Messaging,
    AshStorageDemo.Tagging
  ],
  ash_authentication: [return_error_on_invalid_magic_link_token?: true]

# Defaults for the AshStorage S3 service. Compile-time so the resource DSL can
# capture it via Application.compile_env/2. config/runtime.exs re-applies the
# same shape so env-driven prod overrides land in Application.get_env, which
# AshStorage's per-resource info lookup also consults at runtime.
config :ash_storage_demo, :s3,
  bucket: "ash-storage-demo",
  region: "us-east-1",
  access_key_id: "minioadmin",
  secret_access_key: "minioadmin",
  endpoint_url: "http://localhost:19000"

# Configure the endpoint
config :ash_storage_demo, AshStorageDemoWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: AshStorageDemoWeb.ErrorHTML, json: AshStorageDemoWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AshStorageDemo.PubSub,
  live_view: [signing_salt: "SRuSGrNH"]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :ash_storage_demo, AshStorageDemo.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  ash_storage_demo: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  ash_storage_demo: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
