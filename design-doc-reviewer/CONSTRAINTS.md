# Design Doc Constraints

The rules a design doc must satisfy to pass review. The CI gate
(`scripts/design-doc-lint.js`) enforces the mechanical subset; the
`design-doc-reviewer` skill enforces the full judgment set + suggests fixes.

## Required sections (non-empty)
Context/Problem · Goals & Non-Goals · Proposed Design · Alternatives Considered ·
Data & API design (if it touches data/APIs) · Risks & Mitigations ·
Rollout/Migration/Rollback (if it changes prod/schema/contracts) · Testing strategy ·
Open Questions. *(A doc declaring itself an ADR may use the lighter ADR shape:
Context + Decision + Alternatives.)*

## Pre-conditions (checked first → reject)
- **≤ 15 pages.** A design doc must be tight. The linter estimates pages from
  `max(words/450, non-blank-lines/55)` and rejects over 15 (override with
  `DDLINT_MAX_PAGES`). Move bulk to linked appendices.
- **Human-approved first.** The doc must carry a human approval signal (e.g.
  `Status: Approved`, `Ready for review`, `Reviewed by <name>`) before automated
  review — the agent/gate is a *second* gate. Enforced as a blocker when
  `DDLINT_REQUIRE_APPROVAL=1` (warning otherwise).
- **Not sloppy.** An unfinished/placeholder/wall-of-text draft is rejected outright
  (judgment applied by the design-doc-review-agent).

## Hard constraints (BLOCKER → reject)
- No hardcoded secrets/tokens/credentials/private keys — env vars / secret manager only.
  A design that touches LLM/DB/3rd-party keys must source them by name from env or a
  secret store (CI: GitHub repo/org secret; local: env/gitignored `.env`; tokensmax:
  `~/.config/tokensmax/secrets.env`), least-privilege + rotatable, never logged. See
  engineering-standards §5B.
- No hardcoded site IDs or environment values (site comes from context/config).
- No anti-patterns proposed *as* the design: `::ng-deep`/`/deep/`/`>>>` (use
  `ViewEncapsulation.None` + scoping class); per-request Redis/DB connections
  (use singleton/pool); unbounded cache (must define TTL/LRU/max-size eviction).
- Must not contradict the applicable hyperbrain skill for what it touches
  (see the table in `SKILL.md` §3).

## Engineering constraints (from engineering-standards)
SOLID + the right design pattern (no over-engineering) · DRY/KISS/minimal blast radius ·
resilience (error/loading/empty/partial-data states, no leaks, no unhandled async) ·
data/perf (no N+1, pagination, cache with eviction + invalidation) · connection
standards for Kafka/Redis/DB/MQTT · security (validate inputs, authZ, no `any`).

## How to pass
1. Use the required sections.
2. Reference the applicable hyperbrain skills under a "Skills / Standards" heading.
3. Address failure modes, rollback, and tests for the change's blast radius.
4. Scale rigor to the change — don't gold-plate a small ADR (KISS).

Run locally before pushing:
```bash
node scripts/design-doc-lint.js path/to/your-design.md
```
