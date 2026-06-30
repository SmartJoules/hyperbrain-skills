# Worked example — CPO Dashboard → DeJoule

This is the gold-standard reference for the depth, structure, and tone the skill should produce. It
ports a standalone CPO Dashboard prototype (single-file Flask backend + CDN React UI) into JouleTRACK +
jt-api-v2. Use it as the template; produce equivalent depth for any new prototype.

## What made it a good plan

- **Grounded in the real repos** — every target claim (action shape, `dashboard.service.fetchSavings`,
  the `device_component` influx config / named configs, `--n-*` tokens, `EchartsWrapperComponent`,
  `@ngrx/component-store` as the new-feature flavor) was verified via Morpheus, not assumed.
- **Brainstorm outcome up front (Phase 2.5)** — before writing, the build approach was agreed with the
  user given the evidence: ship the read-only outcome views first (Overview → What-CPO-Did → Schedule →
  Plant Performance), reuse the existing savings/baseline, and defer the Simulator (it's pure
  client-side mock math with no backend). The plan's §1 states this in one line.
- **Diagrams (§2) — three Mermaid diagrams** that render and use real names:
  - *Architecture*: prototype → new `cpo` domain (actions + services) → `device_component` influx /
    S3 config (both **reused** infra); JouleTRACK `cpo-dashboard` module → API.
  - *Request/data sequence*: UI → `isAuthorized` → `cpo/fetch-telemetry` → `cpo.queries.service` →
    `influx.public.runQuery` → reshaped `{ data, err }` → `CpoStore`/facade → presenter, with the
    `timer(0,30s)` polling loop.
  - *Work-item dependency DAG*: doubles as the parallel-build map (below).
- **Backend: a `cpo` domain** mirroring `dashboard`/`baseline`:
  - `cpo.queries.service.js` — Flux built on the existing `influx/enterprise` client; the IOT influx
    (`cpa_logs_30_days`, `cpa-performance-analysis`) as a **named config** (flagged risk: access
    unproven).
  - `cpo.config.service.js` — S3 YAML + ontology loaders with TTL cache.
  - `cpo.analytics.service.js` — pure reshaping (energy/SEC bins, behaviour state machine, calendar).
  - **Endpoint → action map** table (`/api/telemetry/<site>` → `cpo/fetch-telemetry`, …), and a
    **reuse recommendation**: savings reuses `dashboard.service.fetchSavings` rather than re-porting.
- **Frontend: a `cpo-dashboard/` module** mirroring `dashboardv2` / `digital-twin` — lazy module,
  feature-local structure (`containers/`, `presenters/`, `services/`, `models/`) where the feature
  owns those concerns, container with PrimeNG tabs + range picker, real API service (+ mock/testing
  implementation for contract-first FE work), `CpoStore extends ComponentStore` + facade, typed
  transformers, RxJS `timer`+`switchMap`+`shareReplay` polling (replacing `setInterval(30000)`),
  ECharts builders replacing hand-drawn SVG, CSS component styles, and a token mapping from the
  prototype's `--ink-*`/`--brand` onto `--n-*` (flagging the missing Flame metric token).
- **Cross-repo blast radius (§7) checked, not assumed** — Morpheus (`kg_impact`/lineage) confirmed the
  feature reads stores that already exist; the build target was **JouleTRACK + jt-api-v2 only**, stated
  explicitly. The one cross-cutting dependency — read access to the IOT influx buckets from jt-api-v2 —
  was raised as a flagged risk/owner question, exactly the kind of thing that, on another prototype,
  would surface as a real change in an ingestion repo (a not-yet-emitted field) or a DB migration.
- **Moderate TDD (§9)** — TDD only the logic core + the contract: the savings/SEC math, the tptr×wbt
  binning, the FE transformers, and the API response shapes; ~60–70 % on the logic layer, light smoke
  coverage on glue/presenters. Not 80 %-everywhere.
- **Parallel, dependency-driven build (§11)** — work items marked independent vs linked; independent
  tracks (e.g. each read endpoint; FE widgets against the mock) run in parallel via git worktrees +
  subagents; linked items (an endpoint ↔ the adapter consuming it) integrate and are tested together at
  the contract seam. Layered testing: unit/TDD per item → integration per cluster → phase acceptance →
  parity gate.
- **Independent review (§14)** — an architecture-review subagent with Morpheus access re-checked
  contract coherence, reuse claims, the cross-repo blast radius, and the independent/linked split before
  delivery; the "Review notes" section records what it caught and how the plan changed.
- **Phasing for fast delivery** — backend foundation → read endpoints ∥ FE scaffold against mock →
  wire real API + remaining views → polish (Simulator deferred to its own track).
- **Verification** — Sails unit tests per logic-bearing action, Angular transformer/presenter specs,
  and a **parity gate** (avoided kWh, ₹ saved, SEC, command-success % match the prototype within
  rounding before retiring Flask).

### Diagrams as produced (illustrative)

Architecture (reused infra dashed, new nodes filled):

```
flowchart LR
  P[Flask server.py + *.jsx]:::proto
  subgraph be[jt-api-v2 — api/controllers/cpo/]
    A[fetch-telemetry / energy / savings / schedule …]:::new --> Q[cpo.queries.service]:::new
    A --> CFG[cpo.config.service]:::new
    A --> AN[cpo.analytics.service]:::new
  end
  subgraph fe[JouleTRACK — cpo-dashboard module]
    C[CpoShell container] --> W[OnPush widgets + ECharts]
    C --> ST[CpoStore + facade]:::new
  end
  Q --> INF[(device_component influx)]:::reuse
  Q --> IOT[(cpa_logs / perf-analysis influx — named config)]:::risk
  CFG --> S3[(cpa-conf-bucket S3)]:::reuse
  ST -->|HTTP /m2/site/:siteId/cpo/*| A
  classDef new fill:#28939D,color:#fff; classDef reuse stroke-dasharray:4 4; classDef risk stroke:#CA3604;
```

Work-item dependency DAG (parallel-build map):

```
flowchart LR
  F0[BE foundation: influx client + auth + cpo skeleton]:::linked
  F0 --> T[fetch-telemetry]:::indep
  F0 --> E[fetch-energy]:::indep
  F0 --> SV[fetch-savings reuse]:::indep
  F0 --> SC[fetch-schedule + config loader]:::indep
  FE0[FE scaffold: module + store + mock adapter]:::linked
  FE0 --> OV[Overview widgets]:::indep
  FE0 --> SCH[Schedule view]:::indep
  T --> INTt[integrate: Overview ↔ telemetry/energy]:::linked
  E --> INTt
  OV --> INTt
  classDef indep fill:#e6f7f9; classDef linked fill:#fde8df;
```

## Reusable lessons baked into the skill

1. Search for an existing service before proposing a new one (savings was already implemented).
2. Convert every raw query into parameterized `{{key}}` templates (security + correctness).
3. Extra data instances become **named env configs**, never hardcoded.
4. Replace global state / DOM events with NgRx + Facade; replace timers with RxJS.
5. Map design by **semantic role** onto real `--n-*` tokens; flag gaps (e.g. metric color) for review.
6. Lock the data contract against a mock adapter before wiring the real API.
7. **Brainstorm the approach with the user once you have evidence** — scope, reuse, and the
   independent/linked split — before writing a line of plan.
8. **Show the system, don't just describe it** — architecture + sequence + a dependency DAG, in Mermaid.
9. **TDD where it pays** (logic + contract), not everywhere — keep the bar pragmatic.
10. **Plan for parallelism**: mark independent vs linked work, recommend worktrees + subagents for the
    independent tracks, and test linked items together at their seam.
11. **Have the plan reviewed before delivery** by an independent, Morpheus-backed subagent; record what
    changed.
12. **Check the cross-repo blast radius** (`kg_impact`/lineage) — a feature is incomplete if a repo it
    depends on isn't changed. Every store/field the prototype reads must already exist or have an
    owning-repo change planned (a new ingested field, a DB migration, a model input). If it's just the
    two primary repos, **say so explicitly** — never leave it implicit.

> The full original CPO plan document (`cpo-dashboard-dejoule-compliance.md`) is the long-form version
> of this example; this summary captures the structure to reproduce.
