defmodule AshStorageDemo.Repo.Migrations.AttachmentsNilifyOnParentDelete do
  @moduledoc """
  Swap the `ON DELETE CASCADE` rules on `storage_attachments.{user,post,
  comment,story}_id` and `storage_sticker_attachments.reaction_id` for
  `ON DELETE SET NULL`.

  `AshStorage.Changes.HandleDependentAttachments` prefetches attachment
  rows in `before_action` and calls `Ash.destroy/2` on them in
  `after_action`. With `ON DELETE CASCADE`, Postgres deletes the rows
  during the parent's own DELETE, and the after-action hook then races
  into `Ash.Error.Changes.StaleRecord` — meaning that destroying a Post
  (or any attachment-host) with attachments was failing entirely.
  Nilifying lets the Ash hook own the cascade, including invoking
  `:purge_blob` triggers and file deletion.
  """
  use Ecto.Migration

  @attachments_fks [
    {:user, "storage_attachments_user_id_fkey", :users},
    {:post, "storage_attachments_post_id_fkey", :posts},
    {:comment, "storage_attachments_comment_id_fkey", :comments},
    {:story, "storage_attachments_story_id_fkey", :stories}
  ]

  def up do
    Enum.each(@attachments_fks, fn {col, name, ref} ->
      drop constraint(:storage_attachments, name)

      alter table(:storage_attachments) do
        modify :"#{col}_id",
               references(ref,
                 column: :id,
                 name: name,
                 type: :uuid,
                 prefix: "public",
                 on_delete: :nilify_all
               )
      end
    end)

    drop constraint(:storage_sticker_attachments, "storage_sticker_attachments_reaction_id_fkey")

    alter table(:storage_sticker_attachments) do
      modify :reaction_id,
             references(:reactions,
               column: :id,
               name: "storage_sticker_attachments_reaction_id_fkey",
               type: :uuid,
               prefix: "public",
               on_delete: :nilify_all
             )
    end
  end

  def down do
    drop constraint(:storage_sticker_attachments, "storage_sticker_attachments_reaction_id_fkey")

    alter table(:storage_sticker_attachments) do
      modify :reaction_id,
             references(:reactions,
               column: :id,
               name: "storage_sticker_attachments_reaction_id_fkey",
               type: :uuid,
               prefix: "public",
               on_delete: :delete_all
             )
    end

    Enum.each(Enum.reverse(@attachments_fks), fn {col, name, ref} ->
      drop constraint(:storage_attachments, name)

      alter table(:storage_attachments) do
        modify :"#{col}_id",
               references(ref,
                 column: :id,
                 name: name,
                 type: :uuid,
                 prefix: "public",
                 on_delete: :delete_all
               )
      end
    end)
  end
end
