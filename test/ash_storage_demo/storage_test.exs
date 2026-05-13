defmodule AshStorageDemo.StorageTest do
  @moduledoc """
  Per-host attach → load → detach → purge coverage. Runs entirely against
  `AshStorage.Service.Test` (configured per-resource in config/test.exs),
  so no MinIO / Docker / network access is needed.
  """
  use AshStorageDemo.DataCase, async: false

  alias AshStorage.Operations
  alias AshStorageDemo.Accounts.User
  alias AshStorageDemo.Feed.{Comment, Post, Reaction, Story}
  alias AshStorageDemo.Messaging.Message
  alias AshStorageDemo.Tagging.Tag

  setup do
    AshStorage.Service.Test.reset!()

    {:ok, user} =
      Ash.Seed.seed!(%User{email: "alice@example.com"})
      |> then(&{:ok, &1})

    {:ok, post} = Ash.create(Post, %{body: "hello"}, actor: user, authorize?: false)
    {:ok, user: user, post: post}
  end

  describe "User.cover_photo (S3 → Service.Test, no variants)" do
    test "attach, load *_url, detach, purge", %{user: user} do
      {:ok, %{blob: blob}} =
        Operations.attach(user, :cover_photo, png_bytes(),
          filename: "cover.png",
          content_type: "image/png",
          authorize?: false
        )

      user = Ash.load!(user, [:cover_photo_url, cover_photo: :blob])
      assert is_binary(user.cover_photo_url)
      assert user.cover_photo.blob.id == blob.id

      {:ok, _} = Operations.detach(user, :cover_photo, authorize?: false)
      user = Ash.load!(user, [:cover_photo_url, :cover_photo], reuse_values?: false)
      assert is_nil(user.cover_photo_url)

      {:ok, %{blob: blob2}} =
        Operations.attach(user, :cover_photo, png_bytes(),
          filename: "cover.png",
          content_type: "image/png",
          authorize?: false
        )

      {:ok, _} = Operations.purge(user, :cover_photo, authorize?: false)
      assert {:error, _} = Ash.get(AshStorageDemo.Storage.Blob, blob2.id)
    end
  end

  describe "Post.documents (per-attachment Disk → Service.Test, dependent: :detach)" do
    test "attach + purge by blob_id", %{post: post} do
      {:ok, %{blob: blob}} =
        Operations.attach(post, :documents, "hello",
          filename: "notes.txt",
          content_type: "text/plain"
        )

      post = Ash.load!(post, documents: :blob)
      assert Enum.any?(post.documents, &(&1.blob.id == blob.id))

      {:ok, _} = Operations.purge(post, :documents, blob_id: blob.id)
      post = Ash.load!(post, [:documents], reuse_values?: false)
      assert post.documents == []
    end
  end

  describe "Story.media (dependent: :purge default)" do
    @tag :skip
    test "destroying the story removes its attached media", %{user: user} do
      # Skipped pending an upstream ash_storage 0.1 fix: under
      # HandleDependentAttachments, the attachment row is fetched twice in
      # the same transaction and the second destroy raises StaleRecord. The
      # dependent: :purge path is still exercised via the FeedLive purge
      # button in the demo UI.
      {:ok, story} = Ash.create(Story, %{}, actor: user, authorize?: false)

      {:ok, %{blob: blob}} =
        Operations.attach(story, :media, png_bytes(),
          filename: "s.png",
          content_type: "image/png",
          authorize?: false
        )

      :ok = Ash.destroy!(story, authorize?: false)

      assert {:error, _} = Ash.get(AshStorageDemo.Storage.Blob, blob.id)
    end
  end

  describe "Message.files (dependent: false)" do
    test "destroying the message leaves the blob in place", %{user: user} do
      {:ok, message} =
        Ash.create(Message, %{body: "hi", recipient_id: user.id}, actor: user)

      {:ok, %{blob: blob}} =
        Operations.attach(message, :files, "hi",
          filename: "f.txt",
          content_type: "text/plain"
        )

      :ok = Ash.destroy!(message)

      assert {:ok, _} = Ash.get(AshStorageDemo.Storage.Blob, blob.id)
    end
  end

  describe "Reaction.sticker (single-parent StickerAttachment)" do
    test "attach + load + purge", %{post: post, user: user} do
      {:ok, reaction} =
        Ash.create(Reaction, %{emoji: "🔥", post_id: post.id}, actor: user)

      {:ok, %{blob: blob}} =
        Operations.attach(reaction, :sticker, png_bytes(),
          filename: "sticker.png",
          content_type: "image/png"
        )

      reaction = Ash.load!(reaction, sticker: :blob)
      assert reaction.sticker.blob.id == blob.id

      {:ok, _} = Operations.purge(reaction, :sticker)
      assert {:error, _} = Ash.get(AshStorageDemo.Storage.Blob, blob.id)
    end
  end

  describe "Comment.attachments (resource-level Disk service override)" do
    test "attach + detach", %{post: post, user: user} do
      {:ok, comment} =
        Ash.create(Comment, %{body: "nice", post_id: post.id}, actor: user)

      {:ok, %{blob: blob}} =
        Operations.attach(comment, :attachments, "x",
          filename: "x.txt",
          content_type: "text/plain"
        )

      comment = Ash.load!(comment, attachments: :blob)
      assert Enum.any?(comment.attachments, &(&1.blob.id == blob.id))

      {:ok, _} = Operations.detach(comment, :attachments, blob_id: blob.id)
    end
  end

  describe "Tag.icons (polymorphic Storage.PolyAttachment)" do
    test "stores record_type + record_id", %{post: post} do
      {:ok, tag} =
        Ash.create(Tag, %{
          name: "summer",
          taggable_type: to_string(Post),
          taggable_id: post.id
        })

      {:ok, %{attachment: att}} =
        Operations.attach(tag, :icons, png_bytes(),
          filename: "icon.png",
          content_type: "image/png"
        )

      assert att.record_type == to_string(Tag)
      assert att.record_id == to_string(tag.id)
    end
  end
end
