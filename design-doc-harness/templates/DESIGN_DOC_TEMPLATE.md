# <Design Doc Title>

> Copy this file to `docs/design/<feature>-design.md`, fill every section, delete the
> `> guidance` lines, and keep it **≤ 15 pages**. Decision-first, prose over bullets.
> Get a **human approver** to sign off (Status: Approved) before the automated review.

| | |
|---|---|
| **Status** | Draft → In-Review → **Approved** → Implemented / Superseded |
| **Author** | <name> |
| **Reviewers** | <named humans, by area> |
| **Approver** | <human tech lead / principal> |
| **Date** | <YYYY-MM-DD> |
| **Target repo(s)** | <JouleTRACK / jt-api-v2 / iot-feedback-handler / …> |
| **Tier** | RFC / Architecture Doc |

## Context & Problem
> Why this matters NOW. What breaks or is painful without it. Who is affected.
> Frame the problem before any solution. (1–3 short paragraphs.)

## Goals & Non-Goals
**Goals** (measurable):
- …

**Non-Goals** (explicitly out of scope):
- …

## Proposed Design
> The approach AND the reasoning. Walk the reader through it. Add a diagram for any
> non-trivial flow. Justify the key decisions — don't just state them.
> Note which existing repo components/services you reuse (don't reinvent).

## Alternatives Considered
> ≥ 2 real alternatives. For each: brief description · pros · cons · **why rejected**.
1. **<Alternative A>** — … (rejected because …)
2. **<Alternative B>** — … (rejected because …)

## Data & API Design
> Schemas, contracts, endpoints. Types explicit (no `any`). Migrations + backward
> compatibility. Inputs validated at boundaries. (Omit only if it touches no data/APIs.)

## Cross-Cutting Concerns
> Size each to the change; write "N/A — <why>" if truly not applicable.
- **Scalability / performance** — load, hot paths, no N+1/unbounded scans, caching with eviction.
- **Reliability / failure modes** — what fails, timeouts/retries/backoff, graceful degradation.
- **Security & privacy** — authz, input validation, **secrets via env/secret store (never hardcoded)**, PII.
- **Observability** — logs/metrics/traces; how you'll debug it in prod.
- **Cost** — infra/LLM/data cost implications.
- **Connections** (if Kafka/Redis/DB/MQTT) — singleton/pool, retry, offset-after-process, TTL/eviction.

## Rollout / Migration / Rollback
> How it ships safely: feature flags, phased rollout, data migration plan, and the
> rollback path if it goes wrong.

## Testing & Validation
> Unit / integration / e2e strategy; how you'll verify correctness and the success metric.

## Risks & Open Questions
> Honest list. Open questions stated, not hidden. Decisions still needed.

## Skills / Standards
> The hyperbrain skills + repo standards this design follows (e.g. engineering-standards,
> jouletrack-angular / backend-knowledge-base / iot-feedback-handler-knowledge-base).

## Decision & Approval Trail
> Once approved: who approved, when, and the decision recorded. Link implementation PRs.
