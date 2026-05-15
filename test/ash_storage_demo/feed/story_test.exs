defmodule AshStorageDemo.Feed.StoryTest do
  use AshStorageDemo.DataCase, async: false

  alias AshStorageDemo.Feed.Story

  test "sets expires_at ~24h ahead on create" do
    user = user()
    story = story(user)
    assert %DateTime{} = story.expires_at
    delta = DateTime.diff(story.expires_at, DateTime.utc_now(), :hour)
    assert delta in 23..24
  end

  test "links to the author" do
    user = user()
    story = story(user)
    assert story.author_id == user.id
  end

  test "Storage.Attachment has a :story belongs_to_resource" do
    entries =
      Spark.Dsl.Extension.get_entities(AshStorageDemo.Storage.Attachment, [:attachment])

    assert Enum.any?(entries, &match?(%{name: :story, resource: Story}, &1))
  end
end
