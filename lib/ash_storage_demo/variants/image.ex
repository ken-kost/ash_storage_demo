defmodule AshStorageDemo.Variants.Image do
  @moduledoc """
  Image variant powered by `Image` / `vix` (libvips). Accepts standard
  raster formats and produces a resized copy.

  Opts:
    * `:width` — output width (required when only one dimension is given)
    * `:height` — output height
    * `:crop` — `:center` | `:none` (defaults to `:none`, preserves aspect)
    * `:format` — `:jpg` | `:png` | `:webp` (defaults to source content type)
  """
  @behaviour AshStorage.Variant

  @image_mimes ~w(image/png image/jpeg image/jpg image/webp image/gif)

  @impl true
  def accept?(content_type), do: content_type in @image_mimes

  @impl true
  def transform(source_path, dest_path, opts) do
    width = Keyword.get(opts, :width)
    height = Keyword.get(opts, :height)
    crop = Keyword.get(opts, :crop, :none)
    format = Keyword.get(opts, :format)

    with {:ok, image} <- Image.open(source_path),
         {:ok, resized} <- resize(image, width, height, crop),
         {:ok, _} <- write(resized, dest_path, format) do
      {:ok, %{content_type: content_type_for(format, source_path)}}
    end
  end

  defp resize(image, width, height, :center) when is_integer(width) and is_integer(height) do
    Image.thumbnail(image, "#{width}x#{height}", crop: :center)
  end

  defp resize(image, width, nil, _crop) when is_integer(width) do
    Image.thumbnail(image, "#{width}")
  end

  defp resize(image, nil, height, _crop) when is_integer(height) do
    Image.thumbnail(image, "x#{height}")
  end

  defp resize(image, width, height, _crop) when is_integer(width) and is_integer(height) do
    Image.thumbnail(image, "#{width}x#{height}")
  end

  defp write(image, path, nil), do: write(image, path, :jpg)

  # `Image.write(image, path, suffix: ".xxx")` ignores the suffix for file-path
  # destinations and derives the format from the path's extension. AshStorage's
  # variant pipeline hands us extension-less temp paths, so the saver lookup
  # fails with "Failed to find save". Write to a buffer (where suffix is
  # honoured) and dump the bytes to the path ourselves.
  defp write(image, path, format) when format in [:jpg, :png, :webp] do
    with {:ok, buffer} <- Image.write(image, :memory, suffix: ".#{format}"),
         :ok <- File.write(path, buffer) do
      {:ok, image}
    end
  end

  # Match `write/3`'s default-to-JPEG behaviour. Earlier this inferred a mime
  # from the source extension, which mislabelled variants (`write/3` always
  # re-encodes to JPEG when no `:format` is given, regardless of source).
  defp content_type_for(:jpg, _), do: "image/jpeg"
  defp content_type_for(:png, _), do: "image/png"
  defp content_type_for(:webp, _), do: "image/webp"
  defp content_type_for(nil, _), do: "image/jpeg"
end
