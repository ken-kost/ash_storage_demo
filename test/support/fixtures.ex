defmodule AshStorageDemo.Fixtures do
  @moduledoc """
  Small helpers for creating fixture records in tests. Each helper goes
  through Ash with `authorize?: false` so tests don't have to wire actors
  for every step.
  """

  alias AshStorageDemo.Accounts.User
  alias AshStorageDemo.Feed.{Comment, Post, Reaction, Story}
  alias AshStorageDemo.Messaging.Message
  alias AshStorageDemo.Tagging.Tag

  # 1x1 transparent PNG used as a stand-in image payload across the suite.
  @png <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8,
         6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5,
         0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130>>

  def png_bytes, do: @png

  def user(opts \\ []) do
    email = Keyword.get(opts, :email, unique_email())
    hashed_password = Bcrypt.hash_pwd_salt("password123!")
    Ash.Seed.seed!(%User{email: email, hashed_password: hashed_password})
  end

  def unique_email, do: "u-#{System.unique_integer([:positive])}@example.test"

  def post(user, body \\ "hello") do
    {:ok, post} = Ash.create(Post, %{body: body}, actor: user, authorize?: false)
    post
  end

  def comment(post, user, body \\ "nice") do
    {:ok, comment} =
      Ash.create(Comment, %{body: body, post_id: post.id}, actor: user, authorize?: false)

    comment
  end

  def story(user) do
    {:ok, story} = Ash.create(Story, %{}, actor: user, authorize?: false)
    story
  end

  def message(sender, recipient, body \\ "hi") do
    {:ok, msg} =
      Ash.create(Message, %{body: body, recipient_id: recipient.id},
        actor: sender,
        authorize?: false
      )

    msg
  end

  def reaction(post, user, emoji \\ "🔥") do
    {:ok, r} =
      Ash.create(Reaction, %{emoji: emoji, post_id: post.id}, actor: user, authorize?: false)

    r
  end

  def tag(post, name \\ "demo") do
    {:ok, tag} =
      Ash.create(Tag, %{
        name: name,
        taggable_type: to_string(Post),
        taggable_id: post.id
      })

    tag
  end
end
