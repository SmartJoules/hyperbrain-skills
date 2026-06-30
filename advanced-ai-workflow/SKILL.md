---
name: advanced-ai-workflow
description: HyperBrain's default high-efficiency AI engineering workflow. Use at the start of any non-trivial development, research, review, debugging, or product-to-code task to target at least 40% developer efficiency improvement through fleet orchestration, retrieve-first context, repo-aware implementation, eval guardrails, and measured feedback loops.
---

# Advanced AI Workflow

**Purpose:** Turn HyperBrain into an engineering operating system, not a bag of isolated skills.
**Efficiency target:** Improve developer throughput by at least 40% on non-trivial work by reducing discovery time, duplicated context loading, review rework, and escaped defects.

---

## When to Use

Use this skill for:
- Features spanning more than one file or layer
- Debugging where root cause is not obvious
- Solved bugs that should become reusable team knowledge
- Code review or security/performance review
- Prototype-to-production planning
- LLM/RAG/agent feature changes
- Any task where multiple AI seats, repo context, or live connectors can shorten the path

Skip it for tiny one-line edits, obvious mechanical changes, or answers already known in-session.

---

## The 40% Efficiency Model

The workflow targets 40%+ improvement by compounding five gains:

| Lever | Expected gain | How |
|---|---:|---|
| Retrieve-first context | 10-20% | Use graph, local KB, `ai-context`, and targeted search before reading files |
| Fleet orchestration | 10-25% | Route research, implementation, and review to the right AI seat/model tier with `tokensmax` |
| Repo-aware harness | 5-15% | Bind generated code to real stack, schema, conventions, and anti-patterns |
| Shift-left review/evals | 5-15% | Add TDD, diff-only review, LLM evals, and guardrails before handoff |
| Learning loop | 5-10% | Persist decisions and reusable patterns so future tasks start warmer |

Measure it with cycle time, number of manual context-gathering steps, review iterations, test failures caught before handoff, token/cost spend, and reused knowledge artifacts.

---

## Core Loop

### 1. Classify the Work

Choose the lane:

| Lane | Primary skills |
|---|---|
| Product/spec/prototype to implementation | `proto-to-dejoule`, `prd-to-html-prototype`, `prompt-harness` |
| Multi-file engineering | `agentic-engineering`, `prompt-harness`, `engineering-standards` |
| AI/LLM/RAG/agent work | `prompt-engineering`, `rag-retrieval`, `agent-tool-design`, `llm-eval-guardrails` |
| DeJoule diagnostics/live data | `cpa-health`, `cpa-rca`, `iot-health`, `smartjoules-influxdb` |
| UI/frontend | `sj-ui-design-system`, `jouletrack-angular`, framework pattern skill |
| Review/debug/performance | `database-query-optimizer`, `engineering-standards`, `tdd-workflow` |
| Solved bug/postmortem learning | `bug-postmortem-learning`, `root-cause-analyzer`, `self-learning` |

### 2. Retrieve Before Reading

Use this order:

1. `AGENTS.md`, repo README, and package/build metadata
2. `graphify-out/GRAPH_REPORT.md`, `ai-context/*.md`, local KB, knowledge-base skills
3. Targeted `rg`/symbol searches
4. Small file windows around the target code
5. Full-file reads only for files that will likely change

Do not load whole subsystems for "understanding" if a graph, KB, or targeted search answers the question.

### 3. Route Work Through the Fleet

For any non-trivial build, research, or review task, use `tokensmax`:

1. Run `tokensmax status`.
2. Build routing options from the actual configured seats and model tiers.
3. Recommend the best option, including one token-saving option.
4. Wait for the user to choose unless they explicitly said to just do it.
5. Dispatch with `tokensmax run` or `tokensmax fleet`.
6. Report `tokensmax usage` after dispatch.

Use cheap/fast tiers for mechanical tasks, mid tiers for bounded implementation, and deep tiers for ambiguous design, architecture, safety, or correctness-critical work. Never hardcode model versions; resolve the current lineup from `tokensmax status`.

### 4. Implement With Repo-Aware Contracts

Before editing:
- Detect the repo type and framework.
- Identify the exact files/symbols/contracts to change.
- Reuse existing controllers, services, components, query helpers, styling tokens, and tests.
- Keep the diff scoped.
- Confirm before destructive DB/schema/production changes.

For DeJoule:
- JouleTRACK frontend: follow `jouletrack-angular` and `sj-ui-design-system`.
- jt-api-v2 / Sails backend: follow `prompt-harness`, `backend-knowledge-base`, and existing Sails service/model patterns.
- IoT/data pipelines: follow `iot-architecture`, `mqtt-patterns`, `kafka-patterns`, and `influxdb-patterns`.

### 5. Verify Before Handoff

Minimum gate:
- Run focused tests/builds for the changed surface.
- Run lint/typecheck when available and practical.
- Inspect the diff for unintended churn.
- For AI features, run or create eval cases and guardrails.
- For UI, verify behavior and layout with the browser/QA flow when a server exists.
- For live data claims, query the source instead of guessing.

### 6. Persist the Learning

After meaningful work:
- Add reusable decisions, API contracts, schema facts, and gotchas to the appropriate KB or memory artifact.
- After a bug is solved, use `bug-postmortem-learning` to write a postmortem, ask the user for KB-ingestion approval, and save only durable fix patterns.
- Update skill guidance when a pattern becomes repeatable.
- Keep graph/local context fresh after structural changes.

---

## Default Execution Plan

Use this compact plan unless the user gives a better one:

1. Detect repo and task lane.
2. Retrieve existing context with the cheapest source first.
3. If the task is non-trivial, route with `tokensmax`; otherwise do it locally.
4. Implement in small, contract-shaped changes.
5. Verify with focused tests/review/evals.
6. Report changed files, verification, residual risk, and any persisted learning.

---

## Anti-Patterns

- Reading large files before checking graph/KB/search.
- Letting one AI session do all research, build, and review when configured fleet seats exist.
- Dispatching workers without a crisp contract, allowed files, and done criteria.
- Generating code from generic patterns instead of the repo's actual architecture.
- Shipping LLM output without evals, grounding, output validation, and cost/rate guardrails.
- Reporting "40% faster" without measuring the baseline and follow-up signals.

---

## Completion Checklist

- [ ] Task lane selected and relevant skills loaded
- [ ] Context gathered retrieve-first
- [ ] Fleet routing considered for non-trivial work
- [ ] Exact files/contracts identified before editing
- [ ] Implementation follows repo conventions and `engineering-standards`
- [ ] Focused tests/build/review/evals completed or limitations stated
- [ ] Reusable learning persisted when applicable, with user approval for bug-fix KB ingestion
- [ ] Efficiency signals captured: time saved, fewer reads, parallel work, fewer review loops, or cost reduced
