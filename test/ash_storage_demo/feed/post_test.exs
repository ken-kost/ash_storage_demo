defmodule AshStorageDemo.Feed.PostTest do
  use AshStorageDemo.DataCase, async: false

  alias AshStorageDemo.Feed.Post

  describe "create" do
    test "stores body and links the author" do
      user = user()
      post = post(user, "first post")
      assert post.body == "first post"
      assert post.author_id == user.id
    end

    test "requires body" do
      user = user()
      assert {:error, _} = Ash.create(Post, %{body: nil}, actor: user, authorize?: false)
    end

    test "rejects body over 1000 chars" do
      user = user()

      assert {:error, _} =
               Ash.create(Post, %{body: String.duplicate("x", 1001)},
                 actor: user,
                 authorize?: false
               )
    end
  end

  describe "loads attachment relationships" do
    test "cover_image / photos / videos / documents start empty" do
      user = user()
      post = post(user)
      loaded = Ash.load!(post, [:cover_image, :photos, :videos, :documents], authorize?: false)
      assert is_nil(loaded.cover_image)
      assert loaded.photos == []
      assert loaded.videos == []
      assert loaded.documents == []
    end

    test "*_url calculations resolve to nil for empty attachments" do
      user = user()
      post = post(user)
      loaded = Ash.load!(post, [:cover_image_url], authorize?: false)
      assert is_nil(loaded.cover_image_url)
    end
  end

  describe "EXIF write_attributes target columns" do
    test "taken_at / camera / gps_lat / gps_lng exist and default to nil" do
      user = user()
      post = post(user)
      assert is_nil(post.taken_at)
      assert is_nil(post.camera)
      assert is_nil(post.gps_lat)
      assert is_nil(post.gps_lng)
    end
  end
end
