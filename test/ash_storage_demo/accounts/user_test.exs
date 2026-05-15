defmodule AshStorageDemo.Accounts.UserTest do
  use AshStorageDemo.DataCase, async: false

  alias AshStorageDemo.Accounts.User

  describe "schema" do
    test "stores email and is queryable" do
      user = user(email: "schema@example.test")
      assert {:ok, fetched} = Ash.get(User, user.id, authorize?: false)
      assert to_string(fetched.email) == "schema@example.test"
    end

    test "AshStorage extension exposes avatar / cover_photo relationships" do
      user = user()
      loaded = Ash.load!(user, [:avatar, :cover_photo], authorize?: false)
      assert is_nil(loaded.avatar)
      assert is_nil(loaded.cover_photo)
    end

    test "avatar_url / cover_photo_url calculations default to nil" do
      user = user()
      loaded = Ash.load!(user, [:avatar_url, :cover_photo_url], authorize?: false)
      assert is_nil(loaded.avatar_url)
      assert is_nil(loaded.cover_photo_url)
    end
  end
end
