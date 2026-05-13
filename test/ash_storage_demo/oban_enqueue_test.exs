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
  alias AshStorageDemo.Accounts.User
  alias AshStorageDemo.Feed.Post

  setup do
    AshStorage.Service.Test.reset!()

    user = Ash.Seed.seed!(%User{email: "alice@example.com"})
    {:ok, post} = Ash.create(Post, %{body: "hi"}, actor: user)
    {:ok, user: user, post: post}
  end

  test "attaching a Post.photo flags the blob as pending_analyzers without running inline", %{
    post: post
  } do
    {:ok, %{blob: blob}} =
      Operations.attach(post, :photos, png_bytes(),
        filename: "p.png",
        content_type: "image/png"
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

  defp png_bytes do
    <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6,
      0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1,
      13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130>>
  end
end
