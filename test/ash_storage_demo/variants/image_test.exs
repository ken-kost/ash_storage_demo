defmodule AshStorageDemo.Variants.ImageTest do
  # AshStorage's variant pipeline hands the variant module a *temp file path*
  # whose basename has no extension. `Image.write/3` from elixir-image
  # determines the saver from the path's extension and silently ignores any
  # `suffix:` option for file destinations, so a naive `Image.write(image,
  # path, suffix: ".jpg")` against an extension-less path bombs with
  # `Failed to find save` from libvips. This test guards against regression
  # by exercising the real libvips path against an extension-less destination.
  use ExUnit.Case, async: true

  alias AshStorageDemo.Variants.Image, as: Variant

  # 1×1 red PNG (69 bytes). Smallest legal PNG we can inline so the test
  # has no fixture file dependency.
  @png <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8,
         2, 0, 0, 0, 144, 119, 83, 222, 0, 0, 0, 12, 73, 68, 65, 84, 8, 153, 99, 248, 207, 192, 0,
         0, 0, 3, 0, 1, 94, 242, 178, 213, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130>>

  setup do
    src = Path.join(System.tmp_dir!(), "variant-src-#{System.unique_integer([:positive])}.png")
    dst = Path.join(System.tmp_dir!(), "variant-dst-#{System.unique_integer([:positive])}")
    File.write!(src, @png)
    on_exit(fn -> Enum.each([src, dst], &File.rm/1) end)
    {:ok, src: src, dst: dst}
  end

  test "writes to an extension-less destination path", %{src: src, dst: dst} do
    assert {:ok, %{content_type: "image/jpeg"}} =
             Variant.transform(src, dst, width: 64, height: 64, crop: :center)

    assert <<0xFF, 0xD8, 0xFF, _rest::binary>> = File.read!(dst)
  end

  test "honours explicit :png format on an extension-less path", %{src: src, dst: dst} do
    assert {:ok, %{content_type: "image/png"}} =
             Variant.transform(src, dst, width: 64, format: :png)

    assert <<137, 80, 78, 71, _rest::binary>> = File.read!(dst)
  end

  test "honours explicit :webp format on an extension-less path", %{src: src, dst: dst} do
    assert {:ok, %{content_type: "image/webp"}} =
             Variant.transform(src, dst, width: 64, format: :webp)

    # WebP files begin with "RIFF....WEBP".
    assert <<"RIFF", _size::32, "WEBP", _rest::binary>> = File.read!(dst)
  end
end
