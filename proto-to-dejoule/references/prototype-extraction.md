# Prototype extraction playbook (any HTML + Python backend)

Systematic procedure for Phase 0–1. Goal: a **complete, reconciled inventory** of the prototype —
nothing reaches Phase 2 unaccounted for. Works for any Python web framework and any HTML/JS flavor.

**Scope rules (read first):**
- **Multiple apps are normal.** Census every Python app in the repo (serving API, training/CLI
  pipeline, admin tools) and tag each route with its app + how it's deployed. Training/CLI pipelines
  are usually a separate workstream (airflow/SageMaker), not REST endpoints to port — tag, don't drop.
- **Multiple frontends are normal** (a legacy UI kept as fallback). Fully census the primary;
  for the legacy one only diff which endpoints it consumes.
- **Cross-check the prototype's own docs against its code** — same "code wins" rule as for the
  DeJoule repos. Record a drift list (docs claiming features/data the code doesn't have).
- **Tag prototype scaffolding** (demo tweak panels, coachmarks, fake multi-site switchers,
  hardcoded marketing copy) as include/exclude-recommended so it doesn't reach Phase 2 as a
  requirement.

## A. Python backend extraction

### A1. Detect the framework

| Signal in code | Framework | Contract source |
|---|---|---|
| `Flask(__name__)`, `@app.route/@app.get` | Flask | handler `return`/`jsonify` |
| `FastAPI()`, `APIRouter`, `@router.get` | FastAPI | **pydantic request models + `response_model` classes — they ARE the contract; don't read handler returns** |
| `urls.py`, `urlpatterns` | Django | views + serializers |
| `st.` calls, no routes | Streamlit | callbacks/data fns are the contract |
| `dash.Dash`, `@app.callback` | Dash | callbacks are the contract |
| `web.Application()` | aiohttp | `add_routes` handlers |

```bash
grep -rnE '@(app|router|bp)\.(route|get|post|put|delete|websocket)|urlpatterns|@app\.callback' --include='*.py'
```

### A2. Route census
One table row per route: **app · method · path · params · auth (usually none) · response shape ·
consumed by which view**. Streaming endpoints (SSE/WebSocket) get extra columns: event types,
heartbeat cadence, error-in-stream contract, abort semantics, and whether it's POST-then-stream
(EventSource can't POST — the FE will be hand-parsing a fetch ReadableStream).

If the prototype is **running locally** and the user approves, `curl` each read-only GET once and
record the real JSON — never POST/mutating endpoints. **Never probe deployment URLs discovered in
docs/code without asking** — log them as a hazard instead (a public unauthenticated URL is a finding).

### A3. Data-source tracing
For every read/write, record: store · object (bucket/table/file) · fields · and the **equivalent
jt-api-v2 access pattern**:

| Prototype pattern | Look for | jt-api-v2 target |
|---|---|---|
| InfluxDB | `influxdb_client`, raw `requests.post(...api/v2/query)` | `influx2x.js` named config + `{{key}}` Flux templates |
| SQL | `sqlalchemy`, `psycopg`, `sqlite3` | existing RDS service wrappers |
| Dynamo/S3 | `boto3` | existing AWS service wrappers + TTL cache |
| **Local files** (`open()`, csv/yaml/json on disk) | `Path(...)`, `read_text` | must move to S3/config service — flag as ops dependency |
| **ML model artifacts** | train→publish→serve seams, versioned filenames, model stores | artifact lifecycle + version pinning is a reviewer decision — record which version the FE/config pins |
| External HTTP APIs | `requests.`, `httpx` | service wrapper + env-var base URL |

Watch for **read/write splits**: the API reading a config from one place (S3) while an editor
endpoint writes it elsewhere (local disk) means UI edits silently don't take effect — a finding.

### A4. Business logic (materiality rule)
Capture every derivation that **changes a number a user sees or a KPI gates on** — savings, kWh
factors, efficiency, bins, lookups, fallback constants — **verbatim with file:line**. Skip plumbing
(resampling, NaN coercion, parsing). These become the analytics service AND the parity-gate KPIs.
**This includes frontend math** (see B4) — client-side derivations are business logic too. Math lost
here is silently wrong forever.

### A5. Background work
`threading.Thread`, `schedule`, `APScheduler`, asyncio tasks, cron lines in `start.sh`/Dockerfile —
each needs a home decision (Sails cron/listener vs airflow DAG vs drop) surfaced to the reviewer.

```bash
grep -rnE 'threading\.Thread|APScheduler|schedule\.|asyncio\.create_task|@app\.on_event|lifespan' --include='*.py'
```
Watch for **import-time threads** (a `Thread(...).start()` at module top level filling a module-global
cache): it's background work AND a hazard (per-worker state).

### A6. Hazard sweep (always run — scan docs too)
```bash
grep -rnEi 'token|secret|password|api_key|authorization|verify.{0,4}(ssl|false)|http://' \
  --include='*.py' --include='*.sh' --include='*.md' --include='*.html' --include='*.js*' .
```
- **Hardcoded secrets/URLs/buckets** → inventory each, plan env-var replacement, flag exposed
  credentials **for rotation** in plan risks.
- **Hardcoded site IDs** — check code, not just config: asset maps, capacity constants, request
  defaults, FE config objects → multi-site via `:siteId` + per-site config.
- **No auth** (typical) → every endpoint goes behind `isAuthorized`.
- **Client-supplied filesystem paths in request bodies** (artifact_path, output paths — worst case an
  unauthenticated arbitrary-path write) → become server-side config keyed by `:siteId`.
- **f-string / concatenated queries** (esp. when a path param reaches the interpolation) → `{{key}}`
  parameterized templates.
- **TLS-verification toggles** (`verify=False`), wide-open CORS, global mutable state, file uploads,
  deployment URLs in docs, load-bearing error contracts (e.g. a 503 the FE branches on — preserve it).

## B. HTML/JS frontend extraction

### B1. Detect the flavor
Static HTML+vanilla JS · CDN React/Vue (incl. Babel-standalone transpiling `.jsx` in the browser) ·
bundled SPA · server-rendered templates (Jinja). Flavor determines where calls and state live.

### B2. Screen & state census
Every view/tab/modal, plus **loading / empty / error** states (prototypes usually lack them — the
plan must add them per `sj-ui-design-system`). Note state that must outlive navigation (views kept
mounted, in-flight streams) — that maps to NgRx state, not component lifetime.

### B3. Network census
```bash
grep -rnE 'fetch\(|axios|XMLHttpRequest|EventSource|WebSocket|setInterval|setTimeout' \
  --include='*.html' --include='*.js' --include='*.jsx' --include='*.ts' --include='*.tsx'
```
**Chase wrappers to call sites**: prototypes funnel calls through helpers (`api.js`, `window.__API`),
so grepping `fetch(` finds 2 helpers, not the real 8 calls — grep the helper names next. Every call:
method · path · trigger (button / mount / poll interval / stream) · consuming view. Plain polling
intervals carry over as RxJS `timer()` periods; **SSE/WebSocket does not** — it needs a streaming
adapter and a jt-api-v2 transport decision (see A2).

### B4. Charts, state, visuals
- Chart lib (Chart.js / ECharts / hand-drawn SVG/canvas) → series/axes → ECharts builder mapping.
- **Client-side derivations** (efficiency division with silent zero-fallbacks, cumulative savings,
  binning) → capture into the A4 business-logic table with file:line.
- Global vars, `localStorage`, URL params, DOM events → NgRx store/facade mapping. Note lost
  capabilities to restore (e.g. no URL routing today = no deep-linking).
- CSS custom props, inline colors, fonts → semantic-role table for `--n-*` token mapping; bespoke
  visuals with no PrimeNG equivalent (SVG schematics) are flagged design decisions.

## C. Reconciliation gate (must pass before Phase 2)

Diff the censuses: **every frontend network call maps to a backend route and vice versa**. Classify
orphans into one of three buckets — **dead code** (never-called helpers, superseded blocking/CSV
variants of streaming endpoints), **hidden consumer** (CLI, ops, another team), or **serving/infra
plumbing** (`/`, `/health`, static/UI file routes). Orphans are findings, not omissions.

Then confirm every screen, datum, formula (BE + FE), secret, scheduler, **and shipped data fixture**
(LUT CSVs, YAML profiles, lookup tables — runtime dependencies someone must own) appears in exactly
one inventory row.

Finally, ask the user the clarifying questions **now, not during plan synthesis** — 2–3 minimum;
more is fine when scope cuts, data-contract conflicts (read/write splits), and multi-site each
genuinely need an answer.
