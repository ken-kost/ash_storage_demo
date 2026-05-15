defmodule AshStorageDemo.Variants.PdfPreview do
  @moduledoc """
  Renders the first page of a PDF as a PNG preview using libvips (which
  needs to be built with Poppler/PDFium). On systems where libvips lacks
  PDF support, `Image.open/2` will return `{:error, _}` and this variant
  will simply fail rather than crash the host.
  """
  @behaviour AshStorage.Variant

  @impl true
  def accept?("application/pdf"), do: true
  def accept?(_), do: false

  @impl true
  def transform(source_path, dest_path, opts) do
    width = Keyword.get(opts, :width, 400)

    with {:ok, image} <- Image.open(source_path, page: 0),
         {:ok, resized} <- Image.thumbnail(image, "#{width}"),
         {:ok, _} <- Image.write(resized, dest_path, suffix: ".png") do
      {:ok, %{content_type: "image/png", filename: "preview.png"}}
    end
  end
end
