defmodule AshStorageDemo.Analyzers.ImageDimensionsTest do
  use ExUnit.Case, async: true

  alias AshStorageDemo.Analyzers.ImageDimensions
  alias AshStorageDemo.Fixtures

  test "accept?/1 covers common raster types and rejects others" do
    assert ImageDimensions.accept?("image/png")
    assert ImageDimensions.accept?("image/jpeg")
    assert ImageDimensions.accept?("image/webp")
    refute ImageDimensions.accept?("application/pdf")
    refute ImageDimensions.accept?("text/plain")
  end

  test "analyze/2 extracts width and height from a PNG" do
    path = write_temp(Fixtures.png_bytes())
    assert {:ok, %{"width" => 1, "height" => 1}} = ImageDimensions.analyze(path, [])
  end

  test "analyze/2 returns :error for non-image bytes" do
    path = write_temp("not an image")
    assert {:error, :unknown_format} = ImageDimensions.analyze(path, [])
  end

  defp write_temp(bytes) do
    name = "image_dim_test_#{System.unique_integer([:positive])}"
    path = Path.join(System.tmp_dir!(), name)
    File.write!(path, bytes)
    path
  end
end
