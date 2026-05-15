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
      # All parent refs use `:nilify` (not `:delete`) so AshStorage's
      # `HandleDependentAttachments` `after_action` hook can still find the
      # rows and call `Ash.destroy(att, ...)` on them. With `:delete`,
      # Postgres cascades during the parent's DELETE and the hook then
      # races into `Ash.Error.Changes.StaleRecord`.
      reference :user, on_delete: :nilify
      reference :post, on_delete: :nilify
      reference :comment, on_delete: :nilify
      reference :story, on_delete: :nilify
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
