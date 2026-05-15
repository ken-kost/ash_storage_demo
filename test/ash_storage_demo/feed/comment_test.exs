defmodule AshStorageDemo.Feed.CommentTest do
  use AshStorageDemo.DataCase, async: false

  alias AshStorageDemo.Feed.Comment

  test "belongs to a post and an author" do
    user = user()
    post = post(user)
    comment = comment(post, user, "wat")
    assert comment.post_id == post.id
    assert comment.author_id == user.id
    assert comment.body == "wat"
  end

  test "destroying a post cascades to its comments (FK delete)" do
    user = user()
    post = post(user)
    comment = comment(post, user)
    :ok = Ash.destroy!(post, authorize?: false)
    assert {:error, _} = Ash.get(Comment, comment.id, authorize?: false)
  end
end
