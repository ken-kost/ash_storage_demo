defmodule AshStorageDemo.Feed do
  use Ash.Domain, otp_app: :ash_storage_demo, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource AshStorageDemo.Feed.Post
    resource AshStorageDemo.Feed.Comment
    resource AshStorageDemo.Feed.Story
    resource AshStorageDemo.Feed.Reaction
  end
end
