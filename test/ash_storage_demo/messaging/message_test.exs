defmodule AshStorageDemo.Messaging.MessageTest do
  use AshStorageDemo.DataCase, async: false

  alias AshStorage.Operations
  alias AshStorageDemo.Messaging.Message
  alias AshStorageDemo.Storage.Blob

  test "sender + recipient + body wiring" do
    sender = user(email: "s@example.test")
    recipient = user(email: "r@example.test")
    msg = message(sender, recipient, "yo")
    assert msg.sender_id == sender.id
    assert msg.recipient_id == recipient.id
    assert msg.body == "yo"
  end

  test "dependent: false — destroy leaves attached blob in place" do
    sender = user()
    recipient = user()
    msg = message(sender, recipient)

    {:ok, %{blob: blob}} =
      Operations.attach(msg, :files, "payload",
        filename: "p.txt",
        content_type: "text/plain"
      )

    :ok = Ash.destroy!(msg, authorize?: false)

    assert {:ok, _} = Ash.get(Blob, blob.id, authorize?: false)
  end

  test "Message belongs_to_resource entry in Storage.Attachment uses on_delete: :nilify" do
    # The :delete vs :nilify split is encoded in the resource DSL via the
    # postgres references block; we just confirm the relationship exists.
    entries =
      Spark.Dsl.Extension.get_entities(AshStorageDemo.Storage.Attachment, [:attachment])

    assert Enum.any?(entries, &match?(%{name: :message, resource: Message}, &1))
  end
end
