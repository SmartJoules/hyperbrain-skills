# Plan output template

The skill produces ONE markdown document with the sections below, in this order. Code excerpts are
JSON blocks; diagrams are **Mermaid** fenced blocks. Keep it concrete and grounded in Morpheus
findings — no hand-waving.

---

## §Analysis (internal — feeds the plan, not necessarily a section)
- **UI inventory**: screens, components, states, interactions.
- **API inventory**: method, path, request, response shape (the contract).
- **Data inventory**: shapes, granularity, derived values, business logic/math.
- **Visual inventory**: colors/fonts/spacing + the semantic role of each.

---

## 1. Overview
- Feature name + one-paragraph summary of what the prototype does.
- Input artifact type (working app / mockup / screenshots / code / spec) and what it covers.
- Target: JouleTRACK feature module + jt-api-v2 actions (+ any supporting repos — see §7).
- One-line **brainstorm outcome** (from Phase 2.5): the agreed scope, MVP cut, and big forks resolved.

## 2. Architecture & flow diagrams
Three **Mermaid** diagrams (must render; reference real component/store names via `resolve`):

- **2.1 Architecture** — `flowchart`: the prototype's source(s) → the new jt-api-v2 domain
  (actions + services) → each data store (influx buckets / RDS / Dynamo / S3); the JouleTRACK feature
  module → API; **and any other repo that must change (§7)** — edge/ingestion, pipeline, model. Mark
  **reused** vs **new** vs **other-repo** nodes.
- **2.2 Request / data-flow sequence** — `sequenceDiagram`: a representative live request
  (UI → `isAuthorized` → action → service → store → reshaped response → store/facade → presenter),
  including the polling loop.
- **2.3 Work-item dependency DAG** — `flowchart`: nodes = buildable+testable units, edges =
  dependencies. **This is the parallel-build map for §11** — colour/tag each node independent vs linked;
  cross-repo items (§7) appear here too, tagged with their owning repo.

```
flowchart LR
  subgraph proto[Prototype]
    P[server.py + *.jsx]
  end
  subgraph be[jt-api-v2 — api/controllers/<feature>/]
    A[actions]:::new --> S[services]:::new
  end
  subgraph fe[JouleTRACK — <feature> module]
    C[container] --> W[presenters/widgets]
    C --> ST[ComponentStore + facade]:::new
  end
  subgraph other[supporting repos — §7]
    ING[ingestion: new field]:::other
  end
  S --> INF[(device_component influx)]:::reuse
  S --> S3[(S3 config)]:::reuse
  ING --> INF
  ST -->|HTTP| A
  classDef new fill:#28939D,color:#fff;
  classDef reuse stroke-dasharray:4 4;
  classDef other fill:#fde8df;
```

## 3. Current → Target gap

| Concern | Prototype today | DeJoule target |
|---|---|---|
| Frontend framework | … | Angular 15, AOT, strict TS |
| UI components | … | PrimeNG + shared components, `--n-*` tokens |
| Charts | … | Apache ECharts via `EchartsWrapperComponent` |
| State | … | NgRx (flavor per repo) + Facade |
| Async/polling | … | RxJS `timer()`+`switchMap`+`shareReplay` |
| Backend | … | Sails actions + influx/RDS access |
| Auth / multi-site | … | `isAuthorized` + `:siteId` |
| Tests | … | Sails unit + Angular specs (moderate TDD — §9) |

## 4. Backend plan (jt-api-v2)
- **Domain** to create (e.g. `api/controllers/<feature>/`) mirroring an existing domain.
- **Endpoint → action map** table: prototype API → new Sails action (or **reuse** existing service,
  with Morpheus evidence).
- **Services**: queries service (Flux/SQL with `{{key}}` templating), config/loader service, analytics
  service (pure reshaping). One responsibility per file; services < 800 lines.
- **DB usage**: which stores (influx buckets / RDS tables / Dynamo) and how, inferred from repo code.
- **Auth & routes**: `isAuthorized`, `_userMeta`, `:siteId`, `config/routes.js` entries.
- **Reuse recommendations** (for reviewer): "X already exists — reuse vs extend vs new."

## 5. Frontend plan (JouleTRACK)
- **Module location** following the *real* repo structure (confirm from a recent feature).
- **Structure**: mirror the chosen recent feature's actual shape — typically module + routing files,
  and where the feature warrants it, feature-local `containers/`, `presenters/`, `services/`, and
  `models/`. Do **not** invent a `/ports` folder unless the mirrored feature for this work uses one.
- **Routing/shell**: lazy module + container (tabs/sections), range picker, etc.
- **Data-access**: API service (+ mock/testing implementation when the mirrored feature uses one),
  NgRx store/facade (flavor per repo), typed transformers, RxJS polling (no `setInterval`).
- **Presenters**: `OnPush` components per card/section, `@Input()`/`@Output()`.
- **Charts**: ECharts builder classes via `EchartsWrapperComponent`.
- **Design alignment** (see `DESIGN.md` + `sj-ui-design-system`):
  - Token mapping table: prototype visual role → real `--n-*` token.
  - Font mapping (Work Sans), px→rem, BEM CSS.
  - Component substitution table: hand-rolled → PrimeNG/shared component.
  - **Flagged design gaps** (e.g. metric/Flame token) as reviewer decisions.

## 6. DB usage summary
One table: store → object (bucket/table) → fields used → read/write → **confidence/risk**. List
unproven data as explicit risks (structural analysis only).

## 7. Cross-repo changes (supporting repos beyond JouleTRACK + jt-api-v2)
**A feature is incomplete if a repo it depends on isn't changed.** DeJoule is ~50 linked repos across
edge → transport → pipeline → stores → intelligence → backend → frontend. Using Morpheus, determine
the **full blast radius** and list **every other active repo** that must change for this prototype to
work end-to-end:

- `architecture_brief` — store catalog: who **reads/writes** each store.
- `kg_impact(target)` — blast radius of changing a store / table / measurement / service.
- `kg_trace` / lineage — **producers & consumers** of a bucket / table / topic, with file:line.
- `check_fit(source, action, target)` — validate every NEW cross-service dataflow.

**Typical cross-repo needs:** a telemetry field / measurement the prototype reads that **isn't emitted
yet** (an edge/ingestion repo — e.g. `iot-application`, `component-null-data-ingestor`,
`py-mqtt-data-flow` — must produce it); a new **RDS/Mongo column or table + migration** owned by
another service; a new **Dynamo key** or **MQTT topic**; an **airflow DAG / ETL** change
(`sj-airflow`, `ETL_*`); a **CPA/CPO/CPC model** input.

For each affected repo, a **proportionate change-spec** (what's needed to action + estimate — not a
full design):

| Repo | Layer | Change needed | Why (feature need) | Evidence (Morpheus) | Owner / team | Blocks feature? | Rough effort |
|---|---|---|---|---|---|---|---|
| … | edge / pipeline / stores / intelligence | e.g. new column `x` on table `y` (+ migration) | … | `kg_trace`/`kg_impact` + file:line | … | yes/no | … |

**Rules:**
- **Active repos only.** `JouleTrack-API` is **retired** — never plan changes there; route the change to
  whichever active repo owns the artifact.
- If the data the prototype reads **does not exist yet** in any store, the producing repo's change is a
  **hard dependency / blocker** — it appears here, as a node in the §2.3 DAG, in §12, and in §13 risks.
- Cross-repo work is often owned by **other teams** — capture owner + whether it blocks; don't assume
  it's ours to build in a worktree. Flag external dependencies as schedule risks.
- Schema changes: name the **migration mechanism** and flag backward-compat / rollout order.
- **If the blast radius is genuinely just the two primary repos, state that explicitly**
  ("Blast radius: JouleTRACK + jt-api-v2 only — verified via `kg_impact`"). Never leave it implicit.

## 8. API summary
- Total count of new/changed actions.
- List each: action → consumed by which frontend view.

## 9. Testing plan (moderate TDD)
TDD where it pays; light elsewhere — **not** aggressive 80 %-everywhere coverage.
- **TDD the logic core + the contract (red→green→refactor):** savings/derivation math, binning/
  aggregation, the FE transformers (prototype reshaping logic), and the **API response shapes** the FE
  consumes. Write these tests first. **Target ~60–70 % on the logic layer.**
- **Light coverage elsewhere:** glue, wiring, and presentational components get a smoke/spec, not full
  TDD.
- **Backend**: Sails unit tests per logic-bearing action/service (mock the data client).
- **Frontend**: transformer + key-presenter specs; assert `OnPush`, `trackBy`, async-pipe/`takeUntil`
  teardown (no `setInterval`; charts `dispose` on destroy).
- **Cross-repo (§7):** name how each cross-repo change is verified (migration test, ingestion field
  appears in the store, contract test against the new data) — its acceptance gates the dependent work.
- **Layered to the build (see §11):** unit/TDD per work item (parallel) → integration per linked
  cluster at its contract seam → phase acceptance/E2E → **parity gate**.
- **Parity gate**: named KPIs match the prototype within rounding before retiring it.

## 10. Ops & rollout
- **Env vars / configs to add**: every secret and hardcoded URL from the prototype → its env var or
  named influx config; exposed credentials flagged **for rotation**.
- **Infra dependencies**: S3 buckets/IAM, local prototype files that must move to S3/config service.
- **Background jobs**: proposed home per job (airflow DAG / dedicated microservice / Kafka consumer — jt-api-v2 has no cron; see backend ref).
- **Cross-repo rollout order (§7):** deploy producing/migration changes **before** the consumers that
  depend on them; note the sequencing.
- **Registration**: JouleTRACK nav/menu entry, role/permission wiring, `config/routes.js` entries.
- **Prototype retirement**: parity gate passes → traffic moves → decommission the prototype host.
- *(Deployment to a test environment is intentionally out of scope for now — add when the env details
  are provided.)*

## 11. Phasing, parallel build & dependency graph
Incremental, dependency-driven delivery — **not waterfall**. Decompose into work items with explicit
dependencies (the §2.3 DAG), then:
- **Independent vs linked table** — for each work item: independent (build/test in isolation, in
  parallel) or linked (must integrate + be tested together), with its dependencies. Include cross-repo
  items (§7) and mark which are **external** (other-team owned).

  | Work item | Track / repo | Independent / Linked | Depends on | Tested with |
  |---|---|---|---|---|
  | … | BE / FE / other-repo | … | … | unit / integration-with-X |

- **Parallel execution recommendation:** run independent tracks in parallel via **git worktrees +
  subagents** (one worktree+agent per track; `superpowers:using-git-worktrees`,
  `superpowers:subagent-driven-development`). Linked items integrate and are tested together at their
  **contract seam** (the API shape ↔ the FE adapter). Cross-repo changes that block dependents go
  **first**; external-team items are tracked as dependencies, not parallel tracks we own.
- **Phases** (each independently verifiable), e.g. cross-repo/producer changes → BE foundation → read
  endpoints ∥ FE scaffold+mock → wire real API + remaining views → polish. State which work items run
  in parallel within each phase.

## 12. Effort estimate
Per phase, in **person-days**, assuming **1 FE + 1 BE in parallel** (state any other assumptions; call
out cross-repo work that needs another team/owner). Realistic but delivery-focused. Include a total and
the critical path (note where parallelism via worktrees/subagents shortens wall-clock, and where an
external cross-repo dependency extends it).

| Phase | BE (days) | FE (days) | Other-repo (days) | Notes |
|---|---|---|---|---|
| … | … | … | … | … |

## 13. Open decisions for the reviewer
Every recommendation needing a human call: reuse-vs-build, design-token gaps, NgRx flavor, data risks,
background-job homes, **cross-repo changes + their owning teams**, scope cuts.

## 14. Review notes — what changed
Output of **Phase 4** (independent architecture-review subagent, Morpheus-backed). Short:
- what the review checked (rubric);
- issues it caught (contract gaps, missing risks, **missed cross-repo dependency**, unsound parallel
  split, invented design, weak evidence, unrealistic effort);
- how the plan was revised in response. The delivered plan is the post-review version.
