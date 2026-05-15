defmodule AshStorageDemo.Analyzers.ImageDimensions do
  @moduledoc """
  Extracts width/height for common image formats using ex_image_info, which
  reads only the file header so it's cheap and pure-Elixir.

  Used eagerly on User.avatar / Post.cover_image, and via `analyze: :oban`
  on Post.photos to demonstrate the background-analysis path.
  """
  @behaviour AshStorage.Analyzer

  @image_mimes ~w(image/png image/jpeg image/jpg image/webp image/gif)

  @impl true
  def accept?(content_type), do: content_type in @image_mimes

  @impl true
  def analyze(path, _opts) do
    data = File.read!(path)

    case ExImageInfo.info(data) do
      {_mime, w, h, _variant} ->
        {:ok, %{"width" => w, "height" => h}}

      _ ->
        {:error, :unknown_format}
    end
  end
end
