// Shared screen components for the Ash Storage Demo upgrade.

const Chrome = ({ active, user = "maria@ash.dev", children }) => (
  <div className="chrome">
    <header className="nav">
      <a className="brand" href="#">
        <span className="brand-mark" aria-hidden="true">
          <svg viewBox="0 0 24 24" width="20" height="20"><path d="M12 2 3 20h18L12 2zm0 5.6 5.4 10.8H6.6L12 7.6z" fill="currentColor"/></svg>
        </span>
        <span className="brand-text">
          <span className="brand-name">ash<span className="brand-dot">/</span>storage</span>
          <span className="brand-sub">demo</span>
        </span>
      </a>
      <nav className="nav-links">
        <a className={active === "feed" ? "is-active" : ""} href="#">Feed</a>
        <a className={active === "profile" ? "is-active" : ""} href="#">Profile</a>
        <a className={active === "storage" ? "is-active" : ""} href="#">Storage</a>
        <span className="nav-sep" />
        <div className="theme-toggle" role="group" aria-label="Theme">
          <button aria-label="System"><Icon.Monitor/></button>
          <button className="is-on" aria-label="Light"><Icon.Sun/></button>
          <button aria-label="Dark"><Icon.Moon/></button>
        </div>
        <span className="user-chip">
          <span className="user-avatar">M</span>
          <span className="user-email">{user}</span>
        </span>
      </nav>
    </header>
    <main className="main">{children}</main>
  </div>
);

const Icon = {
  Monitor: () => <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="1.8"><rect x="3" y="4" width="18" height="13" rx="2"/><path d="M8 21h8M12 17v4"/></svg>,
  Sun: () => <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="1.8"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41"/></svg>,
  Moon: () => <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>,
  Arrow: () => <svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" strokeWidth="2"><path d="M15 6l-6 6 6 6"/></svg>,
  Plus: () => <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 5v14M5 12h14"/></svg>,
  Image: () => <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="1.7"><rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="1.5"/><path d="m3 17 5-5 4 4 3-3 6 6"/></svg>,
  Video: () => <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="1.7"><rect x="3" y="6" width="13" height="12" rx="2"/><path d="m16 10 5-3v10l-5-3z"/></svg>,
  Doc: () => <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="1.7"><path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><path d="M14 3v6h6M8 13h8M8 17h6"/></svg>,
  Cloud: () => <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="1.7"><path d="M7 18a5 5 0 1 1 1.2-9.85A6 6 0 0 1 20 11a4 4 0 0 1-1 7.87"/></svg>,
  Disk: () => <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="1.7"><rect x="3" y="5" width="18" height="5" rx="1"/><rect x="3" y="14" width="18" height="5" rx="1"/><path d="M7 7.5h.01M7 16.5h.01"/></svg>,
  Dot: () => <svg viewBox="0 0 8 8" width="8" height="8"><circle cx="4" cy="4" r="3" fill="currentColor"/></svg>,
  Trash: () => <svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M4 7h16M10 11v6M14 11v6M6 7l1 13a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-13M9 7V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v3"/></svg>,
  Upload: () => <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="1.7"><path d="M12 16V4M7 9l5-5 5 5M4 20h16"/></svg>,
  Check: () => <svg viewBox="0 0 24 24" width="11" height="11" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="m5 12 5 5L20 7"/></svg>,
  Spin: () => <svg viewBox="0 0 24 24" width="11" height="11" fill="none" stroke="currentColor" strokeWidth="2.2"><circle cx="12" cy="12" r="8" opacity="0.25"/><path d="M20 12a8 8 0 0 0-8-8"/></svg>,
  X: () => <svg viewBox="0 0 24 24" width="11" height="11" fill="none" stroke="currentColor" strokeWidth="2.4"><path d="M6 6l12 12M18 6 6 18"/></svg>,
  Slash: () => <svg viewBox="0 0 24 24" width="11" height="11" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M5 19 19 5"/></svg>,
};

const StatusPill = ({ kind, label }) => {
  const map = {
    complete: { tone: "ok", icon: <Icon.Check/>, text: "complete" },
    pending: { tone: "wait", icon: <Icon.Spin/>, text: "pending" },
    error: { tone: "err", icon: <Icon.X/>, text: "error" },
    skipped: { tone: "mute", icon: <Icon.Slash/>, text: "skipped" },
  };
  const v = map[kind] || map.skipped;
  return (
    <span className={`pill pill-${v.tone}`}>
      <span className="pill-icon">{v.icon}</span>
      <span className="pill-label">{label}</span>
      <span className="pill-sep">·</span>
      <span className="pill-status">{v.text}</span>
    </span>
  );
};

const ServiceTag = ({ kind }) => (
  <span className={`svc svc-${kind}`}>
    {kind === "s3" ? <Icon.Cloud/> : <Icon.Disk/>}
    <span>{kind === "s3" ? "S3" : "Disk"}</span>
  </span>
);

const Placeholder = ({ label, h = 180, kind = "photo" }) => (
  <div className="ph" style={{height: h}}>
    <svg className="ph-bg" preserveAspectRatio="none" viewBox="0 0 100 100">
      <defs>
        <pattern id={"st-"+label.replace(/\W/g,'')} width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
          <line x1="0" y1="0" x2="0" y2="6" stroke="currentColor" strokeWidth="1" opacity="0.35"/>
        </pattern>
      </defs>
      <rect width="100" height="100" fill={"url(#st-"+label.replace(/\W/g,'')+")"}/>
    </svg>
    <span className="ph-label">{label}</span>
  </div>
);

/* =====================  HOME  ===================== */
const Home = () => (
  <Chrome active="home">
    <div className="home-hero">
      <div className="hero-eyebrow">
        <span className="kbd">v0.1</span>
        <span className="eyebrow-text">ash_storage · a polymorphic attachment layer for Ash</span>
      </div>
      <h1 className="hero-title">
        Storage that knows<br/>
        <em>where</em> things live, <em>what</em> they are,<br/>
        and <em>who</em> they belong to.
      </h1>
      <p className="hero-lede">
        One blob table. Many services. Pluggable analyzers.<br/>
        This demo wires a feed against S3 and local Disk so you can watch the pipeline run.
      </p>
      <div className="hero-ctas">
        <a className="btn btn-primary" href="#">Open the feed <Icon.Arrow/></a>
        <a className="btn btn-ghost" href="#">Read the spec</a>
      </div>

      <div className="hero-stats">
        <div className="stat">
          <span className="stat-num">3</span>
          <span className="stat-lbl">attachment surfaces<br/><em>posts · users · documents</em></span>
        </div>
        <div className="stat">
          <span className="stat-num">2</span>
          <span className="stat-lbl">services<br/><em>S3 · Disk</em></span>
        </div>
        <div className="stat">
          <span className="stat-num">4</span>
          <span className="stat-lbl">analyzers<br/><em>FileInfo · Exif · Variants · DominantColor</em></span>
        </div>
      </div>
    </div>

    <div className="home-grid">
      <a href="#" className="tile">
        <div className="tile-head">
          <span className="tile-num">01</span>
          <span className="tile-name">Feed</span>
        </div>
        <p className="tile-desc">Compose posts with cover image, photos, videos and documents. Watch analyzers fill in metadata in real time.</p>
        <span className="tile-meta">photos · videos → S3 &nbsp; documents → Disk</span>
      </a>
      <a href="#" className="tile">
        <div className="tile-head">
          <span className="tile-num">02</span>
          <span className="tile-name">Profile</span>
        </div>
        <p className="tile-desc">Avatar and cover photo with dominant-color tinting, variants and signed URLs.</p>
        <span className="tile-meta">single-attachment slots · variant pipeline</span>
      </a>
      <a href="#" className="tile">
        <div className="tile-head">
          <span className="tile-num">03</span>
          <span className="tile-name">Storage admin</span>
        </div>
        <p className="tile-desc">Cross-service inventory. Bytes by service, counts by mime, orphan sweeper, blob inspector.</p>
        <span className="tile-meta">read-only · production-safe</span>
      </a>
    </div>
  </Chrome>
);

/* =====================  FEED  ===================== */
const Feed = () => (
  <Chrome active="feed">
    <BackLink/>
    <div className="page-head">
      <h1>Feed</h1>
      <p className="page-sub">
        <span><Icon.Cloud/> photos · videos route to <strong>S3</strong></span>
        <span className="sep">/</span>
        <span><Icon.Disk/> documents route to <strong>Disk</strong></span>
      </p>
    </div>

    <section className="composer">
      <textarea className="composer-input" placeholder="What's on your mind?" defaultValue="Field notes from the storage team. Pushing the new analyzer chain to staging this afternoon — EXIF + dominant-color on every photo, and we'll start variants next week."/>
      <div className="composer-slots">
        <Slot label="Cover image" hint=".jpg .png .webp · 16MB" svc="s3" max="1"/>
        <Slot label="Photos" hint="up to 6 · 16MB each" svc="s3" max="6" filled={["sunset.jpg","studio-01.png"]}/>
        <Slot label="Videos" hint="up to 2 · 64MB each" svc="s3" max="2"/>
        <Slot label="Documents" hint=".pdf .txt .md .csv · 16MB" svc="disk" max="4" filled={["spec-v3.pdf"]}/>
      </div>
      <div className="composer-foot">
        <span className="composer-hint">Drafts are not persisted. <kbd>⌘</kbd>+<kbd>↵</kbd> to post.</span>
        <button className="btn btn-primary">Post</button>
      </div>
    </section>

    <div className="feed-divider">
      <span>2 posts</span>
      <span className="rule"/>
      <span>sorted by <em>newest</em></span>
    </div>

    <Post
      author="theo@ash.dev"
      time="2026-05-13 14:02"
      body="Shot these on the M-mount over the weekend. The Exif analyzer pulled GPS, camera body and capture time straight off the originals — no client work."
      cover
      photos={3}
      meta={[
        ["Taken at", "2026-05-11 18:24 UTC"],
        ["Camera", "Leica M11 · 35mm f/1.4"],
        ["GPS", "37.7790, -122.4192"],
      ]}
    />

    <Post
      author="maria@ash.dev"
      time="2026-05-13 09:48"
      body="Routing the new RFC through the Disk service for now — the analyzer chain still flags content-type mismatches even though the upload header claimed text/plain."
      docs
    />
  </Chrome>
);

const BackLink = () => (
  <a className="back" href="#"><Icon.Arrow/> Back to home</a>
);

const Slot = ({label, hint, svc, max, filled = []}) => (
  <div className={`slot ${filled.length ? "has-files" : ""}`}>
    <div className="slot-head">
      <span className="slot-label">{label}</span>
      <ServiceTag kind={svc}/>
    </div>
    <div className="slot-drop">
      {filled.length === 0 ? (
        <>
          <Icon.Upload/>
          <span>Drop or <u>browse</u></span>
        </>
      ) : (
        <ul className="slot-files">
          {filled.map(f => (
            <li key={f}><span className="file-name">{f}</span><Icon.Check/></li>
          ))}
          <li className="slot-add"><Icon.Plus/> add more</li>
        </ul>
      )}
    </div>
    <div className="slot-foot">{hint} · max {max}</div>
  </div>
);

const Post = ({author, time, body, cover, photos = 0, meta = [], docs = false}) => (
  <article className="post">
    <header className="post-head">
      <span className="post-author">
        <span className="post-avatar">{author[0].toUpperCase()}</span>
        <span>
          <span className="post-name">{author}</span>
          <span className="post-time">{time}</span>
        </span>
      </span>
      <span className="post-id">post_<span className="mono">01J9X4T2</span></span>
    </header>
    <p className="post-body">{body}</p>

    {cover && (
      <Placeholder label="cover-image · 2400×1350 · jpeg" h={220}/>
    )}

    {photos > 0 && (
      <div className="post-section">
        <div className="post-section-head">
          <span>Photos <em>({photos})</em></span>
          <button className="link-quiet">Clear all</button>
        </div>
        <div className="photo-grid">
          {Array.from({length: photos}).map((_,i) => (
            <Placeholder key={i} label={`IMG_034${i+1}.jpg`} h={120}/>
          ))}
        </div>
      </div>
    )}

    {meta.length > 0 && (
      <dl className="post-meta">
        {meta.map(([k,v]) => (
          <React.Fragment key={k}>
            <dt>{k}</dt>
            <dd className="mono">{v}</dd>
          </React.Fragment>
        ))}
      </dl>
    )}

    {docs && (
      <div className="post-section">
        <div className="post-section-head">
          <span>Documents <em>(1)</em></span>
        </div>
        <ul className="doc-list">
          <li>
            <div className="doc-row">
              <a className="doc-link"><Icon.Doc/> rfc-0042-content-sniffing.txt</a>
              <span className="badge-mono">application/pdf <span className="badge-detected">detected</span></span>
              <button className="btn-tiny">Unlink</button>
            </div>
            <div className="doc-pills">
              <StatusPill kind="complete" label="FileInfo"/>
              <StatusPill kind="complete" label="ContentType"/>
              <StatusPill kind="pending" label="Indexer"/>
              <StatusPill kind="skipped" label="Exif"/>
            </div>
          </li>
        </ul>
      </div>
    )}
  </article>
);

/* =====================  PROFILE  ===================== */
const Profile = () => (
  <Chrome active="profile">
    <BackLink/>
    <div className="page-head">
      <h1>Your profile</h1>
      <p className="page-sub">
        Single-attachment slots. Uploads land on <strong>S3</strong>, then a variant chain emits thumbnails and a dominant-color sample.
      </p>
    </div>

    <article className="panel">
      <header className="panel-head">
        <div>
          <h2>Avatar</h2>
          <span className="panel-sub">256×256 square · auto-cropped variants generated</span>
        </div>
        <div className="panel-tools">
          <span className="color-chip" style={{background: "#7a5cff"}}>
            <span>#7A5CFF</span>
          </span>
          <a className="link-quiet" href="#">View current</a>
          <button className="link-quiet danger">Remove</button>
        </div>
      </header>
      <div className="panel-body avatar-body">
        <div className="avatar-preview" style={{background: "#7a5cff"}}>
          <span>M</span>
        </div>
        <div className="avatar-variants">
          <Variant size="512" label="original"/>
          <Variant size="256" label="display"/>
          <Variant size="96" label="medium"/>
          <Variant size="48" label="small"/>
        </div>
      </div>
      <div className="panel-upload">
        <div className="file-input">
          <Icon.Upload/>
          <span>Drop a new avatar, or <u>browse</u></span>
          <span className="file-hint">.jpg .png .webp · max 8MB</span>
        </div>
        <button className="btn btn-primary">Upload</button>
      </div>
      <footer className="panel-foot">
        <Field k="blob_id" v="01J9X4Q…7K2D"/>
        <Field k="service" v="s3:primary"/>
        <Field k="content_type" v="image/png"/>
        <Field k="byte_size" v="142.4 KB"/>
      </footer>
    </article>

    <article className="panel">
      <header className="panel-head">
        <div>
          <h2>Cover photo</h2>
          <span className="panel-sub">1600×400 wide · single attachment</span>
        </div>
        <div className="panel-tools">
          <a className="link-quiet" href="#">View current</a>
          <button className="link-quiet danger">Remove</button>
        </div>
      </header>
      <div className="panel-body">
        <Placeholder label="cover · 1600×400 · jpeg" h={170}/>
      </div>
      <div className="panel-upload">
        <div className="file-input">
          <Icon.Upload/>
          <span>Drop a new cover, or <u>browse</u></span>
          <span className="file-hint">.jpg .png .webp · max 16MB</span>
        </div>
        <button className="btn btn-primary">Upload</button>
      </div>
      <footer className="panel-foot">
        <Field k="blob_id" v="01J9W2H…4P1A"/>
        <Field k="service" v="s3:primary"/>
        <Field k="content_type" v="image/jpeg"/>
        <Field k="byte_size" v="2.1 MB"/>
      </footer>
    </article>
  </Chrome>
);

const Variant = ({size, label}) => (
  <div className="variant">
    <div className="variant-tile" style={{background: "#7a5cff"}}>
      <span>M</span>
    </div>
    <span className="variant-label">{label}</span>
    <span className="variant-size mono">{size}px</span>
  </div>
);

const Field = ({k, v}) => (
  <div className="field"><span className="field-k">{k}</span><span className="field-v mono">{v}</span></div>
);

/* =====================  STORAGE ADMIN  ===================== */
const Storage = () => (
  <Chrome active="storage">
    <BackLink/>
    <div className="page-head">
      <h1>Storage admin</h1>
      <p className="page-sub">
        Aggregate view across every host. For the per-resource UI see <a className="inline-link mono" href="#">/admin/</a>.
      </p>
    </div>

    <section className="kpi-row">
      <Kpi label="Total blobs" value="1,284" hint="+ 42 last 24h"/>
      <Kpi label="Stored bytes" value="14.8 GB" hint="S3 14.2 · Disk 0.6"/>
      <Kpi label="Analyzer queue" value="6 pending" hint="0 errors · 2 skipped" tone="wait"/>
      <Kpi label="Orphans" value="3" hint="purgeable" tone="warn"/>
    </section>

    <section className="two-up">
      <article className="card">
        <h2 className="card-title">Bytes per service</h2>
        <ul className="bar-list">
          <BarRow svc="s3" name="s3:primary" bytes="13.9 GB" pct={94}/>
          <BarRow svc="s3" name="s3:eu" bytes="312 MB" pct={3}/>
          <BarRow svc="disk" name="disk:local" bytes="624 MB" pct={4}/>
        </ul>
      </article>

      <article className="card">
        <h2 className="card-title">Count per content-type</h2>
        <ul className="ct-list">
          <CtRow ct="image/jpeg" count={742}/>
          <CtRow ct="image/png" count={318}/>
          <CtRow ct="video/mp4" count={84}/>
          <CtRow ct="application/pdf" count={78}/>
          <CtRow ct="image/webp" count={42}/>
          <CtRow ct="text/markdown" count={14}/>
          <CtRow ct="(unknown)" count={6} muted/>
        </ul>
      </article>
    </section>

    <article className="orphan-bar">
      <div>
        <h2>Orphan blobs</h2>
        <p>Blob rows with no attachment in any of the three attachment tables.</p>
      </div>
      <div className="orphan-actions">
        <span className="orphan-count">3</span>
        <button className="btn btn-danger">Purge orphan records</button>
      </div>
    </article>

    <section className="blobs">
      <header className="blobs-head">
        <h2>Recent blobs</h2>
        <div className="blobs-filter">
          <button className="chip is-on">All</button>
          <button className="chip">Images</button>
          <button className="chip">Video</button>
          <button className="chip">Docs</button>
          <button className="chip">Variants</button>
        </div>
      </header>

      <ul className="blob-list">
        <BlobRow
          name="IMG_03471.jpg"
          ct="image/jpeg"
          svc="s3"
          size="4.2 MB"
          time="14:02"
          analyzers={[["FileInfo","complete"],["Exif","complete"],["DominantColor","complete"],["Variants","pending"]]}
          meta={[["camera","Leica M11"],["taken_at","2026-05-11 18:24Z"],["dominant","#7a5cff"]]}
        />
        <BlobRow
          name="IMG_03471.jpg"
          variantOf="display"
          ct="image/webp"
          svc="s3"
          size="312 KB"
          time="14:02"
          analyzers={[["FileInfo","complete"],["Exif","skipped"]]}
        />
        <BlobRow
          name="rfc-0042-content-sniffing.txt"
          ct="text/plain"
          detected="application/pdf"
          svc="disk"
          size="184 KB"
          time="09:48"
          analyzers={[["FileInfo","complete"],["ContentType","complete"],["Indexer","pending"]]}
          meta={[["detected","application/pdf"],["sha256","9c1a…d4f0"]]}
        />
        <BlobRow
          name="walkthrough-final.mp4"
          ct="video/mp4"
          svc="s3"
          size="38.6 MB"
          time="08:11"
          analyzers={[["FileInfo","complete"],["Probe","error"]]}
        />
      </ul>
    </section>
  </Chrome>
);

const Kpi = ({label, value, hint, tone}) => (
  <div className={`kpi ${tone ? "kpi-"+tone : ""}`}>
    <span className="kpi-label">{label}</span>
    <span className="kpi-value">{value}</span>
    <span className="kpi-hint">{hint}</span>
  </div>
);

const BarRow = ({svc, name, bytes, pct}) => (
  <li>
    <div className="bar-meta">
      <span className="bar-name"><ServiceTag kind={svc}/> <span className="mono">{name}</span></span>
      <span className="bar-bytes mono">{bytes}</span>
    </div>
    <div className="bar-track"><span className="bar-fill" style={{width: pct+"%"}}/></div>
  </li>
);

const CtRow = ({ct, count, muted}) => (
  <li className={muted ? "is-muted" : ""}>
    <span className="ct-name mono">{ct}</span>
    <span className="ct-rail"><span className="ct-fill" style={{width: Math.min(100, count/8)+"%"}}/></span>
    <span className="ct-count mono">{count}</span>
  </li>
);

const BlobRow = ({name, ct, detected, svc, size, time, variantOf, analyzers = [], meta = []}) => (
  <li className="blob">
    <div className="blob-head">
      <span className="blob-name mono">{name}</span>
      <div className="blob-tags">
        {variantOf && <span className="tag-variant">variant · {variantOf}</span>}
        <span className="badge-mono">
          {ct}
          {detected && <span className="badge-detected">→ {detected}</span>}
        </span>
      </div>
    </div>
    <div className="blob-sub">
      <ServiceTag kind={svc}/>
      <span className="sep">·</span>
      <span className="mono">{size}</span>
      <span className="sep">·</span>
      <span className="mono">{time}</span>
    </div>
    {analyzers.length > 0 && (
      <div className="blob-pills">
        {analyzers.map(([n, s]) => <StatusPill key={n+s} kind={s} label={n}/>)}
      </div>
    )}
    {meta.length > 0 && (
      <dl className="blob-meta">
        {meta.map(([k,v]) => (
          <React.Fragment key={k}>
            <dt>{k}</dt>
            <dd className="mono">{v}</dd>
          </React.Fragment>
        ))}
      </dl>
    )}
  </li>
);

Object.assign(window, { Home, Feed, Profile, Storage });
