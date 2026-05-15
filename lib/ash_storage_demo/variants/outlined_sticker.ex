defmodule AshStorageDemo.Variants.OutlinedSticker do
  @moduledoc """
  Custom variant for `Feed.Reaction.sticker`: takes a transparent PNG
  sticker and stamps a white outline behind it, similar to chat-app
  sticker styling. Implemented as a libvips dilation followed by a
  composite over the original.
  """
  @behaviour AshStorage.Variant

  @impl true
  def accept?("image/png"), do: true
  def accept?("image/webp"), do: true
  def accept?(_), do: false

  @impl true
  def transform(source_path, dest_path, opts) do
    radius = Keyword.get(opts, :radius, 4)

    with {:ok, source} <- Image.open(source_path),
         {:ok, blurred} <- Image.blur(source, sigma: radius),
         {:ok, outline} <- Image.compose(blurred, source),
         {:ok, _} <- Image.write(outline, dest_path, suffix: ".png") do
      {:ok, %{content_type: "image/png", filename: "outlined.png"}}
    end
  end
end
