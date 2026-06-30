---
name: design-doc-review-agent
description: A callable reviewer agent (Pi-style, also works in Claude Code) that reviews a software design doc for correctness against FAANG-style standards and adds repo-grounded feedback. Invoke via /skill:design-doc-review-agent <path-to-doc> (Pi) or "review this design doc with the design-doc-review-agent". Runs hard-reject pre-conditions FIRST — the doc must be human-approved before reaching the agent, must be ≤15 pages, and a sloppy/unfinished doc is rejected immediately — then applies the design-doc-reviewer rules and grounds every finding in the real context + coding standards of the target repo (JouleTRACK Angular, jt-api-v2 Sails, iot-feedback-handler TS microservice) plus hyperbrain engineering-standards. Use whenever a design doc needs a correctness review before implementation.
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

## 🚦 Pre-conditions & Hard Rejects (run this gate FIRST — before any review work)

Do these checks before loading repo context or reviewing content. If any fails, **REJECT immediately** with the one-line reason and STOP — do not produce a full review, do not suggest fixes line-by-line. The point is to bounce a doc that isn't ready for a reviewer's time.

1. **Human-approved first (REQUIRED).** A doc must be **human-approved before it reaches this agent.** Check for an explicit human-approval signal — e.g. doc status `Approved`/`Ready for review` set by a named person, an approving human reviewer/sign-off on the PR, or the requester stating it's human-approved. **No human approval → REJECT** with: "Design docs must be human-reviewed and approved before automated review. Get a human sign-off, then resubmit." (This agent is a *second* gate, not the first.)
2. **Length ≤ 15 pages (HARD CAP).** If the doc exceeds **15 pages**, REJECT immediately: "Doc exceeds the 15-page limit — a design doc must be tight. Split it (link appendices/sub-docs) and resubmit." Page estimate (no native page count in Markdown): **~450 words/page or ~55 non-empty lines/page** → reject if `max(words/450, non_blank_lines/55)` > 15. State the estimate used. (Code blocks, large tables, and embedded data count; move bulk to appendices.)
3. **Sloppy → immediate REJECT.** If the doc is sloppy, bounce it without a detailed review: "Doc is too rough for review — clean it up and resubmit." Sloppy = any of: no real structure / wall-of-text with no sections; placeholder/TODO/`<...>`/`lorem`/"TBD" in core sections; broken or empty headings; contradictory or copy-paste-leftover content; no clear problem statement or proposed design; obviously unfinished (truncated, dangling sentences). Judgment call — but err toward rejecting an unserious draft rather than spending review effort on it.

Only if all three pass do you proceed to the Agent Loop.

---

## 🔁 Agent Loop (deterministic)

0. **Pre-conditions gate** — run the §Pre-conditions checks above. Any failure → REJECT + STOP.
1. **Resolve the target** — read the design doc (path, PR, or pasted text). If it's a PR, get the changed doc files.
2. **Detect the target repo(s)** the doc is about (it may span more than one). Markers:
   | Signal | Repo | Context to load |
   |--------|------|-----------------|
   | Angular, component/service, dashboard, `--n-*`, PrimeNG | **JouleTRACK** | [[jouletrack-angular]], [[jouletrack-library]], [[design-knowledge-base]] |
   | Sails, Waterline, controller/service/model, `/v1/...`, dejoule-api | **jt-api-v2** | [[backend-knowledge-base]], [[dejoule-knowledge-base]] |
   | device feedback, Kafka consumer, event-driven ingestion, mode/recipe/relinquish/bulk-asset, command ack | **iot-feedback-handler** | [[iot-feedback-handler-knowledge-base]] + [[iot-knowledge-base]], [[kafka-patterns]] |
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
See [[iot-feedback-handler-knowledge-base]] for the full architecture. In brief: explicit **layered architecture** `handlers→orchestrators→services→repositories` (downward deps only; thin handlers, fat services, no DB in services); **Repository / Factory / Strategy / Singleton** patterns mandated (per its `ARCHITECTURE_AND_STANDARDS.md`); OOP-only main flows; Express + **KafkaJS+snappy** (manual offset-after-process, heartbeat; note: NO DLQ — failures skip+Sentry), cloud/edge **DocumentStoreFactory** (DynamoDB/MongoDB) + Postgres audit + Redis singleton (TTL 3600), Sentry + structured pino; **Morpheus MCP query is mandated** for AI agents before changes. Feedback cites the KB skill + the relevant layer/file.

> If a target repo has its own `AGENTS.md`/`ARCHITECTURE_AND_STANDARDS.md`, that repo's rules win for repo-specific specifics; hyperbrain [[engineering-standards]] is the cross-repo baseline.

---

## 📏 FAANG-style Design Doc Standard (what a *good* doc looks like)

Hold docs to the bar used at Google/Amazon/Meta — substance over length, decisions over description. Expect:

- **Tight & self-contained** — a reader unfamiliar with the work understands it in one sitting (hence the ≤15-page cap). Written prose, not bullet soup; Amazon-style narrative is ideal.
- **Context & problem framed first** — why this matters now, what breaks without it, who's affected. The *problem* is argued before any solution.
- **Explicit Goals & Non-Goals** — measurable goals; non-goals bound the scope.
- **Proposed design with a clear "why"** — the approach AND the reasoning; key decisions justified, not just stated. Diagrams for non-trivial flows.
- **Alternatives Considered with trade-offs** — ≥2 real alternatives, each with pros/cons and *why it was rejected*. A doc with no genuine alternatives reads as an unconsidered decision.
- **Cross-cutting concerns addressed** — scalability, failure modes/reliability, security & privacy, data model/migration, observability, cost, rollout + rollback. Sized to the change.
- **Testing & validation strategy**, **risks/open questions**, and a **decision/approval trail**.
- **Honest about uncertainty** — open questions stated, not hidden; trade-offs acknowledged.

Missing the problem framing, missing alternatives-with-trade-offs, or no decision rationale → **BLOCKER**. Padding to look thorough is itself a smell (ties to the ≤15-page + not-over-engineered rules).

## ✅ Correctness Bar (what makes a design doc "correct")

A doc passes only if it clears the **§Pre-conditions gate** (human-approved · ≤15 pages · not sloppy) AND is (a) **complete** (required sections per [[design-doc-reviewer]] + the FAANG-style standard above), (b) **constraint-clean** (no hardcoded secrets/site-ids, no banned anti-patterns, security/resilience addressed), (c) **consistent with the target repo's real architecture & standards** (doesn't propose a pattern the repo forbids, or reinvent something it already has), (d) **decision-grounded** (problem framed, ≥2 alternatives with trade-offs, rationale for the chosen design), and (e) **not over-engineered / not padded** for the change. Pre-condition failure or a/b/c/d failing is a REJECT; over-engineering/padding is a MAJOR.

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
- [ ] Pre-conditions gate run FIRST: human-approved · ≤15 pages · not sloppy — any fail → REJECT + STOP (no full review)
- [ ] Target doc + target repo(s) resolved
- [ ] Real repo context loaded cheaply (AGENTS/ARCHITECTURE/ai-context/graphify + KB skill), not whole-module reads
- [ ] Rules applied from design-doc-reviewer; FAANG-style standard + correctness bar (a–e) checked
- [ ] Every finding cites a real repo convention/file or a hyperbrain skill — no generic advice
- [ ] Verdict + ordered required changes; PR comments line-anchored where applicable
- [ ] Not over-engineered / not padded; feedback scaled to the change
