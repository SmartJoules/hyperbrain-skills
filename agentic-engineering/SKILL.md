---
name: agentic-engineering
description: Operating model for large, multi-step development with low token consumption. Use for big features, multi-file refactors, migrations, or any task too large for one context window. Combines progressive context retrieval (graphify/local-kb/ai-context instead of reading whole files), explicit context budgets and compaction, planner→scoped-sub-agent orchestration where each sub-agent gets only the minimal context for its task, and a verification gate. Use whenever a task spans many files or would otherwise blow the context window.
---

# Agentic Engineering — Large Development at Low Token Cost

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Run large development as orchestrated, context-budgeted sub-tasks instead of one giant context
**Version:** 1.0.0

---

## 🎯 When to Use This Skill

Use when the task is **too large for one context window** or would waste tokens:
- A feature spanning many files / layers (UI + API + DB + stream)
- A repo-wide refactor, rename, or migration
- Onboarding to / changing an unfamiliar large codebase
- Anything where naively reading files would burn the budget before work starts

For small, single-file edits, skip this — the overhead isn't worth it (KISS).

---

## 🧠 The Core Idea

Token cost scales with **how much you read into context**, not how much you change.
Two levers, applied together:

1. **Retrieve, don't read.** Pull *precomputed, summarized* context (graphify graph,
   `ai-context/*`, local KB) and targeted grep/symbol lookups — instead of reading
   whole files "to understand the codebase."
2. **Decompose, don't accumulate.** Split the work into independent sub-tasks. Run
   each in its **own scoped sub-agent** with only the minimal context it needs. The
   orchestrator keeps a tiny working state (plan + results), never the union of all
   files every sub-agent touched.

This keeps the orchestrator's context small and bounded even as total work grows.

---

## 📚 Layer 1 — Progressive Context Retrieval (read the least possible)

**Order of preference (cheapest first). Stop as soon as you have enough.**

1. **Precomputed project context** (near-zero cost, highest signal):
   - `graphify-out/GRAPH_REPORT.md` — architecture, god nodes, communities (see [[graphify-integration]])
   - `ai-context/*.md` — curated SYSTEM_CONTEXT, DATABASE_SCHEMA, KAFKA/CACHE strategy, API_CONTRACTS, ANTI_PATTERNS
   - local KB for the repo (see [[local-kb]])
   - The project's `AGENTS.md` / `CLAUDE.md`
2. **Targeted search**, not full reads: grep for the symbol/route/class; read only the
   matching lines + a small window. Use the graph to find *which* file, then open just that file.
3. **Symbol-level reads**: read the one function/class you'll change, not the whole 800-line file.
4. **Full-file read** — last resort, only for the file you're actually editing.
5. **MCP on demand** (see [[mcp-on-demand]]): enable Morpheus/DB/Figma MCP only for the
   step that needs it, then move on. Don't hold every MCP open.

> Rule: never read a file "for understanding" if the graph/ai-context already
> summarizes it. Summaries are 10–100× cheaper than source.

If the repo has **no** precomputed context yet, generate it first with graphify /
local-kb — that one-time cost pays back across every later task.

---

## 📏 Layer 2 — Context Budgeting & Compaction

Set an explicit budget and defend it:

- **Budget per phase.** Plan/discovery, per sub-task, and verification each get a
  rough token ceiling. If discovery is eating the budget, you're reading too much —
  fall back to retrieval (Layer 1).
- **Working set, not history.** Keep only: the plan, the current sub-task's context,
  and structured results so far. Drop raw file dumps once you've extracted what you need.
- **Summarize-and-discard.** After reading something large, write a 3–5 line structured
  note (what it does, the signature/contract, the gotcha) and discard the source from
  context. Future steps read the note.
- **Compact at phase boundaries.** Between phases, collapse the transcript to: decisions
  made, files touched, open questions. (Claude Code does this automatically when context
  fills; do it deliberately at phase ends so you control what survives.)
- **Avoid the last ~20% of the window** for heavy multi-file work (errors and omissions
  rise there) — decompose instead.

---

## 🛠 Layer 3 — Planner → Scoped Sub-Agent Orchestration

The heart of large-task handling. **The orchestrator never does the reading-heavy work itself.**

### 3.1 Plan (orchestrator, small context)
- Use the planning frame from [[superpowers-brainstorm]] and the right persona from
  [[expert-personas]].
- Produce a **task list** of independent, well-scoped units. For each task record:
  `{ goal, the 1–5 files/symbols it touches, inputs, expected output/contract, done-criteria }`.
- Identify dependencies so independent tasks can run in **parallel**.

### 3.2 Dispatch scoped sub-agents (one per task)
Give each sub-agent a **self-contained brief** containing ONLY:
- its single goal + done-criteria,
- the specific files/symbols it may read (from the plan — not "the codebase"),
- the relevant convention slice (e.g. the [[engineering-standards]] rules + the one
  language/framework skill that applies, like [[jouletrack-angular]]),
- the contract it must satisfy (function signature, API shape, DTO).

The sub-agent returns a **structured result** (files changed, summary, any new
contracts), not its whole transcript. The orchestrator stores the result, not the
sub-agent's context. → total tokens scale with *number of tasks*, not *files × tasks*.

> Parallel where independent, sequential where one task's output is another's input.
> A failed sub-task returns its error and is retried or re-scoped — it doesn't poison
> the others.

### 3.3 Integrate
Orchestrator stitches results, resolves cross-task contracts, and runs the build/tests.

### 3.4 Verify (adversarial, cheap)
- Run the build + targeted tests for the changed surface only.
- Optionally spawn a **reviewer sub-agent** that sees only the diff (not the whole repo)
  and checks it against the [[engineering-standards]] quality gate + the done-criteria.
- Re-scope and re-dispatch only the tasks that fail. Don't re-run the whole pipeline.

---

## 🔁 Layer 4 — Learn & Persist (compound the savings)

- Capture decisions, new contracts, and gotchas via [[self-learning]] and project
  memory, so the *next* large task starts with more precomputed context and less reading.
- If a pattern recurs, promote it into the relevant skill (or a new one) so it's
  retrieved, not re-derived.
- Keep `graphify-out` / `ai-context` fresh after structural changes so retrieval stays accurate.

---

## 📋 Execution Checklist

- [ ] Used precomputed context (graph / ai-context / KB) BEFORE reading any source
- [ ] Read targeted symbols/lines, not whole files, for understanding
- [ ] Set a context budget per phase; summarized-and-discarded large reads
- [ ] Decomposed into independent, scoped tasks with explicit file lists + contracts
- [ ] Each sub-agent got ONLY its minimal brief; returned a structured result
- [ ] Ran independent tasks in parallel; sequenced only real dependencies
- [ ] Verified via build + targeted tests + diff-only review (re-scoped failures only)
- [ ] Persisted decisions/contracts so the next task reads less
- [ ] Engineering standards ([[engineering-standards]]) held on every sub-task

---

## 🧪 Worked Example (concise)

**Task:** "Add a comfort-index widget end-to-end (Angular UI + jt-api-v2 endpoint + Influx query)."

1. **Retrieve:** read `graphify-out/GRAPH_REPORT.md` + `ai-context/{API_CONTRACTS,DATABASE_SCHEMA,WIDGET_MAPPING}.md`. Do **not** read the dashboard module wholesale.
2. **Plan → 3 scoped tasks:**
   - API: add `GET /comfort-index` (files: controller + service; contract: response DTO). Skill slice: nodejs/engineering-standards + CACHE_STRATEGY (cache with eviction).
   - Query: Influx/Timestream query (file: query builder; contract: input range → series). Skill slice: influxdb-patterns.
   - UI: widget component (files: 1 component + 1 service; contract: consumes the DTO). Skill slice: jouletrack-angular + design tokens.
3. **Dispatch** the 3 sub-agents; API+Query can run in parallel, UI depends on the DTO contract.
4. **Integrate + verify:** build, hit the endpoint, render the widget; diff-only review against the standards gate.
5. **Persist:** record the new DTO contract in ai-context/memory so the next widget reuses it.

Net effect: the orchestrator's context holds a 3-task plan + 3 small results — not the dashboard module, the API layer, and the query engine all at once.
