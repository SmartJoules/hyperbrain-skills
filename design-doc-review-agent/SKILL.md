---
name: design-doc-review-agent
description: A callable reviewer agent (Pi-style, also works in Claude Code) that reviews a software design doc for correctness and adds grounded feedback. Invoke via /skill:design-doc-review-agent <path-to-doc> (Pi) or by asking "review this design doc with the design-doc-review-agent". It applies the design-doc-reviewer rules, then grounds every piece of feedback in the real context + coding standards of the repo the doc targets — JouleTRACK (Angular), jt-api-v2 (Sails), and iot-feedback-handler (TypeScript microservice) — plus the hyperbrain engineering standards. Use whenever a design doc needs a correctness review with repo-aware, actionable feedback before implementation.
allowed-tools: Read, Grep, Glob, Bash
---

# Design Doc Review Agent (callable, Pi-style)

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** A callable agent that reviews a software design doc and leaves repo-grounded, standards-based feedback
**Version:** 1.0.0

---

## 🎯 What this is / How to call it

A **callable reviewer agent**. It does not invent its own rules — it composes existing skills and grounds feedback in real repo context.

- **Pi**: `/skill:design-doc-review-agent <path-or-PR-to-the-design-doc>`
  (Pi auto-loads it from its description, or invoke explicitly; args after the command are the target doc. See [[pi-coding-agent]] for Pi skill/agent mechanics, AGENTS.md context loading, and print/JSON/RPC modes for running it headless/in CI.)
- **Claude Code**: "review this design doc with the design-doc-review-agent" (or run inside a sub-agent).
- **Headless / CI**: run via Pi print mode (`pi -p`) or the existing `design-doc-reviewer` CI gate; this agent is the richer, repo-grounded counterpart.

Composes (does NOT duplicate): [[design-doc-reviewer]] (the rules + verdict format) · [[pi-coding-agent]] (Pi agent/skill mechanics) · [[engineering-standards]] (the coding standards) · [[agentic-engineering]] (retrieve-don't-read for large docs).

---

## 🔁 Agent Loop (deterministic)

1. **Resolve the target** — read the design doc (path, PR, or pasted text). If it's a PR, get the changed doc files.
2. **Detect the target repo(s)** the doc is about (it may span more than one). Markers:
   | Signal | Repo | Context to load |
   |--------|------|-----------------|
   | Angular, component/service, dashboard, `--n-*`, PrimeNG | **JouleTRACK** | [[jouletrack-angular]], [[jouletrack-library]], [[design-knowledge-base]] |
   | Sails, Waterline, controller/service/model, `/v1/...`, dejoule-api | **jt-api-v2** | [[backend-knowledge-base]], [[dejoule-knowledge-base]] |
   | device feedback, Kafka consumer, event-driven ingestion, Prisma, command ack | **iot-feedback-handler** | repo context below + [[iot-knowledge-base]], [[kafka-patterns]] |
   | InfluxDB / DynamoDB / Redis / Postgres | any | [[database-patterns]], [[influxdb-patterns]], [[database-query-optimizer]] |
   | LLM/agent/RAG | any | [[rag-retrieval]], [[prompt-engineering]], [[llm-eval-guardrails]], [[agent-tool-design]], [[lumen-knowledge-base]] |
3. **Load real context cheaply** (retrieve-don't-read per [[agentic-engineering]]): for each target repo read its `AGENTS.md` / `CLAUDE.md` / `ARCHITECTURE_AND_STANDARDS.md`, `ai-context/*`, and `graphify-out/GRAPH_REPORT.md` if present; the KB skill above; then targeted grep into the repo for the specific symbols/endpoints/patterns the doc proposes. Do NOT read whole modules.
4. **Apply the rules** from [[design-doc-reviewer]] — required structure, hard constraints, engineering-standards, skill alignment.
5. **Ground each finding** in what the repo actually does (cite a real file/convention/standard — see §Repo Grounding).
6. **Emit feedback** in the verdict format (§Output) — and, when invoked on a PR, post the findings as review comments anchored to the relevant lines.

---

## 📚 Repo Grounding (cite the real thing, not generic advice)

When the doc targets a repo, check it against that repo's ACTUAL conventions and say where it diverges:

### JouleTRACK (Angular 17, PrimeNG, RxJS)
OnPush; `takeUntil(destroy$)`/async pipe; typed services with `catchError`; no `::ng-deep` (use `ViewEncapsulation.None` + scoping class); `--n-*` design tokens; reusable-first (grep blast radius before editing shared components). Feedback cites `jouletrack-angular` + the design tokens.

### jt-api-v2 (Sails 1.x + Waterline)
Thin `api/controllers/*` → `api/services/*` (logic) → `api/models/*` (Waterline); routes in `config/routes.js`, auth in `config/policies.js` (don't change without consent); "repository" = Waterline model + service (no foreign ORM); preserve nulls in time-series (no `fill(0)`); connection standards (singleton ioredis, Kafka offset-after-process, lag). Feedback cites `backend-knowledge-base`.

### iot-feedback-handler (TypeScript microservice, event-driven)
Enterprise TS strict; **explicit layered architecture** — `src/{config,constants,handlers,interface,orchestrators,repositories,services,utils}`; **Repository / Factory / Strategy / Singleton** patterns are mandated (per its `ARCHITECTURE_AND_STANDARDS.md`); OOP + GoF required; Express + **KafkaJS** (heartbeat, offset-after-process, lag, DLQ, snappy), Prisma + Postgres/MongoDB/DynamoDB/InfluxDB, Redis singleton, Sentry + pino logging; MCP (Morpheus) usage is mandated for AI agents. Feedback cites `iot-communication/iot-feedback-handler/ARCHITECTURE_AND_STANDARDS.md` and the relevant layer.

> If a target repo has its own `AGENTS.md`/`ARCHITECTURE_AND_STANDARDS.md`, that repo's rules win for repo-specific specifics; hyperbrain [[engineering-standards]] is the cross-repo baseline.

---

## ✅ Correctness Bar (what makes a design doc "correct")

A doc passes only if it is (a) **complete** (required sections per [[design-doc-reviewer]]), (b) **constraint-clean** (no hardcoded secrets/site-ids, no banned anti-patterns, security/resilience addressed), (c) **consistent with the target repo's real architecture & standards** (doesn't propose a pattern the repo forbids, or reinvent something it already has), and (d) **not over-engineered** for the change. Anything failing a/b/c is a REJECT; over-engineering is a MAJOR.

---

## 📤 Output (feedback format)

Use the [[design-doc-reviewer]] verdict block, with every finding **repo-grounded**:

```
## Design Doc Review — <doc> — Target repo(s): <…> — VERDICT: REJECT | APPROVE-WITH-CHANGES | APPROVE

### Summary  — what it proposes + headline reason for the verdict

### Blockers (must fix)
- [section] <issue> → <fix>  (grounded in: <repo file/convention or hyperbrain skill>)

### Major / ### Minor

### Strengths

### Required changes to APPROVE  (ordered, concrete)
```

When run on a PR: post each blocker/major as a line-anchored review comment citing the repo convention or skill; post the summary + verdict as the top-level review (request changes on REJECT). Every comment names **where · why (which standard/repo file) · the fix** — so the author acts in one round.

---

## Done Checklist
- [ ] Target doc + target repo(s) resolved
- [ ] Real repo context loaded cheaply (AGENTS/ARCHITECTURE/ai-context/graphify + KB skill), not whole-module reads
- [ ] Rules applied from design-doc-reviewer; correctness bar (a–d) checked
- [ ] Every finding cites a real repo convention/file or a hyperbrain skill — no generic advice
- [ ] Verdict + ordered required changes; PR comments line-anchored where applicable
- [ ] Not over-engineered; feedback scaled to the change
