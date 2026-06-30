---
name: architecture-reviewer
description: Review and audit an EXISTING system's architecture (not line-level code, not greenfield design). Use when evaluating a service, module, or whole repo for boundaries, coupling/cohesion, layering, dependency direction, scalability, data flow, fault tolerance, security posture, observability, and architectural smells/tech-debt — or when asked "review the architecture", "is this design sound", "where are the bottlenecks/risks", or before a big refactor/migration. Produces findings by severity with concrete remediations and an overall architecture-health verdict. Acts as a Principal Engineer / Solution Architect reviewer.
---

# Architecture Reviewer

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Audit an existing system's architecture and report risks + remediations by severity
**Version:** 1.0.0

---

## 🎯 When to Use

Auditing the architecture of an existing service/module/repo — boundaries, coupling, scalability, resilience, smells — or before a large refactor/migration. Acts as a **Principal Engineer / Solution Architect**.

**Boundaries (avoid overlap):**
- Designing architecture *forward* from requirements → use [[software-architecture-planner]].
- Line/PR-level code quality → use [[code-reviewer]].
- This skill is **system-level review of what already exists**.

Pairs with [[engineering-standards]] (the rules findings are graded against), [[database-query-optimizer]] (data-layer hotspots), [[agentic-engineering]] (review a large system without reading every file — use graphify/ai-context first), and [[agent-tool-design]] (reviewing an agent's architecture).

> Review against **stated requirements and real constraints**, not personal taste. An "imperfect" architecture that meets its scale/latency/team needs is fine — don't gold-plate (KISS/YAGNI).

---

## 🔍 Method

1. **Understand intent first.** What is the system for, its scale (RPS, data volume, users), latency/availability targets, team size, constraints? You can't judge architecture without the requirements it serves.
2. **Map before judging.** Build the real picture cheaply (retrieve-don't-read per [[agentic-engineering]]): components, their responsibilities, dependencies/edges, data stores, external integrations, data flow. Use graphify `GRAPH_REPORT` / `ai-context/*` where present.
3. **Review each dimension** (below).
4. **Report** findings by severity with concrete remediations + an overall verdict.

---

## 📐 Review Dimensions

### 1. Boundaries & modularity
- Clear module/service boundaries aligned to domains? Single responsibility per component?
- **Coupling** (low is good): hidden cross-module reach-ins, shared mutable state, chatty calls, circular dependencies. **Cohesion** (high is good): does each module hold related things?
- **Dependency direction**: do dependencies point inward to abstractions (Dependency Inversion), or does business logic depend on concrete infra? Any layering violations (UI→DB directly, domain importing framework)?

### 2. Layering & patterns
- Clean separation (controller/service/repository or equivalent)? In jt-api-v2: thin controllers → services (logic) → Waterline models; in Angular: container/presenter, OnPush, typed services.
- Right patterns where they remove branching/duplication (Strategy/Factory/Observer/Repository) — and **no over-engineering** (a framework where a function would do).

### 3. Scalability & performance
- Bottlenecks: synchronous chains that should be async, N+1 across services, query-in-loop, unbounded result sets, missing pagination.
- Statelessness / horizontal scalability; sticky state that blocks scaling.
- **Caching**: present where it pays, with eviction (TTL/LRU) + invalidation — never unbounded (a known Lumen gap is in-process-only cache). Hot paths identified.

### 4. Data architecture
- Right store per access pattern (relational vs time-series vs KV vs graph). In DeJoule: Postgres/Waterline, InfluxDB/Timestream, DynamoDB, Neptune, Redis.
- Schema/ownership: one writer per dataset? Consistency model appropriate? Migrations safe/reversible?
- Data flow & lineage clear; no chatty cross-store joins in app code (push down).

### 5. Resilience & fault tolerance
- Failure isolation (one dependency down ≠ whole system down); timeouts, retries with backoff, circuit breakers, graceful degradation, fallbacks.
- Long-lived connections (Kafka/Redis/DB/MQTT): singleton/pool, retry, graceful shutdown, error-event handling ([[engineering-standards]]).
- Idempotency, at-least/exactly-once semantics where it matters; DLQs; backpressure.
- No unbounded growth (caches, queues, in-memory maps) → memory-leak/OOM risk.

### 6. Security posture (architecture grain)
- Trust boundaries & authZ enforced at the right layer; no auth bypass via a side door.
- Secrets via env/secret-manager (never hardcoded); least privilege on data/services; input validated at boundaries.
- Blast radius of a compromised component; tenant/site isolation.

### 7. Observability & operability
- Structured logging, metrics, tracing, health checks; can you debug a prod incident from what's emitted? (Lumen emits a trace + cost meta — good; lacks Prometheus metrics — a gap.)
- Config/secrets externalized; safe deploy/rollback; feature flags for risky changes.

### 8. Evolvability & tech-debt
- Architectural smells: god component, distributed monolith, shotgun surgery (one change → many files), leaky abstractions, dead/duplicated subsystems.
- Is the change-cost reasonable for likely future work? Documented decisions (ADRs)? Test seams (can you test components in isolation)?

---

## 📊 Severity & Verdict

Grade each finding:

| Severity | Meaning | Action |
|----------|---------|--------|
| **CRITICAL** | Will cause outage/data-loss/security breach at expected load | Block — fix before scaling/shipping |
| **HIGH** | Significant scalability/resilience/maintainability risk | Fix soon; plan it in |
| **MEDIUM** | Real debt; will bite as the system grows | Schedule |
| **LOW** | Minor / stylistic / nice-to-have | Optional |

Each finding: **what · where (component/file) · why it's a risk (tie to a requirement/load) · concrete remediation · rough effort.** Recommend the highest-leverage fixes first; note quick wins.

---

## 📤 Output Format

1. **System summary** — purpose, scale/SLA targets, the architecture as you mapped it (components, data stores, data flow).
2. **Strengths** — what's sound (don't only criticize).
3. **Findings by severity** — CRITICAL → LOW, each with what/where/why/remediation/effort.
4. **Top risks & bottlenecks** — the 3–5 that matter most, prioritized.
5. **Remediation roadmap** — sequenced (quick wins → structural), with dependencies.
6. **Architecture-health verdict** — overall (e.g. Sound / Sound-with-risks / Needs-rework) + the one-line rationale.

---

## ✅ Reviewer Checklist
- [ ] Anchored the review in the system's actual requirements/scale, not taste
- [ ] Mapped components/dependencies/data-flow before judging (cheaply, via precomputed context)
- [ ] Checked all dimensions: boundaries, layering, scalability, data, resilience, security, observability, evolvability
- [ ] Each finding has severity + location + risk-tied-to-requirement + concrete fix + effort
- [ ] Called out strengths and quick wins, not just problems
- [ ] Did not gold-plate (no fixes the requirements don't justify)
- [ ] Clear verdict + prioritized roadmap
