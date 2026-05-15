defmodule AshStorageDemo.Storage.VolumeUsage do
  @moduledoc """
  Approximate fill of the shared S3-backed volume.

  Sums object sizes in the configured S3 bucket via `ListObjectsV2` (uses the
  same Req + sigv4 client AshStorage's S3 service uses), caches the result in
  `:persistent_term`, and broadcasts `{:volume_usage, %VolumeUsage{}}` over
  PubSub so subscribers (e.g. the home LiveView) can render live.

  This is bucket bytes, not raw filesystem usage of the Fly volume. For a
  single-bucket MinIO deploy on a 1 GB volume those track closely; metadata
  overhead and Fly volume reservation make the on-disk number a little larger.
  """

  alias Phoenix.PubSub

  @topic "storage:volume_usage"
  @cache_key {__MODULE__, :latest}

  defstruct used_bytes: 0,
            total_bytes: 0,
            percent: 0.0,
            object_count: 0,
            measured_at: nil,
            error: nil

  @type t :: %__MODULE__{
          used_bytes: non_neg_integer(),
          total_bytes: non_neg_integer(),
          percent: float(),
          object_count: non_neg_integer(),
          measured_at: DateTime.t() | nil,
          error: any()
        }

  def topic, do: @topic

  def subscribe do
    PubSub.subscribe(AshStorageDemo.PubSub, @topic)
  end

  @spec current() :: t()
  def current do
    case :persistent_term.get(@cache_key, nil) do
      nil -> %__MODULE__{total_bytes: total_bytes()}
      cached -> cached
    end
  end

  @doc """
  Measure the bucket and update the cache. Broadcasts the new value
  regardless of success — on failure the previous numbers are kept and
  `:error` is populated so the UI can surface it.
  """
  @spec refresh() :: {:ok, t()} | {:error, any()}
  def refresh do
    total = total_bytes()

    case measure() do
      {:ok, used, count} ->
        usage = %__MODULE__{
          used_bytes: used,
          total_bytes: total,
          percent: percent(used, total),
          object_count: count,
          measured_at: DateTime.utc_now(),
          error: nil
        }

        store_and_broadcast(usage)
        {:ok, usage}

      {:error, reason} ->
        %__MODULE__{} = prev = current()

        usage = %__MODULE__{
          prev
          | total_bytes: total,
            percent: percent(prev.used_bytes, total),
            measured_at: DateTime.utc_now(),
            error: reason
        }

        store_and_broadcast(usage)
        {:error, reason}
    end
  end

  defp store_and_broadcast(%__MODULE__{} = usage) do
    :persistent_term.put(@cache_key, usage)
    PubSub.broadcast(AshStorageDemo.PubSub, @topic, {:volume_usage, usage})
  end

  defp total_bytes do
    case System.get_env("STORAGE_VOLUME_BYTES") do
      nil ->
        Application.get_env(:ash_storage_demo, :storage_volume_bytes, 1_073_741_824)

      raw ->
        case Integer.parse(raw) do
          {n, _} when n > 0 -> n
          _ -> 1_073_741_824
        end
    end
  end

  defp percent(_used, 0), do: 0.0
  defp percent(used, total), do: Float.round(used / total * 100, 1)

  # -- Bucket measurement ---------------------------------------------------

  defp measure do
    s3 = Application.fetch_env!(:ash_storage_demo, :s3)

    bucket = Keyword.fetch!(s3, :bucket)
    endpoint = Keyword.fetch!(s3, :endpoint_url)
    access_key_id = Keyword.fetch!(s3, :access_key_id)
    secret_access_key = Keyword.fetch!(s3, :secret_access_key)
    region = Keyword.get(s3, :region, "us-east-1")

    req =
      Req.new(
        base_url: "#{endpoint}/#{bucket}",
        aws_sigv4: [
          service: :s3,
          region: region,
          access_key_id: access_key_id,
          secret_access_key: secret_access_key
        ],
        retry: :transient,
        receive_timeout: 15_000
      )

    sum_pages(req, nil, 0, 0)
  end

  defp sum_pages(req, continuation_token, acc_bytes, acc_count) do
    params = build_params(continuation_token)

    case Req.get(req, url: "/", params: params) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        result = parse_list_result(body)
        contents = List.wrap(result["Contents"])

        page_bytes = Enum.reduce(contents, 0, &(parse_size(&1["Size"]) + &2))
        acc_bytes = acc_bytes + page_bytes
        acc_count = acc_count + length(contents)

        if result["IsTruncated"] == "true" do
          sum_pages(req, result["NextContinuationToken"], acc_bytes, acc_count)
        else
          {:ok, acc_bytes, acc_count}
        end

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_params(nil), do: %{"list-type" => "2"}
  defp build_params(token), do: %{"list-type" => "2", "continuation-token" => token}

  # Req auto-decodes JSON but not S3's XML when we use a raw http(s) endpoint
  # (req_s3 only registers its decode step when the URL is `s3://`). The XML
  # parser in req_s3 is exactly what we need, so call it directly when the
  # body comes back as a string.
  defp parse_list_result(body) when is_binary(body) do
    case ReqS3.XML.parse_s3(body) do
      %{"ListBucketResult" => result} -> result
      other when is_map(other) -> other
      _ -> %{}
    end
  end

  defp parse_list_result(%{"ListBucketResult" => result}), do: result
  defp parse_list_result(map) when is_map(map), do: map
  defp parse_list_result(_), do: %{}

  defp parse_size(nil), do: 0
  defp parse_size(n) when is_integer(n), do: n

  defp parse_size(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, _} -> n
      :error -> 0
    end
  end
end
