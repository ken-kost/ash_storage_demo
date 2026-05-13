defmodule AshStorageDemo.Repo do
  use Ecto.Repo,
    otp_app: :ash_storage_demo,
    adapter: Ecto.Adapters.Postgres
end
