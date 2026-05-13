defmodule AshStorageDemo.Accounts do
  use Ash.Domain, otp_app: :ash_storage_demo, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource AshStorageDemo.Accounts.Token
    resource AshStorageDemo.Accounts.User
  end
end
