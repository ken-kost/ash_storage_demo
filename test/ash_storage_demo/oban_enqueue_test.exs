defmodule AshStorageDemo.ObanEnqueueTest do
  @moduledoc """
  Verifies that `analyze: :oban` / `generate: :oban` paths *enqueue* work
  rather than running inline. We attach a photo to a Post (which declares
  ImageDimensions as `analyze: :oban` and cover_image's feed_size variant
  as `generate: :oban`), then read the Oban-queued jobs without draining
  them.
  """
  use AshStorageDemo.DataCase, async: false
  use Oban.Testing, repo: AshStorageDemo.Repo

  alias AshStorage.Operations
  alias AshStorageDemo.Feed.Post

  setup do
    AshStorage.Service.Test.reset!()

    user = user(email: "alice@example.com")
    {:ok, post} = Ash.create(Post, %{body: "hi"}, actor: user)
    {:ok, user: user, post: post}
  end

  test "attaching a Post.photo flags the blob as pending_analyzers without running inline", %{
    post: post,
    user: user
  } do
    {:ok, %{blob: blob}} =
      Operations.attach(post, :photos, png_bytes(),
        filename: "p.png",
        content_type: "image/png",
        actor: user
      )

    blob = Ash.reload!(blob)

    # ImageDimensions is `analyze: :oban` → blob is flagged pending and
    # `analyzers["AshStorageDemo.Analyzers.ImageDimensions"]["status"]` is
    # "pending" until the cron scheduler drains.
    assert blob.pending_analyzers == true

    assert get_in(blob.analyzers, [
             "Elixir.AshStorageDemo.Analyzers.ImageDimensions",
             "status"
           ]) == "pending"
  end
end
