---
name: agent-tool-design
description: Design LLM agents and their tools. Use when building an agentic feature — defining the tool registry, tool schemas, the agent loop, model-tier routing, grounding, and observability. Covers tool granularity and naming, input/output schema design, the tool-use loop (turn limits, parallelism, timeouts, truncation), cost-tiered model routing, error handling for tools, and agent tracing. Grounded in the DeJoule stack (Lumen's Bedrock agent + tool-registry of graph/hvac/energy/cohort tools). Use whenever the question is "how should this agent's tools / loop be designed".
---

# Agent & Tool Design

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Design agent tool-registries and loops that are correct, cheap, and debuggable
**Version:** 1.0.0

---

## 🎯 When to Use

Building an agentic LLM feature: the tools the model can call, their schemas, the loop, model routing, grounding, and tracing. Pairs with [[prompt-engineering]] (the agent's system/tool prompts), [[rag-retrieval]] (retrieval-as-a-tool), [[llm-eval-guardrails]] (tool-use eval + action allow-listing), [[agentic-engineering]] (orchestration at the dev-workflow level), and [[lumen-knowledge-base]] (a real Bedrock agent + tool-registry). Enforce [[engineering-standards]].

> **The tool registry IS the agent's capability surface.** Good tools = grounded, cheap, reliable answers. Vague/overlapping/unbounded tools = wandering, expensive, wrong ones.

---

## 1. Tool granularity & boundaries

- One tool = one **clear, composable** capability. Prefer a few sharp tools over many fuzzy ones.
- Tools should map to **how data is actually fetched** (a query, a graph traversal, an API) — not to high-level intents the model can compose. Lumen splits graph (`graph_match`, `graph_feeds`), telemetry (`hvac_query`), energy, cohort — each grounded in one source.
- Avoid overlap (two tools that could answer the same thing → the model dithers). If two tools are always called together, consider merging.

## 2. Tool schemas (this is a contract)

- **Name**: verb_noun, unambiguous (`cohort_rank`, not `analyze`).
- **Description**: say *when* to use it and *when not to* — the model routes on this. Include units, defaults, and constraints.
- **Inputs**: typed, minimal, with sane defaults (e.g. `time_range='-1h'`). Validate them server-side (the model will pass garbage sometimes). Use the provider's native tool/function schema (Bedrock `toolConfig`, etc.).
- **Output**: compact + structured + grounded. Return IDs/labels the model can cite. **Truncate** large results (Lumen caps at `MAX_TOOL_RESULT_CHARS=1500`) and include a numeric_summary instead of dumping rows.

## 3. The agent loop

- **Bounded turns** (Lumen `MAX_TURNS=6`): cap tool-use iterations so it can't loop forever.
- **Parallel tools per turn** when independent (Lumen `MAX_PARALLEL_TOOLS_PER_TURN=6`) — faster, cheaper than serial.
- **Per-tool timeout** (Lumen `TOOL_TIMEOUT_MS=45s`): a slow/failed tool returns "treat as a gap, not a finding", never hangs the loop.
- **Repeat/empty guards**: block re-calling the same tool with the same args; on empty result, instruct a different field/tool rather than retrying identically.
- **Stop conditions**: model signals done, turn cap hit, or budget exhausted.

## 4. Model-tier routing (cost discipline)

- Classify the request first (cheap model), then route to the right tier — lookups → cheap; analytics → mid; multi-hop/RCA → strong; verification → a stronger judge; last-resort → top model. (Lumen: Qwen 32B → Haiku 4.5 → Qwen 235B → Sonnet verify → Opus escalate.)
- Size by **footprint** (nodes × fields × window), not just keywords.
- **Guard escalation**: don't let one query bounce up to the top tier repeatedly (cost runaway) — see [[llm-eval-guardrails]].

## 5. Grounding & verification

- Every concrete claim must trace to a tool result / graph / retrieved doc. Run a **verify pass** (stronger model judges the answer vs the evidence) before returning — rewrite or fall back on violation. (Lumen's verify-gate.)
- Derive facts from **structure, not labels** (Lumen decides a pump's role from FEEDS/COMMANDS edges, never its name).

## 6. Safety

- **Allow-list** tool actions; read-only by default; any write/destructive tool requires explicit confirmation (per [[engineering-standards]] / [[engineering-ai-assistant]]). An injected instruction must not be able to invoke a harmful tool.
- Validate every tool input at the boundary; never pass model output to a shell/SQL/query without parameterization + validation.
- Long-lived connections the tools use (DB/Redis/graph) follow the connection standards (singleton/pool, retry+backoff, graceful degradation).

## 7. Observability (you cannot debug an agent you can't see)

- **Trace every run**: intent, tier, footprint, each tool call + args + result size + latency, violations, final answer, tokens/cost. Lumen writes one JSON line per chat to a trace file — replicate this.
- Emit cost/token **telemetry** per run (Lumen's `meta` event). Add metrics (counts, latency, lag) for production.
- Make traces replayable for eval ([[llm-eval-guardrails]]).

---

## ✅ Checklist
- [ ] Tools are sharp, non-overlapping, mapped to real data sources
- [ ] Each tool: clear name + when-to-use description + typed/validated inputs + compact grounded output (truncated)
- [ ] Loop bounded: turn cap, per-tool timeout, parallel where independent, repeat/empty guards
- [ ] Model-tier routing by footprint; escalation guarded
- [ ] Verify-gate: claims grounded in evidence; roles from structure not labels
- [ ] Actions allow-listed; read-only default; writes confirm-gated; inputs validated
- [ ] Full per-run trace + cost/token telemetry; traces replayable for eval
