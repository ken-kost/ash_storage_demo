defmodule AshStorageDemo.Storage.Attachment do
  @moduledoc """
  Multi-parent FK attachment resource shared by every host in the demo
  except `Feed.Reaction` (which uses `Storage.StickerAttachment` to show
  the single-parent flavour) and Phase 6's `Tagging.Tag` (which uses
  `Storage.PolyAttachment` to show the polymorphic flavour).
  """
  use Ash.Resource,
    domain: AshStorageDemo.Storage,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage.AttachmentResource]

  postgres do
    table "storage_attachments"
    repo AshStorageDemo.Repo

    references do
      reference :user, on_delete: :delete
      reference :post, on_delete: :delete
      reference :comment, on_delete: :delete
      reference :story, on_delete: :delete
      # message intentionally not :delete — `Message.files` declares
      # `dependent: false` so attachments outlive the message.
      reference :message, on_delete: :nilify
    end
  end

  attachment do
    blob_resource(AshStorageDemo.Storage.Blob)
    belongs_to_resource(:user, AshStorageDemo.Accounts.User)
    belongs_to_resource(:post, AshStorageDemo.Feed.Post)
    belongs_to_resource(:comment, AshStorageDemo.Feed.Comment)
    belongs_to_resource(:story, AshStorageDemo.Feed.Story)
    belongs_to_resource(:message, AshStorageDemo.Messaging.Message)
  end

  attributes do
    uuid_primary_key :id
  end
end
