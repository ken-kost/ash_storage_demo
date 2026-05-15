defmodule AshStorageDemo.Analyzers.Exif do
  @moduledoc """
  Extracts EXIF metadata from JPEGs using exexif. Designed to be paired
  with `write_attributes:` so the parent record (e.g. `Feed.Post`) gets
  `taken_at`, `camera`, `gps_lat`, `gps_lng` populated as a side effect
  of attaching a photo.
  """
  @behaviour AshStorage.Analyzer

  @impl true
  def accept?("image/jpeg"), do: true
  def accept?("image/jpg"), do: true
  def accept?(_), do: false

  @impl true
  def analyze(path, _opts) do
    case Exexif.exif_from_jpeg_file(path) do
      {:ok, info} ->
        {:ok, extract(info)}

      {:error, _} ->
        # Not every JPEG has EXIF data — just record an empty result instead
        # of failing the upload.
        {:ok, %{}}
    end
  end

  defp extract(info) do
    taken_at =
      info
      |> Map.get(:exif, %{})
      |> Map.get(:datetime_original)
      |> parse_datetime()

    camera =
      [Map.get(info, :make), Map.get(info, :model)]
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.join(" ")
      |> case do
        "" -> nil
        other -> other
      end

    {lat, lng} =
      info
      |> Map.get(:gps, %{})
      |> case do
        %{} = gps ->
          {decode_gps(gps[:gps_latitude], gps[:gps_latitude_ref]),
           decode_gps(gps[:gps_longitude], gps[:gps_longitude_ref])}

        _ ->
          {nil, nil}
      end

    %{
      "taken_at" => taken_at,
      "camera" => camera,
      "gps_lat" => lat,
      "gps_lng" => lng
    }
    |> Map.reject(fn {_, v} -> is_nil(v) end)
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(str) when is_binary(str) do
    case String.replace(str, ":", "-", global: false) |> String.split(" ") do
      [date, time] ->
        case NaiveDateTime.from_iso8601("#{String.replace(date, ":", "-")}T#{time}") do
          {:ok, dt} -> DateTime.from_naive!(dt, "Etc/UTC") |> DateTime.to_iso8601()
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp parse_datetime(_), do: nil

  defp decode_gps(nil, _), do: nil

  defp decode_gps([d, m, s], ref) when is_number(d) and is_number(m) and is_number(s) do
    decimal = d + m / 60 + s / 3600
    if ref in ["S", "W"], do: -decimal, else: decimal
  end

  defp decode_gps(_, _), do: nil
end
