defmodule AshStorageDemo.Storage do
  use Ash.Domain, otp_app: :ash_storage_demo, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource AshStorageDemo.Storage.Blob
    resource AshStorageDemo.Storage.Attachment
  end
end
