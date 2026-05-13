defmodule AshStorageDemo.Variants.VideoPoster do
  @moduledoc """
  Grabs a frame from a video at the configured offset (`:at`, in seconds,
  default 1.0) and writes it as a JPEG poster image. Uses ffmpex, which
  shells out to ffmpeg — the system needs ffmpeg on PATH at runtime.
  """
  @behaviour AshStorage.Variant

  @video_mimes ~w(video/mp4 video/quicktime video/webm video/x-matroska)

  @impl true
  def accept?(content_type), do: content_type in @video_mimes

  @impl true
  def transform(source_path, dest_path, opts) do
    at = Keyword.get(opts, :at, 1.0)

    cmd =
      FFmpex.new_command()
      |> FFmpex.add_global_option(FFmpex.Options.Main.option_y())
      |> FFmpex.add_input_file(source_path)
      |> FFmpex.add_output_file(dest_path)
      |> FFmpex.add_file_option(FFmpex.Options.Main.option_ss(at))
      |> FFmpex.add_file_option(FFmpex.Options.Video.option_vframes(1))

    case FFmpex.execute(cmd) do
      {:ok, _} -> {:ok, %{content_type: "image/jpeg", filename: "poster.jpg"}}
      {:error, reason} -> {:error, reason}
    end
  end
end
