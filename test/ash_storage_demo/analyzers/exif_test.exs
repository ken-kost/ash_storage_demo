defmodule AshStorageDemo.Analyzers.ExifTest do
  use ExUnit.Case, async: true

  alias AshStorageDemo.Analyzers.Exif

  test "accept?/1 is JPEG-only" do
    assert Exif.accept?("image/jpeg")
    assert Exif.accept?("image/jpg")
    refute Exif.accept?("image/png")
    refute Exif.accept?("application/pdf")
  end

  test "analyze/2 returns {:ok, %{}} when the JPEG has no EXIF block" do
    # A 2-byte stub that's not a valid JPEG either, but exexif's parser falls
    # over cleanly and we treat that as "no EXIF available", not an error.
    path = Path.join(System.tmp_dir!(), "exif_empty_#{System.unique_integer([:positive])}.jpg")
    File.write!(path, <<0xFF, 0xD8>>)

    assert {:ok, %{}} == Exif.analyze(path, [])
  end
end
