---
name: design-doc-reviewer
description: Review a design document (HLD/LLD, RFC, tech spec, ADR, *-design.md) against required structure, engineering constraints, and the hyperbrain skill standards — then APPROVE or REJECT with concrete, actionable improvements. Use when a design doc is written/changed, in a PR that touches a design/spec/RFC file, or when asked "review this design doc / is this spec ready / does this follow our standards". Acts as the gate a doc must pass before implementation. Produces a verdict (APPROVE / REJECT / APPROVE-WITH-CHANGES), violations by severity, and required fixes. Pairs with the CI design-doc check.
---

# Design Doc Reviewer

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Gate design docs — reject non-conforming ones and say exactly how to fix them
**Version:** 1.0.0

---

## 🎯 When to Use

A design doc (HLD/LLD, RFC, tech spec, ADR, `*-design.md`, `DESIGN.md`, `docs/**/specs/*`) is written or changed, or a PR touches one. Acts as the **approval gate before implementation**. Verdict + violations + required fixes.

> Reject for **substantive** constraint violations, not style nitpicks. The goal is "this design is safe and standards-aligned to build", not a perfect document. Be specific and actionable — every rejection names the fix.

Pairs with: [[software-architecture-planner]] (forward design it reviews), [[architecture-reviewer]] (system-level review of built systems), [[engineering-standards]] (the constraints), and the **CI check** (`scripts/design-doc-lint.js` in this skill + the workflow it powers).

---

## 1. Required Structure (a design doc MUST have)

Reject if any of these are **missing or empty**:

1. **Title + status** (Draft / In-Review / Approved) + author + date
2. **Context / Problem** — what & why; the requirement it serves
3. **Goals & Non-Goals** — explicit scope (non-goals prevent scope creep)
4. **Proposed Design** — the actual approach (HLD; LLD where it matters)
5. **Alternatives Considered** — ≥1 alternative + why rejected (no alternatives = unconsidered design)
6. **Data & API design** — schema/contracts/endpoints if it touches data or APIs
7. **Risks & Mitigations**
8. **Rollout / Migration / Rollback** — if it changes prod, schema, or contracts
9. **Testing strategy**
10. **Open Questions** (or an explicit "none")

(For a lightweight ADR, items 1–5 + the decision suffice; scale rigor to the change size — KISS.)

## 2. Engineering Constraints (from [[engineering-standards]]) — REJECT on violation

- **Design**: SOLID respected; the right pattern named where it removes branching/duplication (Strategy/Factory/Observer/Repository…), and **no over-engineering** (a pattern/service where a function suffices). DRY (reuses existing components/services, doesn't reinvent), KISS, minimal-blast-radius.
- **Resilience**: the design addresses error handling, loading/empty/**partial-data** states (UI), no-memory-leak (cleanup of subscriptions/timers/connections), and no unhandled async.
- **Data & performance**: queries/access patterns are sound (no N+1, no unbounded scans, pagination); **caching has a defined eviction strategy** (TTL/LRU/max-size) + invalidation — never an unbounded cache.
- **Connections** (if it adds Kafka/Redis/DB/MQTT): singleton/pool (not per-request), retry+backoff, graceful shutdown, error-event handling; Kafka offset-after-process + lag; Redis TTL/eviction + graceful degradation.
- **Security**: no hardcoded secrets/credentials/tokens (env/secret-manager); inputs validated at boundaries; authZ at the right layer; no `any` types in proposed contracts.
- **No hardcoded site IDs / environment values** (DeJoule rule).

## 3. HyperBrain Skill Alignment — REJECT if it ignores the applicable standards

A conforming design must be consistent with the relevant hyperbrain skills for what it touches. The reviewer checks the doc against the skill(s) that apply:

| Doc touches… | Must align with |
|--------------|-----------------|
| JouleTRACK Angular frontend | [[jouletrack-angular]], [[design-knowledge-base]]/[[ui-ux-design]] (OnPush, RxJS+takeUntil, no ::ng-deep, --n-* tokens) |
| jt-api-v2 / Node / Python / Go backend | [[backend-knowledge-base]], [[prompt-harness]] repo idioms (Sails: thin controllers → services → Waterline models) |
| Databases / queries | [[database-patterns]], [[database-query-optimizer]], [[influxdb-patterns]] |
| IoT / streaming | [[iot-architecture]], [[kafka-patterns]], [[mqtt-patterns]] |
| An algorithm/data-structure choice | [[algorithm-picker]] (justified by input size/constraints) |
| An LLM / agent / RAG feature | [[rag-retrieval]], [[prompt-engineering]], [[llm-eval-guardrails]], [[agent-tool-design]], [[lumen-knowledge-base]] |
| Large/multi-file effort | [[agentic-engineering]] (decompose + budget) |

If the doc proposes a pattern that **contradicts** an applicable skill (e.g. per-request Redis client, ::ng-deep, unbounded cache, hardcoded model names), that's a REJECT with the skill cited.

## 4. Verdict & Severity

| Severity | Meaning | Effect |
|----------|---------|--------|
| **BLOCKER** | Missing required section, or a hard constraint/skill violation | **REJECT** |
| **MAJOR** | Significant gap/risk (weak alternatives, unhandled failure mode) | REJECT or APPROVE-WITH-CHANGES (reviewer judgment) |
| **MINOR** | Improvement, not blocking | Note |

**Verdict**: `APPROVE` (no blockers/majors) · `APPROVE-WITH-CHANGES` (majors only, fixable in follow-up) · `REJECT` (any blocker).

## 5. Output Format (the review)

```
## Design Doc Review — <doc> — VERDICT: REJECT | APPROVE-WITH-CHANGES | APPROVE

### Summary
<1–2 lines: what the doc proposes + the headline reason for the verdict>

### Blockers (must fix to pass)
- [section/line] <what's wrong> → <concrete fix> (constraint/skill: <which>)

### Major
- ...

### Minor / Suggestions
- ...

### Strengths
- <what's good — don't only criticize>

### Required changes to APPROVE
1. <ordered, concrete>
```

Every rejection line must name **where**, **why** (which constraint/skill), and **the fix** — so the author can act without a second round.

---

## ✅ Reviewer Checklist
- [ ] All required sections present + non-empty (scaled to change size)
- [ ] Engineering constraints met (SOLID/patterns, resilience, data/perf+cache-eviction, connections, security, no hardcoded IDs/secrets)
- [ ] Aligns with every applicable hyperbrain skill; no contradicting pattern
- [ ] Alternatives + risks + rollback/test covered for the change's blast radius
- [ ] Not over-engineered (rigor scaled to the change)
- [ ] Verdict + severity-tagged findings + ordered required fixes + strengths
- [ ] Every rejection is actionable (where · why · fix)

> The CI counterpart (`scripts/design-doc-lint.js`) enforces the *mechanical* subset (required sections, hardcoded-secret/site-id scan, skill-reference presence) as a hard gate; this skill provides the full judgment review + suggestions.
