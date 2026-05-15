defmodule AshStorageDemo.Analyzers.FileInfo do
  @moduledoc """
  Eager analyzer that records basic file info on every blob: detected MIME
  (sniffed from the bytes, not just the upload header), byte size, and an
  MD5 digest for quick equality checks in the UI.
  """
  @behaviour AshStorage.Analyzer

  @impl true
  def accept?(_content_type), do: true

  @impl true
  def analyze(path, _opts) do
    data = File.read!(path)
    detected = ExImageInfo.info(data)

    base = %{
      "byte_size" => byte_size(data),
      "md5" => :crypto.hash(:md5, data) |> Base.encode16(case: :lower)
    }

    case detected do
      {mime, _w, _h, _variant} -> {:ok, Map.put(base, "detected_content_type", mime)}
      _ -> {:ok, base}
    end
  end
end
