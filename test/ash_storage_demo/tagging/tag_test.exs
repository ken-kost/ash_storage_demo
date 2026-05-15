defmodule AshStorageDemo.Tagging.TagTest do
  use AshStorageDemo.DataCase, async: false

  alias AshStorage.Operations
  alias AshStorageDemo.Storage.PolyAttachment
  alias AshStorageDemo.Tagging.Tag

  test "create with name + taggable" do
    user = user()
    post = post(user)
    tag = tag(post, "summer")
    assert tag.name == "summer"
    assert tag.taggable_type == to_string(AshStorageDemo.Feed.Post)
    assert tag.taggable_id == post.id
  end

  test "identity rejects duplicate (name, taggable_type, taggable_id)" do
    user = user()
    post = post(user)
    _ = tag(post, "dup")

    assert {:error, _} =
             Ash.create(Tag, %{
               name: "dup",
               taggable_type: to_string(AshStorageDemo.Feed.Post),
               taggable_id: post.id
             })
  end

  test "attaching an icon writes record_type + record_id (polymorphic)" do
    user = user()
    post = post(user)
    tag = tag(post)

    {:ok, %{attachment: att}} =
      Operations.attach(tag, :icons, png_bytes(),
        filename: "i.png",
        content_type: "image/png"
      )

    assert att.record_type == to_string(Tag)
    assert att.record_id == to_string(tag.id)
  end

  test "PolyAttachment has no belongs_to_resource entries" do
    entries =
      Spark.Dsl.Extension.get_entities(PolyAttachment, [:attachment])

    assert entries == []
  end
end
