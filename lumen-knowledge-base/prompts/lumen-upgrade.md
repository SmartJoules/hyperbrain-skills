# Single Build Prompt — Lumen Advanced Chat + Caching + UX Upgrade

Paste this as one prompt to develop the complete feature across **JouleTRACK** (Angular frontend) and **jt-api-v2** (Sails backend) in one go. It assumes the `lumen-knowledge-base`, `engineering-standards`, `agentic-engineering`, `jouletrack-angular`, `database-query-optimizer`, and `prompt-harness` skills are installed.

---

```
You are upgrading the existing Lumen AI chat assistant. Work across two repos on the
`labs-hyper` branch: JouleTRACK (Angular 17 frontend, src/app/app/lumen/) and jt-api-v2
(Sails + Waterline backend, api/{controllers,services}/lumen/).

FIRST load context — do NOT re-infer the architecture:
- Read the `lumen-knowledge-base` skill for the real Lumen architecture (backend agent +
  tools + caching, frontend module + SSE chat + theme) and known gaps.
- Use the precomputed context first (graphify GRAPH_REPORT, ai-context/*) per the
  `agentic-engineering` skill; read only the specific Lumen files you'll change.
- Confirm the live structure on `labs-hyper` before editing (files may have moved).

GOAL: make Lumen's chat advanced with better interaction, align its UX/UI to JouleTRACK,
and optimize it with cache layers so there are far fewer DB/Neptune/Influx calls.

Follow the `engineering-standards` skill on EVERY change (SOLID, right design pattern,
DRY/KISS, minimum diff, no leaks, no unhandled promises, error/loading/empty/partial-data
states, caching with eviction + invalidation, Kafka/Redis/connection rules). Match the
existing Lumen patterns and the repo idioms from `prompt-harness` (Sails: controllers thin,
logic in services, Waterline models; Angular: OnPush, takeUntil, ViewEncapsulation.None +
scoping class, no ::ng-deep). Do not invent a new architecture.

Decompose with `agentic-engineering`: plan first, then implement as scoped sub-tasks
(below), each touching only its listed files, verify per task, integrate, then a diff-only
review. Run independent tasks in parallel; sequence where a contract is shared.

=== BACKEND (jt-api-v2) ===

B1. Redis cache layer (fewer DB calls)
  - Add a singleton ioredis client (api/services/lumen/redis-cache.service.js) — NEVER
    per-request; retry + exponential backoff; handle error/reconnecting/end events;
    graceful degradation (if Redis down, fall through to compute, never crash).
  - Turn result-cache.service.js into a two-tier cache: L1 in-memory (keep as-is) + L2
    Redis. memoizeAsync checks L1 → L2 → compute; writes both with TTL. Keep the 45s
    default TTL for insights; expose per-key TTL.
  - Cache the Neptune Building projection (building-projection.service.js) in Redis with a
    longer TTL (e.g. 10 min) + explicit invalidate(siteId) hook for topology changes —
    this removes the cold-start Neptune round-trip on most chats.
  - Add a per-turn tool-result cache keyed by (site_id, tool, args, window) with short TTL
    (e.g. 30s) in tool-registry.service.js so repeated hvac_query/cohort_* within a
    conversation skip Influx. Bound it; never unbounded.
  - All caches: defined eviction (TTL), invalidation on the corresponding write, graceful
    degradation. Document keys + TTLs.

B2. Conversation persistence
  - Add Waterline models lumen_conversation (id, site_id, user_id, title, createdAt) and
    lumen_message (id, conversation_id, role, text, cards json, meta json, createdAt).
  - chat-stream.js: accept optional conversation_id; persist the user message before
    streaming and the assistant message (+ cards/meta) after the stream completes (after
    the verify gate). Don't block the stream on the write — fire-and-handle errors.
  - Add GET /v1/conversations (list) and GET /v1/conversations/:id (messages). Apply the
    same auth/policy as the other lumen routes; do NOT touch config/policies.js or
    routes.js wiring without flagging it for review.

B3. Rate limiting on the expensive endpoint
  - Token-bucket limiter per (user, site) on POST /v1/chat/stream (back it with the Redis
    client). On limit, return a clean 429 with retry-after; never 500. Make limits config
    via env.

B4. Token-level streaming
  - In bedrock-agent.service.js, emit `delta` events at token/sentence granularity as the
    Converse stream produces them (instead of one prose blob), preserving the verify-gate:
    buffer for verification, then stream the verified/corrected text live. Keep res.flush()
    after each write.

B5. Verify/test
  - Reuse test/lumen/eval-invariants.js + test/unit/lumen/agent-tools-grounding.test.js;
    add tests for the cache layers (hit/miss/expiry/Redis-down degradation), conversation
    persistence, and rate limiting. Note: husky pre-commit may need `npm run prepare`.

=== FRONTEND (JouleTRACK) ===

F1. Conversation history UI
  - lumen.service.ts: add typed calls to GET /v1/conversations and /v1/conversations/:id;
    pass conversation_id on POST /v1/chat/stream. Keep the fetch+getReader SSE pattern and
    AbortController cleanup; keep manual auth header.
  - lumen-chat.component.ts (OnPush): a conversation list/switcher; load prior messages;
    stop / regenerate / edit-and-resend actions. Persist beyond the in-memory last-8.

F2. UX/UI alignment to JouleTRACK
  - Reconcile the theme with `design-knowledge-base`: keep Flame (#CA3604) for metric
    numbers, but use JouleTRACK --n-* tokens for chrome/buttons/cards/headers so Lumen
    reads as one product. Update _lumen-tokens.scss / lumen-theme.scss; keep everything
    scoped under .lumen-root (no global leak), no ::ng-deep.
  - Add loading SKELETONS for floor-stack, floor-detail, and asset-panel (no white space
    before model loads). Add explicit empty, error, and partial-data states everywhere a
    read can fail.
  - Suggested-prompt chips in the chat seeded from the operator worklist; make citations in
    answers clickable to open the asset-panel for that asset.

F3. Fix the known leaks/edges
  - Cancel the asset-panel deep-diagnostics request when the panel closes (hook reload$ to
    the close/destroy). Guard localStorage token atob() (handle missing/malformed token).
  - Normalize FloorConsumption shape handling (prefer server-side normalization in B*).

F4. Surface ways to interact with Lumen
  - A floating "Ask Lumen" dock available across JouleTRACK pages (gated by the Lumen
    policy), "Ask Lumen about this asset" entry from existing dashboards, and URL deep-link
    to a prefilled question. Reuse the existing scoped streamer callback.

=== OUTPUT (per the prompt-harness / engineering-ai-assistant output format) ===
1. Requirement understanding + detected current Lumen state
2. Assumptions (flag any risky one for confirmation BEFORE writing destructive/migration code)
3. Discovered context (files + contracts touched)
4. Execution plan (the sub-tasks above as a dependency-ordered list)
5. Files to create/modify per repo
6. Full code (matching existing Lumen + repo conventions)
7. API endpoints (new + changed)
8. Example requests / responses (incl. SSE event samples)
9. Test cases (success + failure: cache miss/hit/expiry/Redis-down, 429, persistence)
10. Deployment notes (new env vars for Redis + rate limits; migration for the two models)
11. Risks / follow-ups

CONSTRAINTS: minimum diff; do NOT modify routes.js/policies.js/env/package.json/compose
without explicit confirmation; require confirmation before running any DB migration or
destructive op; never hardcode creds (env only); never log secrets. Preserve the existing
verify-gate behavior and SSE flush semantics.
```

---

## Why this is structured this way

- **Backend-first cache contract** (B1) is the dependency for the rest — it's the biggest "fewer DB calls" win (Redis L2 + Building-projection cache + per-turn tool cache all cut Neptune/Influx round-trips).
- **Conversation persistence** (B2) defines the contract the frontend (F1) consumes — sequence them.
- **UX alignment + skeletons + leak fixes** (F2/F3) are independent and parallelizable.
- Every task names its files so a scoped sub-agent gets only the minimal context (token-efficient per `agentic-engineering`).
- The output format and constraints come straight from `engineering-standards` + `prompt-harness`, so the generated work is review-ready.
