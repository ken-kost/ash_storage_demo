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

  defp write(image, path, nil), do: Image.write(image, path)

  defp write(image, path, format) when format in [:jpg, :png, :webp] do
    Image.write(image, path, suffix: ".#{format}")
  end

  defp content_type_for(:jpg, _), do: "image/jpeg"
  defp content_type_for(:png, _), do: "image/png"
  defp content_type_for(:webp, _), do: "image/webp"

  defp content_type_for(nil, source_path) do
    case Path.extname(source_path) do
      ".png" -> "image/png"
      ".webp" -> "image/webp"
      _ -> "image/jpeg"
    end
  end
end
