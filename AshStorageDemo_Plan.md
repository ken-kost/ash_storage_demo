# AshStorageDemo — Build Plan

A demo Phoenix LiveView app that exercises **every** feature of [`ash_storage`](https://github.com/ash-project/ash_storage), shaped as a small social feed (posts, comments, profiles, stories, DMs). Zach Daniel's stated goal for a demo is:

> _"a social media feed that can upload pictures and files to different places and has features like resizing photos for profile pictures etc."_

So the app is the vehicle; the **real deliverable is feature coverage of `ash_storage`**, plus the roadmap items that haven't shipped yet.

---

## 1. Setup

### 1.1 Bootstrap the project via ash-hq.org

On <https://ash-hq.org> use the **Get Your Installer** widget with project name `ash_storage_demo`. Pick this exact preset set (Advanced Options):

| Group | Selection | Why |
|---|---|---|
| Web | **Phoenix** | LiveView for upload UI |
| Data Layers | **Postgres** | `ash_storage` resources need a SQL data layer (blob/attachment tables) |
| Automation | **Oban** | Required to demo `analyze: :oban` and `generate: :oban` for variants |
| Authentication | **Password** | A real social feed needs authors; gives us a `User` host resource |
| Dev Tools | **Admin UI** | Free inspector for blob/attachment rows while developing |
| AI | **Usage Rules** | Picks up `usage_rules.md` from every Ash dep — useful for editor/agent help |

That gives you a curl-one-liner roughly like:

```bash
sh <(curl 'https://ash-hq.org/install/ash_storage_demo') && cd ash_storage_demo
```

### 1.2 Add `ash_storage` and friends

`ash_storage` is not yet on the ash-hq installer, so add it by hand. Open `mix.exs` and append to `deps/0`:

```elixir
# AshStorage core
{:ash_storage, "~> 0.1"},

# S3 backend for AshStorage.Service.S3
{:req_s3, "~> 0.2"},

# For variants (image resize, PDF/video thumbs) — libvips, ships prebuilt binaries
{:image, "~> 0.54"},
{:vix, "~> 0.31"},

# For analyzers — pure-Elixir dimensions / EXIF
{:ex_image_info, "~> 0.2"},
{:exexif, "~> 0.0.5"},

# For FFmpeg-backed video metadata + thumbs (optional, only Phase 5)
{:ffmpex, "~> 0.11"}
```

Then:

```bash
mix deps.get
mix ash.codegen --dev   # picks up any pending Ash migrations
```

### 1.3 Local S3 (MinIO) via Docker

The `ash_storage` repo's `dev.exs` already shows the pattern — copy it. Create `docker-compose.yml` at the repo root:

```yaml
services:
  minio:
    image: minio/minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    ports:
      - "19000:9000"   # S3 API
      - "19001:9001"   # web console
    volumes:
      - minio_data:/data
volumes:
  minio_data:
```

Run `docker compose up -d minio`, then create the bucket (one-off):

```bash
docker run --rm --network host minio/mc \
  alias set local http://localhost:19000 minioadmin minioadmin && \
docker run --rm --network host minio/mc \
  mb local/ash-storage-demo
```

### 1.4 `config/runtime.exs` — storage service config

```elixir
# Default S3-backed config used by most host resources in prod-ish dev
config :ash_storage_demo, :s3,
  bucket: "ash-storage-demo",
  region: "us-east-1",
  access_key_id: System.get_env("S3_KEY", "minioadmin"),
  secret_access_key: System.get_env("S3_SECRET", "minioadmin"),
  endpoint_url: System.get_env("S3_ENDPOINT", "http://localhost:19000")
```

And in `config/test.exs`, swap every host resource to the in-memory test service (more in §6).

### 1.5 Three AshStorage resources, one time only

Generate the **blob** and **attachment** resources once — every host resource in the app reuses them.

```bash
mix ash.gen.resource AshStorageDemo.Storage.Blob \
  --extend AshStorage.BlobResource --uuid-primary-key id

mix ash.gen.resource AshStorageDemo.Storage.Attachment \
  --extend AshStorage.AttachmentResource --uuid-primary-key id
```

We will use the **multi-parent FK** flavour of the attachment resource (multiple nullable `belongs_to_resource` entries) for the main feed, and a **separate polymorphic** attachment resource for one specific feature in Phase 6. Two attachment tables, one blob table.

---

## 2. Architecture at a glance

```
AshStorageDemo.Storage
├── Blob              (AshStorage.BlobResource)
├── Attachment        (AshStorage.AttachmentResource — multi-parent FK)
└── PolyAttachment    (AshStorage.AttachmentResource — polymorphic, Phase 6)

AshStorageDemo.Accounts
└── User              (host: avatar, cover_photo)

AshStorageDemo.Feed
├── Post              (host: cover_image, photos[], videos[], documents[])
├── Comment           (host: attachments[])      ← shares Attachment with Post
├── Story             (host: media — ephemeral, demos dependent: :purge)
└── Reaction          (host with a custom "sticker" image)

AshStorageDemo.Messaging
└── Message           (host: files[] — private, signed URLs only)

AshStorageDemo.Tagging
└── Tag               (PolyAttachment target — Phase 6)
```

This layout deliberately spreads `ash_storage`'s features across resources so each phase has one focused thing to demo.

---

## 3. Feature coverage matrix

Every cell below is something the demo must visibly exercise.

| `ash_storage` capability | Where it lives in the demo |
|---|---|
| `BlobResource` extension | `Storage.Blob` |
| `AttachmentResource` — single-parent | `Reaction` (single belongs_to_resource) |
| `AttachmentResource` — multi-parent FK | `Storage.Attachment` shared by Post + Comment |
| `AttachmentResource` — polymorphic (`record_type`/`record_id`) | `Storage.PolyAttachment` for `Tag` |
| `has_one_attached` | `User.avatar`, `User.cover_photo`, `Post.cover_image`, `Story.media`, `Reaction.sticker` |
| `has_many_attached` | `Post.photos`, `Post.videos`, `Post.documents`, `Comment.attachments`, `Message.files` |
| `Service.Disk` | `Post.documents`, `Comment.attachments` |
| `Service.S3` (via MinIO) | `User.avatar`, `User.cover_photo`, `Post.photos`, `Post.videos` |
| `Service.Test` | every host, swapped in `config/test.exs` |
| Per-resource `service` (DSL) | `Comment` (whole resource on Disk) |
| Per-attachment `service` (DSL) | `Post.documents` on Disk, the rest of `Post` on S3 |
| Per-env config override (`otp_app`) | `User` flipped between S3 (dev) and Test (test) via `config :ash_storage_demo, User, storage: …` |
| `dependent: :purge` (default) | `Story.media`, `Post.cover_image` |
| `dependent: :detach` | `Post.documents` (keep files in cold storage even if post is deleted) |
| `dependent: false` | `Message.files` (let an external retention job own them) |
| `attach` | every upload form |
| `detach` | "Unlink doc" button on a Post |
| `purge` | "Delete attachment" button + on resource destroy |
| `purge` with `blob_id:` | per-doc remove in `has_many` list |
| `purge` with `all: true` | "Clear all photos" on a Post |
| `*_url` calculation | feed images, profile avatar, etc. |
| `documents_urls` plural calc | doc list on a Post |
| `AshStorage.Plug.DiskServe` (signed URLs) | `/files/*` for Disk-served docs |
| `AshStorage.Plug.Proxy` | `/media/*` proxy in front of S3 (toggle vs presigned to demo both) |
| **Analyzer** — `FileInfo` (eager) | every blob — verifies MIME on upload |
| **Analyzer** — `ImageDimensions` (eager) | `Post.cover_image`, `User.avatar` |
| **Analyzer** — `ImageDimensions` (`:oban`) | `Post.photos` — async, UI shows pending → complete |
| **Analyzer** — custom `DominantColor` | `User.avatar` — extracts a hex color via `image` (Phase 4) |
| **Analyzer** — custom `Exif` (`write_attributes:`) | `Post.photos` — writes `taken_at`, `camera`, `gps_lat`, `gps_lng` onto the **Post** itself |
| **Variant** — image (`:on_demand`) | `Post.photos.thumb` |
| **Variant** — image (`:eager`) | `User.avatar.{small,medium,large}` — generated during attach |
| **Variant** — image (`:oban`) | `Post.cover_image.feed_size` — backgrounded |
| **Variant** — PDF thumbnail | `Post.documents.preview` for PDF blobs |
| **Variant** — video thumbnail | `Post.videos.poster` via `ffmpex` |
| **Variant** — custom (`AshStorage.Variant` behaviour) | `Reaction.sticker.outlined` — runs a custom libvips pipeline |

---

## 4. Build phases

Each phase is shippable on its own and adds one slice of `ash_storage` surface area.

### Phase 0 — Skeleton (½ day)
- ash-hq.org install (§1.1) + add deps (§1.2)
- Boot MinIO (§1.3)
- `Storage.Blob` + `Storage.Attachment` resources, run migrations
- Phoenix `HomeLive` that just lists "no posts yet"

**Acceptance:** `mix phx.server` boots; `/admin` shows empty `storage_blobs` and `storage_attachments` tables.

### Phase 1 — Auth + User profile (1 day)
- AshAuthentication password strategy already wired by installer
- Add `User` host resource with `has_one_attached :avatar` and `has_one_attached :cover_photo` on S3
- `ProfileLive` with `<.live_file_input>` for avatar + cover
- Render `user.avatar_url` from the `*_url` calculation

**Demos:** `BlobResource`, `AttachmentResource`, `has_one_attached`, `Service.S3`, `attach`, `purge`, `*_url` calc.

### Phase 2 — Feed posts with mixed services (1–2 days)
- `Post` host with:
  - `has_one_attached :cover_image` (S3)
  - `has_many_attached :photos` (S3)
  - `has_many_attached :videos` (S3)
  - `has_many_attached :documents, service: {AshStorage.Service.Disk, root: "priv/storage", base_url: "/files"}, dependent: :detach`
- Mount `AshStorage.Plug.DiskServe` at `/files`, `AshStorage.Plug.Proxy` at `/media`
- `FeedLive` — create post, multi-file upload, render the timeline
- Reuse `Storage.Attachment` for Post **and** `Comment` (multi-parent FK pattern)

**Demos:** `has_many_attached`, per-attachment service override, both plugs, multi-parent FK attachment, `dependent: :detach`, `documents_urls`.

### Phase 3 — Comments, stories, messages, reactions (1 day)
- `Comment` — resource-level `service` on Disk (per-resource DSL override)
- `Story` — `dependent: :purge` (default), 24h TTL field, demonstrates a soft-destroy bypass note in code comments
- `Message.files` with `dependent: false` — show that files survive message deletion
- `Reaction.sticker` — single-parent attachment (separate resource just for this, to demo the simpler attachment flavour)

**Demos:** per-resource service, all three `dependent:` modes, single-parent attachment resource.

### Phase 4 — Analyzers (1–2 days)
- Turn on built-in `FileInfo` analyzer everywhere (eager) — UI badge per blob shows MIME from libmagic-style sniffing
- Turn on built-in `ImageDimensions`:
  - Eager on `User.avatar` + `Post.cover_image`
  - **`:oban`** on `Post.photos` — and prove it works by showing a yellow "analyzing…" pill in LiveView that flips green via `PubSub` (the `dev.exs` example does exactly this)
- Custom analyzer #1 — `Analyzers.DominantColor` for `User.avatar`: implements `AshStorage.Analyzer`, uses `Image.dominant_color/1`, stores hex in `blob.analyzers`
- Custom analyzer #2 — `Analyzers.Exif` for `Post.photos` with `write_attributes: [taken_at: ..., camera: ..., gps_lat: ..., gps_lng: ...]` so the **Post's** own columns are populated as a side effect

**Demos:** built-in + custom analyzers, sync + Oban modes, `write_attributes`, blob `metadata`/`analyzers` maps surfaced in UI.

### Phase 5 — Variants (2 days)
- Image variants on `User.avatar`: `small` 64×64, `medium` 256×256, `large` 1024×1024 — `generate: :eager` so they exist immediately
- Image variant on `Post.photos.thumb` — `generate: :on_demand` (default), shows lazy creation on first hit
- Image variant on `Post.cover_image.feed_size` — `generate: :oban`, background regen
- PDF preview variant on `Post.documents.preview` — only fires for `application/pdf`; uses `image` + libvips with Poppler, or `thumbnex` fallback
- Video poster variant on `Post.videos.poster` — `ffmpex` grabs frame at t=1s
- Custom variant on `Reaction.sticker.outlined` — implements `AshStorage.Variant` behaviour, runs a libvips edge-detect+composite pipeline

**Demos:** all three generation modes, built-in image variants, PDF + video variant behaviours, custom variants, digest-based cache invalidation (change source, re-derive).

### Phase 6 — Polymorphic attachments (½ day)
- `Storage.PolyAttachment` — second `AttachmentResource`, no `belongs_to_resource`, uses `record_type` + `record_id`
- `Tag` host resource with `has_many_attached :icons` pointing at `PolyAttachment`
- Show that the same `Tag.icons` flow works whether the tag was created from a `Post`, a `Comment`, or a `User` (UI: "tag a photo to this user")

**Demos:** fully polymorphic attachment pattern (third flavour in the README).

### Phase 7 — Roadmap features (parallelisable — this is the "more meat" Zach wants)
These are net-new and need PRs to `ash_storage` first, then the demo should pick them up.

| Roadmap item | What the demo proves |
|---|---|
| **Checksum verification** | `Post.documents` rejects uploads whose computed digest doesn't match a `checksum:` arg; show a deliberately corrupted upload getting rejected |
| **Redirect handler plug** | Add a `/r/*` route using the new plug; toggle a UI switch between `Proxy` (current) and `Redirect` for S3 traffic and show network tab differences |
| **Mirroring service** | New "redundant" attachment on `Post.cover_image` configured with `Service.Mirror, services: [Service.S3, Service.Disk]`; kill MinIO, prove Disk still serves the file |
| **Orphan cleanup** | Manually `Repo.delete_all(Blob)` for one row, then run `AshStorage.Operations.cleanup_orphans/1`; with AshOban enabled, schedule it as a recurring job and surface results in admin |
| **GCS service** | Smoke test if a GCS bucket is available (optional, env-gated) |
| **Azure service** | Same, env-gated |

### Phase 8 — UI polish + observability (1 day)
- Drag-and-drop uploads with previews (`live_img_preview` for images, generic file pill for the rest)
- Show analyzer status pills (pending / complete / error / skipped) — same component for every blob
- Render analyzer `metadata` and `write_attributes` results inline
- Admin page showing all blobs with size, service, analyzers, variants, and a "purge orphan" button
- A simple "storage stats" LiveView reading from the blob table: total bytes per service, count by content_type

### Phase 9 — Tests (1 day, run continuously)
- `config/test.exs`: flip every host resource to `Service.Test` via per-env app config (proves the resolution order — per-env config beats DSL)
- `test/test_helper.exs`: `AshStorage.Service.Test.start()`
- One test per host resource: attach → assert via `Ash.load!` → detach → purge → assert gone
- A "no Docker required" CI job that runs the whole suite green

---

## 5. Resource sketches

Just enough to make the plan unambiguous — full code lives in the repo.

```elixir
defmodule AshStorageDemo.Storage.Blob do
  use Ash.Resource,
    domain: AshStorageDemo.Storage,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage.BlobResource]

  postgres do
    table "storage_blobs"
    repo AshStorageDemo.Repo
  end

  blob do
    # analyzers turned on per host resource, not globally
  end

  attributes do
    uuid_primary_key :id
  end
end
```

```elixir
defmodule AshStorageDemo.Storage.Attachment do
  use Ash.Resource,
    domain: AshStorageDemo.Storage,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage.AttachmentResource]

  postgres do
    table "storage_attachments"
    repo AshStorageDemo.Repo
  end

  attachment do
    blob_resource AshStorageDemo.Storage.Blob
    belongs_to_resource :post, AshStorageDemo.Feed.Post
    belongs_to_resource :comment, AshStorageDemo.Feed.Comment
  end

  attributes do
    uuid_primary_key :id
  end
end
```

```elixir
defmodule AshStorageDemo.Feed.Post do
  use Ash.Resource,
    domain: AshStorageDemo.Feed,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshStorage],
    otp_app: :ash_storage_demo

  storage do
    blob_resource AshStorageDemo.Storage.Blob
    attachment_resource AshStorageDemo.Storage.Attachment

    # default service for this resource — S3 via MinIO
    service {AshStorage.Service.S3, Application.compile_env(:ash_storage_demo, :s3)}

    has_one_attached :cover_image,
      analyzers: [
        AshStorage.Analyzer.FileInfo,
        AshStorage.Analyzer.ImageDimensions
      ],
      variants: [
        {:feed_size, {AshStorage.Variant.Image, width: 1200, generate: :oban}}
      ]

    has_many_attached :photos,
      analyzers: [
        AshStorage.Analyzer.FileInfo,
        {AshStorage.Analyzer.ImageDimensions, analyze: :oban},
        {AshStorageDemo.Analyzers.Exif,
         write_attributes: [
           taken_at: :taken_at,
           camera: :camera,
           gps_lat: :gps_lat,
           gps_lng: :gps_lng
         ]}
      ],
      variants: [
        {:thumb, {AshStorage.Variant.Image, width: 300}}   # :on_demand by default
      ]

    has_many_attached :videos,
      variants: [
        {:poster, {AshStorageDemo.Variants.VideoPoster, at: 1.0}}
      ]

    # override the resource-level service just for documents
    has_many_attached :documents,
      service: {AshStorage.Service.Disk, root: "priv/storage", base_url: "/files"},
      dependent: :detach,
      variants: [
        {:preview, {AshStorageDemo.Variants.PdfPreview, []}}
      ]
  end
end
```

```elixir
# config/test.exs — per-env override, proves precedence rules
config :ash_storage_demo, AshStorageDemo.Feed.Post,
  storage: [service: {AshStorage.Service.Test, []}]
```

---

## 6. Testing strategy

- **No Docker in CI.** Every test runs against `AshStorage.Service.Test` injected via per-env config.
- One **integration** lane that does spin MinIO up — only there do we hit `Service.S3` for real.
- Property-style coverage matrix: for each `(host, attachment_kind, dependent)` triple, assert behaviour on create / update / destroy / soft-destroy.
- Variants and analyzers each get a dedicated test module — including one test that asserts an `:oban` analyzer is **enqueued, not run inline** (`Oban.Testing` drained manually).

---

## 7. Open questions for Zach / the group — answered

1. **Polymorphic attachment in the same Attachment table?** **Confirmed** — multi-FK and pure-polymorphic are mutually exclusive per attachment resource. The demo uses two attachment tables (`Storage.Attachment` for multi-FK, `Storage.PolyAttachment` for pure-poly).
2. **Variant chain caching** — when `generate: :on_demand`, the rendered output is stored on the **same service as the source** blob. No separate cache service config required.
3. **`write_attributes` from an `:oban` analyzer** — the parent resource gets a **normal update action call**, so the parent's policies must permit the write. Plan accordingly (dedicated bypass update action, or system-actor permissions).
4. **Soft-destroy + variants** — variants of a soft-destroyed parent become **unreachable** (the soft-destroy skips dependent handling, but the variant URL paths must 404). UI in Phase 8 enforces this.
5. **Service.Test + variants** — `Service.Test` **synthesises** variant blobs, so tests can assert variant URLs and metadata just like a live run.

---

## 8. Suggested PR sequencing

Mapping the build phases back to the `ash_storage` repo so this stays a contribution, not just an external demo:

1. PRs against `ash_storage`: checksum verification → redirect handler → mirroring service → orphan cleanup (Phase 7 items, in that order).
2. Each PR ships with a matching slice of the demo app that uses it — that's the "demo app with meat on it" Zach asked for.
3. Final PR to `ash_storage` adds a `documentation/topics/demo.md` pointing at the demo repo and walking through the matrix in §3.
