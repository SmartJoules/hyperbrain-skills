---
name: proto-to-dejoule
description: >
  Use when an Intelligence-team prototype or MVP (HTML/CSS mockup, Flask/FastAPI/Streamlit/Dash app,
  screenshots, Figma, a code folder, or a text spec) needs to be brought into the DeJoule production
  stack, when someone says "bring this into JouleTRACK / jt-api-v2", "productionize this MVP",
  "plan this for DeJoule", or types /proto-to-dejoule.
origin: DeJoule
---

# Proto → DeJoule Implementation Planner

Turns any prototype handed over by the Intelligence team into a **complete, review-ready plan** to
build that feature into DeJoule's production repos:

- **JouleTRACK** — Angular 15 frontend (`SmartJoules/JouleTRACK`, master) — primary build target
- **jt-api-v2** — Sails.js backend (`SmartJoules/jt-api-v2`) — primary build target
- **…plus any other active repo the feature needs.** DeJoule is ~50 linked repos (edge → transport →
  pipeline → stores → intelligence → backend → frontend). A feature often requires supporting changes
  elsewhere — a new DB column/table, a new ingested telemetry field, an MQTT topic, an ETL/airflow DAG,
  a model input. **A feature is incomplete if a repo it depends on isn't changed**, so the plan must
  cover those too (see plan-template §7). Morpheus knows all repos — use it to find the blast radius.

The output is **one markdown plan** following `references/plan-template.md`.

> **This skill PLANS. It does not write production code.** It recommends; the human approves
> reuse-vs-build and design decisions at review time. The plan *describes* the parallel build, the
> TDD approach, and the rollout — a human (or a separate session) executes them.

---

## Prerequisites (check first)

1. **Morpheus MCP is the primary way to ground claims in the real repos.** Start with the
   orientation tools (available since 2026-06-10), then drill down:
   - `architecture_brief` — platform map, store catalog (who reads/writes each store), tool routing.
   - `resolve(name)` — canonical entity names (sites, buckets, measurements, services). Never put
     an unresolved name in the plan.
   - `how_do_i(task)` — the **live** canonical pattern + verified exemplar (sails-action,
     kafka-consumer, influx-access, background-job, realtime-push, new-frontend-feature…). Prefer
     it over this skill's static reference files when they disagree — live wins.
   - `check_fit(source, action, target)` — validate every NEW dataflow the plan proposes;
     violations go in the plan with the sanctioned alternative.
   - `kg_query` / `kg_impact` / `kg_trace` / lineage edges — who already produces/consumes an
     artifact, table, bucket or measurement (reuse precedent + **cross-repo blast radius**), with
     file:line evidence.
   - `code_investigate(question)` — multi-tool search for "does an existing service already do this".
   - `code_search` / `code_read` / `code_answer` — file-level grounding as before.
   If Morpheus is unavailable, tell the user, then **fall back**: shallow-clone `JouleTRACK` and
   `jt-api-v2` read-only, ground via Grep/Read, and record the commit SHA used in the plan's
   overview. Never skip grounding; never plan from memory of the repos.
2. **Design layer is delegated.** For colors/type/components, defer to the **`sj-ui-design-system`**
   skill and **`JouleTRACK/DESIGN.md`**. Do not re-derive or invent design tokens here.

---

## Ground rules (apply throughout)

- **Primary targets + full blast radius.** The **primary build targets** are
  `SmartJoules/JouleTRACK` (master) and `SmartJoules/jt-api-v2`. But cover **every other active repo
  the feature needs to change** (edge/ingestion, data pipeline, stores/migrations, CPA/CPO models) —
  found via Morpheus blast-radius analysis and written up in plan-template §7. **Never** target
  legacy: `JouleTrack-API` (old Sails backend) is **retired** — not a target for anything; legacy
  patterns inside JouleTRACK (Highcharts, pre-NgRx code paths) are not models to mirror. New feature
  endpoints go in jt-api-v2; supporting changes go in whichever **active** repo owns the artifact.
- **Structural analysis only.** Infer data sources by reading repo code/queries. **Never query live
  production databases or read row values.** Where data availability can't be proven from code, mark
  it as a **risk** in the plan — do not assume it exists.
- **Real code wins over docs.** When `src/claude.md` / READMEs disagree with the actual code, mirror
  the **code**. Confirm the current structure from a recent real feature.
- **Secrets protocol.** Prototypes routinely hardcode tokens, URLs, and site IDs. Inventory every
  one, plan its env-var replacement, and flag exposed credentials **for rotation** in plan risks.
- **Recommend, don't decide.** Every reuse-vs-build call is surfaced as a **recommendation for the
  reviewer**, with the evidence.
- **Never invent design.** Map the prototype's visual roles onto real `--n-*` tokens (see
  `DESIGN.md`); flag any gap as a design decision, never a silent new color.
- **Preserve the contract.** The Angular UI must consume exactly what the new backend returns —
  define the response shapes once and keep both sides to them.

---

## Procedure

Work the phases in order. Each phase feeds the next — an interactive **brainstorm gate** sits between
grounding and synthesis (Phase 2.5), and an **independent review** follows synthesis (Phase 4). Use a
TodoWrite list to track them.

### Phase 0 — Ingest & detect input

Determine what was handed over. The input can be **anything**:

| Input form | How to ingest |
|---|---|
| Local folder / path | `Glob` + `Read`; find the entry point, routes, API calls |
| Git repo / URL | Clone or read; same as above |
| Static HTML / CSS mockup | Read the markup; extract structure, components, styles |
| Screenshots / Figma | Read images; describe screens, components, states, visual language |
| Runnable code (no UI) | Read; identify endpoints, data transforms, business logic |
| Text description | Treat as the spec; list features, screens, data flows |
| Shipped data fixtures (CSV/YAML/JSON lookup tables, configs) | Inventory as **runtime dependencies** someone must own/migrate |

Produce a short **input inventory**: artifact kind, every app/frontend it contains (prototypes often
ship two of each), what it covers, what's missing (env files, model artifacts, Dockerfiles). If the
prototype ships its own docs/README, cross-check them against the code and record the drift.

### Phase 1 — Prototype extraction

**REQUIRED:** follow `references/prototype-extraction.md` — the systematic playbook for any Python
backend (framework detection, route census, data-source tracing, business-logic capture, background
work, hazard sweep) and any HTML/JS frontend (screen/network/chart/visual census). It ends with a
**reconciliation gate**: every frontend call maps to a backend route and vice versa; every screen,
datum, formula, secret, and scheduler is inventoried. Do not enter Phase 2 with orphans, and ask the
user the 2–3 clarifying questions there, not later.

### Phase 2 — DeJoule grounding (via Morpheus)

Map the prototype onto the real repos. **Backend** and **frontend** in parallel.

**Backend — jt-api-v2** (details in `references/backend-jt-api-v2.md`; confirm live via `how_do_i`):
- Confirm the action shape (`how_do_i("sails action")` — or `{ friendlyName, inputs, exits, fn }`
  returning `exits.success({ data, err })`).
- For each prototype API: search for an **existing service/action that already does this**
  (`code_investigate`, then verify; e.g. `dashboard.service.fetchSavings`). For each data source
  the prototype touches, check **lineage** (`kg_query` on the bucket/table/artifact) — services
  already reading/writing it are the reuse precedent. Recommend reuse or a new feature domain.
- Map data sources to the real influx/RDS/Dynamo access patterns (named influx configs, `{{key}}`
  Flux templating; canonical names via `resolve`). Infer from code; flag unproven data as risk.
- **Run `check_fit` on every NEW dataflow the plan proposes** (e.g. "backend writes to HVAC
  influx") — violations + sanctioned alternatives go in the plan's risks/open decisions.
- Identify auth (`isAuthorized` + `_userMeta`), multi-site (`:siteId`), and route placement
  (`config/routes.js`).
- Find a home for any background work (`how_do_i("background job")` — airflow DAG / dedicated
  microservice / Kafka consumer; jt-api-v2 has no cron) — reviewer decision.

**Frontend — JouleTRACK** (details in `references/frontend-jouletrack.md`):
- Read a **canonical recent feature** to mirror the *actual* folder structure and NgRx flavor (global
  `@ngrx/store` vs `@ngrx/component-store`) — don't assume from docs.
- Plan the feature module around the repo's real feature shape: lazy route, Container/Presenter,
  feature-local `services/` and `models/` where the feature owns them, transformers, RxJS polling —
  never `setInterval` — plus nav/menu and role/permission registration.
- Charts via `EchartsWrapperComponent` (Apache ECharts) with the DeJoule palette.
- **Design alignment** via `DESIGN.md` + `sj-ui-design-system`: map each prototype visual role → real
  `--n-*` token; substitute hand-rolled UI → PrimeNG/shared components; plan CSS component styles;
  flag token gaps.

**Cross-repo blast radius — every OTHER active repo the feature touches** (drives plan-template §7):
- For each data dependency and new artifact the feature needs, find the **owning repo** and what must
  change there, via Morpheus: `architecture_brief` (store catalog — who reads/writes each store),
  `kg_impact(target)` (blast radius of changing a store/table/measurement/service), `kg_trace`/lineage
  (producers & consumers of a bucket/table/topic, with file:line).
- Typical cross-repo needs: a telemetry field/measurement the prototype reads that **isn't emitted
  yet** (an edge/ingestion repo — `iot-application`, `component-null-data-ingestor`,
  `py-mqtt-data-flow` — must produce it); a new **RDS/Mongo column or table + migration** owned by
  another service; a new **Dynamo key** or **MQTT topic**; an **airflow DAG / ETL** change; a
  **CPA/CPO/CPC model** input.
- If the data the prototype assumes **doesn't exist in any store**, the producing repo's change is a
  **hard dependency / blocker** — it goes in §7, the §2.3 DAG, and the risks. Cross-repo work is often
  owned by **other teams** — capture owner + whether it blocks; don't assume it's ours to build.
- If the blast radius is genuinely just the two primary repos, **say so explicitly** (verified via
  `kg_impact`) — never leave it implicit.

### Phase 2.5 — Brainstorm the approach (interactive — REQUIRED)

With Phase 1 analysis and Phase 2 grounding in hand but **before writing the plan**, invoke the
**`superpowers:brainstorming`** skill to align with the user on the build approach. Bring the evidence
to the table — don't brainstorm in the abstract:
- the **reuse-vs-build** candidates and the riskiest data dependencies (the `check_fit` / unproven-data
  findings);
- the **cross-repo blast radius** — which other repos must change, and which are blockers / owned by
  other teams;
- **scope** (MVP vs full) and any scope cuts;
- the **NgRx flavor** and other framework forks;
- how the work splits into **independent vs linked** tracks (this seeds the §2.3 dependency DAG).

Resolve the big forks here, with the user, so the plan reflects agreed intent — not assumptions.
Capture the brainstorm outcome; it drives Phase 3. (This is the one interactive gate; the rest of the
skill runs to completion.)

### Phase 3 — Plan synthesis

Assemble the **single markdown plan** following `references/plan-template.md` exactly — all sections in
order, code excerpts as JSON blocks. Use the CPO Dashboard plan in `references/cpo-worked-example.md`
as the gold standard for depth, structure, and tone. Beyond the per-section guidance there, hold to:

- **Diagrams (§2).** Produce three **Mermaid** diagrams: an **architecture** diagram (prototype →
  new jt-api-v2 domain → data stores; JouleTRACK feature → API; **plus other-repo changes from §7**),
  a **request/data-flow sequence** (UI → action → service → store → response), and the **work-item
  dependency DAG** (nodes = buildable+testable units; edges = dependencies; the DAG doubles as the
  parallel-build map for §11, and includes cross-repo nodes tagged with their owning repo).
- **Cross-repo changes (§7).** List **every other active repo** that must change (proportionate
  change-spec: what / why / owning repo+team / Morpheus evidence / blocker? / rough effort), and thread
  them into the architecture diagram, the dependency DAG, ops rollout order, effort, and risks. If
  none, state the blast radius is the two primary repos (verified via `kg_impact`).
- **Moderate TDD (§9).** Prescribe TDD (red→green→refactor) for the **logic core + the API contract**
  only — savings/derivation math, binning/aggregation, FE transformers, and the response shapes the FE
  consumes. Target roughly **60–70 % on the logic layer**; keep glue/presentational code lightly
  covered. **Not** aggressive 80 %-everywhere TDD.
- **Parallel, dependency-driven build (§11).** Incremental delivery, not waterfall. Mark each work
  item **independent** (parallelizable) or **linked** (must integrate together). **Recommend** running
  independent tracks in parallel via **git worktrees + subagents** (`superpowers:using-git-worktrees`,
  `superpowers:subagent-driven-development`); linked items integrate and are **tested together at their
  contract seam**. Cross-repo blockers go first; external-team items are tracked as dependencies, not
  tracks we own. Testing layers: unit/TDD per item (parallel) → integration per linked cluster (at the
  contract boundary) → phase acceptance/E2E → final parity gate vs the prototype.

**Completeness gate — verify before delivering, fix anything that fails:**
- [ ] Every route from the Phase 1 census appears in the endpoint→action map (reused, new, or
      explicitly dropped with a reason).
- [ ] Every screen/state from the census appears in the frontend plan.
- [ ] Every formula captured in Phase 1 has a named parity-gate KPI.
- [ ] Every secret/hardcoded value has an env-var/config plan; exposed credentials flagged for rotation.
- [ ] Every background job has a proposed home.
- [ ] **Cross-repo blast radius checked via Morpheus (`kg_impact`/lineage): every active repo the
      feature requires has a §7 change-spec — or §7 explicitly states "two primary repos only,
      verified". Any not-yet-existing data dependency is a logged blocker with an owning repo.**
- [ ] Every claim about the repos has Morpheus (or clone-SHA) evidence; unproven data is in risks.
- [ ] Every NEW cross-service dataflow has a `check_fit` verdict; violations carry the sanctioned
      alternative.
- [ ] Every entity name (site, bucket, measurement, service) in the plan went through `resolve`.
- [ ] All three Mermaid diagrams are present and valid, and match the planned components/contract.
- [ ] The dependency DAG marks each work item independent (parallelizable) or linked (integrate+test
      together), includes cross-repo nodes, and the testing layers are stated.
- [ ] The testing section names what is TDD'd (logic core + contract) and the coverage target — not
      aggressive everywhere.
- [ ] Effort table sums to the stated total; critical path identified (incl. external cross-repo deps).

### Phase 4 — Independent plan review (REQUIRED)

Before delivering, dispatch an **independent architecture-review subagent with Morpheus access**
(architect-style design lens; it re-verifies reuse claims, contract shapes, store lineage, the
**cross-repo blast radius**, and `check_fit` verdicts against the live repos via Morpheus). Hand it the
rubric:
- completeness vs the Phase 1 census; nothing orphaned;
- **contract coherence** — the FE consumes exactly what the BE returns;
- **no missed cross-repo dependency** — every store/table/field the feature needs is either present or
  has an owning-repo change in §7;
- no invented design; tokens mapped to real `--n-*`;
- every repo claim evidenced; risks + `check_fit` violations surfaced;
- the dependency DAG's independent/linked split is sound and the parallel tracks are genuinely
  independent;
- the effort estimate and critical path are realistic.

Fold the review's findings back into the plan, then add the **§14 Review notes** section summarizing
what the review caught and how the plan changed. **The delivered plan is the reviewed one.**

---

## Output

A single markdown document (the plan), already **independently reviewed** (Phase 4) and carrying its
diagrams, cross-repo change-specs, parallel-build dependency graph, and review notes. Offer to save it
next to the prototype or paste it for review. Do not start implementation — the plan is the deliverable.

## References

- `references/prototype-extraction.md` — **Phase 1 playbook**: extract any HTML + Python prototype
- `references/plan-template.md` — the exact output structure to produce
- `references/backend-jt-api-v2.md` — Sails conventions, action shape, services, influx/auth/routes
- `references/frontend-jouletrack.md` — Angular structure, NgRx, charts, design alignment
- `references/cpo-worked-example.md` — the CPO Dashboard plan as a worked example
