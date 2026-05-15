defmodule AshStorageDemo.Analyzers.FileInfoTest do
  use ExUnit.Case, async: true

  alias AshStorageDemo.Analyzers.FileInfo
  alias AshStorageDemo.Fixtures

  test "accept?/1 returns true for any content type (it's the universal analyzer)" do
    assert FileInfo.accept?("image/png")
    assert FileInfo.accept?("application/pdf")
    assert FileInfo.accept?("text/plain")
    assert FileInfo.accept?("")
  end

  test "analyze/2 records byte_size + md5 for any payload" do
    path = write_temp(Fixtures.png_bytes())

    assert {:ok, %{"byte_size" => size, "md5" => md5}} = FileInfo.analyze(path, [])
    assert size == byte_size(Fixtures.png_bytes())
    assert String.length(md5) == 32
  after
    File.rm_rf!(System.tmp_dir!() <> "/file_info_test_*")
  end

  test "analyze/2 adds detected_content_type when bytes are an image" do
    path = write_temp(Fixtures.png_bytes())
    assert {:ok, %{"detected_content_type" => "image/png"}} = FileInfo.analyze(path, [])
  end

  test "analyze/2 omits detected_content_type for non-images" do
    path = write_temp("plain bytes")
    assert {:ok, result} = FileInfo.analyze(path, [])
    refute Map.has_key?(result, "detected_content_type")
  end

  defp write_temp(bytes) do
    name = "file_info_test_#{System.unique_integer([:positive])}"
    path = Path.join(System.tmp_dir!(), name)
    File.write!(path, bytes)
    path
  end
end
