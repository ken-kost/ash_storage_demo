defmodule AshStorageDemo.Feed.ReactionTest do
  use AshStorageDemo.DataCase, async: false

  alias AshStorage.Operations
  alias AshStorageDemo.Feed.Reaction
  alias AshStorageDemo.Storage.StickerAttachment

  test "create with emoji + post" do
    user = user()
    post = post(user)
    reaction = reaction(post, user, "❤️")
    assert reaction.emoji == "❤️"
    assert reaction.post_id == post.id
    assert reaction.author_id == user.id
  end

  test "uses StickerAttachment (single belongs_to_resource)" do
    entries =
      Spark.Dsl.Extension.get_entities(StickerAttachment, [:attachment])

    assert length(entries) == 1
    [%{name: :reaction, resource: Reaction}] = entries
  end

  test "attaching a sticker writes the reaction_id FK" do
    user = user()
    post = post(user)
    r = reaction(post, user)

    {:ok, %{attachment: att}} =
      Operations.attach(r, :sticker, png_bytes(),
        filename: "s.png",
        content_type: "image/png"
      )

    assert att.reaction_id == r.id
    refute Map.has_key?(att, :record_type)
  end
end
