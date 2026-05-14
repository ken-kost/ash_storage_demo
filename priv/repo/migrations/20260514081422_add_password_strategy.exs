defmodule AshStorageDemo.Repo.Migrations.AddPasswordStrategy do
  @moduledoc """
  Adds `hashed_password` to `users` for the AshAuthentication password
  strategy. All other tables were already created by the earlier `_dev`
  migrations; only this column is genuinely new.
  """

  use Ecto.Migration

  def up do
    alter table(:users) do
      add :hashed_password, :text, null: false
    end
  end

  def down do
    alter table(:users) do
      remove :hashed_password
    end
  end
end
