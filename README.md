<table>
  <tr>
    <td><img src="priv/static/images/ashtray-logo.svg" alt="Ashtray logo" width="180" /></td>
    <td>
      <h1>Ashtray</h1>
      <p>A small Phoenix app that exercises every corner of <a href="https://github.com/ash-project/ash_storage"><code>ash_storage</code></a>,</p>
      <p>multi-service routing, analyzers, variants, mirroring, polymorphic attachments and an orphan sweeper,</p>
      <p>in one feed-shaped demo.</p>
    </td>
  </tr>
</table>

Ashtray puts photos and videos on **S3** (MinIO in dev), documents on the local **Disk** service, mirrors cover images across both, and shows the analyzer / variant pipeline filling in metadata in real time as you upload.

---

## Running locally

Prerequisites: **Elixir 1.15+**, **PostgreSQL**, and **Docker** (for the bundled MinIO container).

```bash
# 1. Start the local S3-compatible store (MinIO on :19000, console on :19001)
docker compose up -d

# 2. Install deps, set up the DB, build assets
mix setup

# 3. Run the server
mix phx.server
```

Then open <http://localhost:4000>. The MinIO console is at <http://localhost:19001> (`minioadmin` / `minioadmin`) — the dev `ash-storage-demo` bucket is created automatically on first upload.

### Bundled dev tooling

Once the server is running, several dev surfaces are wired up:

| Route | What |
|---|---|
| `/` | Home — feature tour + live shared-volume gauge |
| `/feed`, `/profile`, `/storage-admin` | The three demo surfaces (sign-in required) |
| `/admin/` | [AshAdmin](https://hexdocs.pm/ash_admin) over every domain |
| `/oban` | [Oban Web](https://hexdocs.pm/oban_web) — see analyzer/variant jobs running |
| `/dev/dashboard` | Phoenix LiveDashboard |
| `/dev/mailbox` | Swoosh mailbox preview |

### Tests

```bash
mix test                # full suite — no MinIO required
mix test --max-failures 1
mix precommit           # compile --warnings-as-errors + format + tests
```

Tests don't need MinIO running: [config/test.exs](config/test.exs) flips every host resource to `AshStorage.Service.Test`, the in-memory service from `ash_storage`.

---

## Deploying to Fly.io

The target topology: a stateless Phoenix app + managed Postgres + a **separate** MinIO app backed by its own Fly volume (the S3-compatible store). Optionally, a second Fly volume on the app itself for the local Disk service.

Prerequisites: `flyctl auth login`, your org (`flyctl orgs list`), and a region (`flyctl platform regions`). **Use the same region for all three machines.**

### 1. MinIO app (the S3 store)

```bash
mkdir ../ash-storage-demo-minio && cd ../ash-storage-demo-minio
flyctl apps create ash-storage-demo-minio --org <ORG>
```

Drop a `fly.toml` that uses `image = "minio/minio:latest"`, runs `server /data --console-address :9001`, exposes the S3 API on **port 443** (Fly only auto-issues certs for 443 — non-443 TLS handlers hang the handshake), the console on port 9001, and mounts `minio_data → /data`. Then:

```bash
flyctl volumes create minio_data --region <REGION> --size 1 --app ash-storage-demo-minio
flyctl secrets set \
  MINIO_ROOT_USER="$(openssl rand -hex 12)" \
  MINIO_ROOT_PASSWORD="$(openssl rand -hex 24)" \
  --app ash-storage-demo-minio
flyctl deploy --app ash-storage-demo-minio
```

Then open the console at `https://ash-storage-demo-minio.fly.dev:9001` and create a bucket named **`ash-storage-demo`**.

> The app talks to MinIO via the public Fly edge on 443 (not `*.internal:9000`) because `req` doesn't pass `inet6: true` to Finch and Fly's `*.internal` hostnames are IPv6-only.

### 2. Phoenix app + Postgres

From the repo root:

```bash
mix phx.gen.release --docker         # commit the generated Dockerfile / rel/overlays
flyctl launch --no-deploy --copy-config --name ash-storage-demo --region <REGION> --org <ORG>
```

Accept Postgres when prompted, decline Redis/Tigris/Sentry, decline "deploy now". Then set secrets:

```bash
flyctl secrets set \
  SECRET_KEY_BASE="$(mix phx.gen.secret)" \
  TOKEN_SIGNING_SECRET="$(mix phx.gen.secret)" \
  PHX_HOST="ash-storage-demo.fly.dev" \
  S3_BUCKET="ash-storage-demo" \
  S3_REGION="us-east-1" \
  S3_ENDPOINT="https://ash-storage-demo-minio.fly.dev" \
  S3_KEY="<MINIO_ROOT_USER>" \
  S3_SECRET="<MINIO_ROOT_PASSWORD>" \
  STORAGE_VOLUME_BYTES="1073741824" \
  --app ash-storage-demo

flyctl deploy --app ash-storage-demo
```

`DATABASE_URL` is set automatically when Postgres is attached. `STORAGE_VOLUME_BYTES` is the denominator for the home page's shared-volume gauge, refreshed every 5 minutes by an Oban cron paging `ListObjectsV2` against the bucket.

### 3. (Optional) App volume for Disk attachments

`Post.documents` and the `cover_image` mirror use `AshStorage.Service.Disk`, which writes to `priv/storage/...` — ephemeral on a stateless app. To make them durable, attach a Fly volume to the app machine:

```bash
flyctl volumes create app_storage --region <REGION> --size 1 --app ash-storage-demo
flyctl scale count 1 --app ash-storage-demo            # volumes are host-pinned
flyctl secrets set DISK_STORAGE_ROOT="/data/storage" --app ash-storage-demo
```

Add a `[[mounts]] source = "app_storage", destination = "/data"` block to the app's `fly.toml` and redeploy. [config/runtime.exs](config/runtime.exs) already rewrites both Disk roots to `${DISK_STORAGE_ROOT}/...` in `:prod`. Don't mount at `priv/storage` directly — `priv` lives under a versioned release path that changes every deploy.

---

## Technical tour

`ash_storage` adds a `storage do … end` DSL to any Ash resource. One blob table is shared across the app; per-attachment service routing decides where the bytes physically land.

### Domains and host resources

| Domain | Host | Attachments | Notable |
|---|---|---|---|
| `Accounts` | `User` | `avatar`, `cover_photo` | Avatar runs `DominantColor` + three eager variants (small/medium/large) |
| `Feed` | `Post` | `cover_image`, `photos`, `videos`, `documents` | Mixed services: photos/videos → S3, documents → Disk, cover → S3 with Disk mirror |
| `Feed` | `Comment` | `attachments` | Disk-only |
| `Feed` | `Story` | `media` | Default `dependent: :purge` — files gone on destroy |
| `Feed` | `Reaction` | `sticker` | Custom `OutlinedSticker` variant |
| `Messaging` | `Message` | `files` | `dependent: false` — external retention |
| `Tagging` | `Tag` | `icons` | Uses `PolyAttachment` — same icons can hang off `Post`, `Comment` or `User` |

### The pipeline

Every host points at the same `Storage.Blob` table and one of three attachment tables (`Attachment`, `StickerAttachment`, `PolyAttachment`). On upload:

1. **Services** (`AshStorage.Service.S3` / `Disk` / `Test`) write the bytes. Per-attachment overrides let `Post.documents` land on disk while `Post.photos` go to S3.
2. **Analyzers** run post-write — eager inline (`FileInfo`) or via Oban (`ImageDimensions`, `Exif`). `Exif` writes EXIF fields back onto the host (`taken_at`, `camera`, `gps_*` on `Post`).
3. **Variants** generate derived blobs — `:eager` (avatar sizes), `:oban` (cover image `feed_size`), or `:on_demand` (photo thumbs, PDF previews, video posters). The `Image` variant uses [`vix`](https://hexdocs.pm/vix)/libvips; `VideoPoster` uses `ffmpex`; `PdfPreview` rasterises page 1; `OutlinedSticker` is a custom outline pass.
4. **Mirroring** — `Post.cover_image` writes to S3 and a Disk mirror. Reads consult S3 first and fall through to Disk on `:not_found`.
5. **Background ops** — Oban triggers on `Storage.Blob` (`run_pending_analyzers`, `run_pending_variants`, `purge_blob`) sweep work every minute.

### Service routing precedence

Three layers, each beating the next. Compile-time DSL ⟵ resource-level `service` ⟵ per-attachment override ⟵ runtime `Application` env (per-resource). [config/runtime.exs](config/runtime.exs) swaps S3 creds in prod without rebuilding the release; [config/test.exs](config/test.exs) flips everything to `Service.Test`.

### Storage admin

[`/storage-admin`](http://localhost:4000/storage-admin) is a cross-service inventory: bytes per service, counts per MIME, blob inspector with analyzer metadata, and a one-click purge for orphan blobs ([`Storage.Orphans`](lib/ash_storage_demo/storage/orphans.ex)).

### Serving bytes

- `/media/...` — `AshStorage.Plug.Proxy` streams S3 bytes through the app.
- `/r/...` — `AshStorage.Plug.Redirect` issues a 302 to a presigned S3 URL (FeedLive has a toggle to compare the two).
- `/files/documents`, `/files/cover_images_mirror` — `DiskServeRuntime` reads the on-disk root from `:disk_storage` Application env so the same release works against `priv/storage/...` in dev and `/data/storage/...` on a mounted Fly volume in prod.

---

## Links

- **`ash_storage` source / issues** → <https://github.com/ash-project/ash_storage>
- **Ash Framework** → <https://hexdocs.pm/ash>
- **Phoenix** → <https://hexdocs.pm/phoenix>
