---
name: lumen-knowledge-base
description: Knowledge base for the Lumen feature — the AI chat assistant for buildings/HVAC in JouleTRACK (Angular frontend) and jt-api-v2 (Sails backend, AWS Bedrock agent + Neptune graph + InfluxDB). Use when working on Lumen: the chat (SSE streaming), the agent tool-registry, insights/comfort/energy/topology endpoints, caching, or the Lumen Angular module (floor-stack, asset-panel, floor-detail, ask-lumen). Use for any Lumen feature work, chat-system improvements, cache optimization, or UX alignment on the `labs-hyper` branch.
---

# Lumen Knowledge Base

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Real architecture of the Lumen AI chat assistant (frontend + backend) so changes build on the actual code
**Version:** 1.0.0
**Source:** `labs-hyper` branch of JouleTRACK + jt-api-v2 (as of June 2026)

---

## 🎯 When to Use

Any Lumen work: chat/SSE, the Bedrock agent + tools, insights endpoints, caching, or the Angular Lumen module. Build on the real structure below — don't re-infer it. Enforce [[engineering-standards]]; for big changes use [[agentic-engineering]]; for query perf use [[database-query-optimizer]].

---

## 1. What Lumen Is

An **AI chat assistant for building operators** that answers HVAC/IoT questions ("why is zone 6F hot", "how many pumps above 40Hz", "what's the chiller doing") by grounding answers in: live **topology graph** (Neptune/Brick ontology), **telemetry** (InfluxDB), and physical models (comfort bands, energy efficiency). It classifies each question's complexity, sizes the LLM tier to match (cost ladder), calls typed tools for evidence, **verifies every concrete claim** against the grounding, then **streams** the answer over SSE.

## 2. Backend (jt-api-v2, Sails + Waterline) — `api/{controllers,services}/lumen/`

**Request flow:** `POST /v1/chat/stream` → `chat-stream.js` (thin SSE controller) → `projectSite()` builds the `Building` graph → `buildRegistry(building)` → `chatStream()` async generator in `bedrock-agent.service.js` → SSE events (`tool`, `card`, `delta`, `citation`, `meta`, `followups`, `verify`, `correction`, `done`). **Critical:** `res.flush()` after every `res.write()` (gzip would batch otherwise); headers include `X-Accel-Buffering: no`.

**AI stack (AWS Bedrock Converse, cost ladder):** INTENT/CHEAP = Qwen 32B; REASONING = Claude Haiku 4.5; HARD/SYNTHESIS = Qwen 235B; VERIFY = Claude Sonnet 4.6; ESCALATE = Opus 4.8. Prompt caching on Anthropic models (system + snapshot). Creds via `bedrock-creds.service.js` (optional dedicated `BEDROCK_AWS_*`, else instance role). Qwen in `eu-north-1` via inference-profile ARNs, Claude in `us-west-2`. Transient errors (Throttling/ServiceUnavailable/ModelTimeout) retried with exp backoff.

**RAG/embeddings:** `embedder.service.js` = Bedrock Titan Embed v2 (1024-dim), used to semantically resolve which point is "room temp" vs "setpoint" (ontology under-types temps). In-memory text→embedding cache.

**Tool registry** (`tool-registry.service.js`): graph (`graph_match`, `graph_search_label`, `graph_feeds`, `graph_explain`), HVAC telemetry (`hvac_query`, `hvac_kw`, `hvac_describe_fields`), energy (`energy_summary`, `param_stats`), inspection (`inspect_node`), cohort (`cohort_metric`, `cohort_rank`, `cohort_capability`, `cohort_anomaly`, `cohort_join`). Tool results truncated to `MAX_TOOL_RESULT_CHARS=1500`; `TOOL_TIMEOUT_MS=45s`; `MAX_PARALLEL_TOOLS_PER_TURN=6`; `MAX_TURNS=6`.

**Data sources:** Neptune (Brick graph per site, SigV4, VPC-private, read-only — roles derived from FEEDS/COMMANDS edges, never names); InfluxDB `components`+`device` measurements (telemetry/kWh) and a separate `iot_influxdb` bucket (controller health); Postgres/Waterline (site metadata); DynamoDB (context). Stale = `last_value==null` or `last_seen_min_ago>10`.

**Caching** (`result-cache.service.js`): in-memory `Map(key→{value,expiresAt})` + in-flight `Map(key→Promise)` dedup. `memoizeAsync(key, ttlMs, fn)`. **Default TTL 45s**, sweep every 5 min (`unref`'d timer), never caches failures. Caches **read endpoints only** (insights/overview) — NOT chat/LLM/tool results. `building-projection.service.js` separately promise-caches the Neptune→Building projection per site.

**Endpoints:** `POST /v1/chat/stream`, `POST /v1/chat/feedback`, `GET /v1/sites`, `GET /v1/overview`, `GET /v1/insights/{overview,comfort,energy,floor_consumption,data_quality,plant_topology,asset_profile}`, `GET /v1/controllers/:siteId`, `GET /v1/components/:siteId/:assetId/{commands,assessment,survivability}`, `GET /v1/topology`, `GET /v1/widgets/operator`.

## 3. Frontend (JouleTRACK Angular) — `src/app/app/lumen/`

**Surfaces:** floor-stack (ranked floors color-washed by comfort + kWh), floor-detail (comfort/plant/infra tabs, attention insights, energy strip, DQ chart), asset-panel (drill-in: chips, command-health, param table, connected-equipment SVG graph, embedded scoped chat), lumen-chat / ask-lumen (building-wide or asset-scoped chat).

**SSE consumption** (`lumen.service.ts:chatStream()`): native `fetch()` + `response.body.getReader()` (HttpClient can't stream), split frames on `\n\n`, JSON-parse `data:` lines → normalized `ChatEvent` → RxJS Observable. **`AbortController`** aborts the fetch on unsubscribe. Auth header set manually (fetch bypasses interceptors): `Authorization: bearer ${atob(localStorage token)}`.

**Chat UX** (`lumen-chat.component.ts`, OnPush): prose arrives as `delta` blobs, revealed via **typewriter** (~22ms, chunk scales to backlog, runs **outside Angular zone**); tool chips, grounded cards, cost meta footer, followups; states: streaming (orb + gerunds + elapsed), tool-running, error+retry, empty, stopped, 90s timeout. `ask-lumen.component.ts` is the lighter scoped variant (owns last-8-turn history, `Subject<void>` teardown).

**Patterns:** OnPush everywhere; `takeUntil(destroy$)`; asset-panel uses `ViewEncapsulation.None` (scoped, justified — no `::ng-deep`); read endpoints `catchError(()=>of({}))`; boot via `/v1/insights/overview` with `forkJoin` fallback.

**Theme** (`_lumen-tokens.scss`, `lumen-theme.scss`): Work Sans, Thunder `#072B31` (matches JouleTRACK), Frost `#F5F5F5` bg, **Flame `#CA3604` for every numeric** (Lumen accent — diverges from JouleTRACK's orange `#FF9900`), custom `--crit/--warn/--ok/--info`, dark theme via `:host-context(.lumen-root[data-theme='dark'])`. All scoped under `.lumen-root`; colors are CSS vars (no hardcodes).

## 4. Known Gaps (improvement targets)

Backend: in-memory cache only (no Redis → no cross-instance sharing); Neptune round-trip dominates cold start; tool results truncated at 1500 chars; no rate-limiting on the expensive `/chat/stream`; no Prometheus/StatsD metrics (only `meta` event + `/tmp/lumen-trace.jsonl`); Opus escalation has no repeat-guard (cost risk).
Frontend: no initial loading skeleton (floors render before model); asset-panel deep-diagnostics request not cancelled on close; chat history truncated to 1200 chars post-stream; `localStorage` token `atob()` can fail silently; `FloorConsumption` shape inconsistent (array vs object) — normalize server-side.

---

## 5. Improvement Design — Advanced Chat + Caching + UX (proposed)

See the companion **single build prompt**: `prompts/lumen-upgrade.md` in this skill folder. Summary of the design it implements:

**Chat (advanced + better interaction):** token-level streaming (emit `delta` per token, drop the client typewriter or feed it real tokens); **persisted conversations** (Waterline `lumen_conversation`/`lumen_message` so history survives reload, not just last-8 in memory); **stop/regenerate/edit-and-resend**; **suggested-prompt chips** seeded from operator worklist; **scoped chat from any asset/floor** (already partial); **citations clickable** to open the asset-panel; **rate-limit** `/chat/stream` per user/site (token bucket) with graceful 429 in UI.

**UX/UI aligned to JouleTRACK:** reconcile the Lumen accent — keep Flame for metrics but adopt JouleTRACK `--n-*` tokens for chrome/buttons/cards so Lumen reads as one product (see [[design-knowledge-base]]); add loading **skeletons** for floor-stack/detail/asset-panel; explicit empty + error + partial-data states everywhere; cancel in-flight asset-panel requests on close (fix the leak).

**Cache layers (fewer DB calls):**
1. **Redis layer** behind `result-cache` (keep the in-memory L1, add Redis L2: singleton ioredis, TTL/eviction, graceful degradation if down) so insights/overview are shared across instances and survive restarts — invalidate on the relevant write.
2. **Cache the Building projection** in Redis (Neptune is the cold-start bottleneck) with a longer TTL + explicit invalidation when topology changes.
3. **Per-turn tool-result cache** keyed by (site, tool, args, window) with short TTL — repeated `hvac_query`/`cohort_*` within a conversation hit cache, cutting Influx calls.
4. **Embedding cache** persisted (Redis/Postgres) instead of per-process memory.
All caches: defined eviction (TTL/LRU/max-size), invalidation on write, graceful degradation — per [[engineering-standards]].

**Ways to interact with Lumen (surface it more):** the floating Ask-Lumen dock available across JouleTRACK pages; right-click/drill "Ask Lumen about this asset" from existing dashboards; deep-link a question via URL; operator-worklist items → one-click "explain this".
