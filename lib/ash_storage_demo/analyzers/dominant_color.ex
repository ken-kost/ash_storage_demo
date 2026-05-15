defmodule AshStorageDemo.Analyzers.DominantColor do
  @moduledoc """
  Extracts a single dominant colour from an image as a hex string (e.g.
  "#a4c2f4"). Used on `User.avatar` to drive avatar background tinting.

  Backed by `Image.dominant_color/2`, which uses libvips under the hood
  via vix.
  """
  @behaviour AshStorage.Analyzer

  @image_mimes ~w(image/png image/jpeg image/jpg image/webp)

  @impl true
  def accept?(content_type), do: content_type in @image_mimes

  @impl true
  def analyze(path, _opts) do
    with {:ok, image} <- Image.open(path),
         {:ok, [r, g, b | _]} <- Image.dominant_color(image) do
      hex = "#" <> Enum.map_join([r, g, b], &Integer.to_string(&1, 16))
      {:ok, %{"dominant_color" => String.downcase(hex)}}
    else
      {:error, _} = err -> err
      other -> {:error, other}
    end
  end
end
