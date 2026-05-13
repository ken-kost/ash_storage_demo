defmodule AshStorageDemo.Storage.StickerAttachment do
  @moduledoc """
  Single-parent attachment resource backing `Feed.Reaction.sticker`.

  Separate from `Storage.Attachment` to demonstrate the simpler
  single-`belongs_to_resource` flavour of `AshStorage.AttachmentResource`.
  """
  use Ash.Resource,
    domain: AshStorageDemo.Storage,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage.AttachmentResource]

  postgres do
    table "storage_sticker_attachments"
    repo AshStorageDemo.Repo

    references do
      reference :reaction, on_delete: :delete
    end
  end

  attachment do
    blob_resource(AshStorageDemo.Storage.Blob)
    belongs_to_resource(:reaction, AshStorageDemo.Feed.Reaction)
  end

  attributes do
    uuid_primary_key :id
  end
end
