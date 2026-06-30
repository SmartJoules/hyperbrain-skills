---
name: llm-eval-guardrails
description: Evaluate and guard production LLM/AI features. Use when shipping or changing an LLM feature and you need to prove it works (eval sets, LLM-as-judge, grounding/hallucination checks, regression tests) and keep it safe (PII/secret redaction, prompt-injection defense, output validation, rate + cost limits, fallbacks). Grounded in the DeJoule stack (Lumen's verify-gate, Bedrock cost telemetry). Use whenever the question is "is this AI output correct/safe" or "how do I stop the model from hallucinating / leaking / over-spending".
---

# LLM Eval & Guardrails

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Measure LLM feature quality and constrain its failure modes before/at runtime
**Version:** 1.0.0

---

## 🎯 When to Use

Shipping or changing any LLM feature. Pairs with [[prompt-engineering]] (what you're evaluating), [[rag-retrieval]] (retrieval/faithfulness eval), [[agent-tool-design]] (tool-use eval), and [[lumen-knowledge-base]] (live verify-gate + eval-invariants). Enforce [[engineering-standards]] (rate limits, cost caps, error handling).

> **You can't ship what you can't measure.** Treat LLM features like any other code: an eval set is the test suite; guardrails are the input validation + error handling.

---

## PART A — Evaluation

### A1. Build an eval set (the test suite for AI)
- Curate **golden examples**: input → expected behavior (exact answer, or rubric/criteria for open-ended).
- Cover **happy path + edge + adversarial + "should refuse / say unknown"** cases. Mine real traces (Lumen writes `/tmp/lumen-trace.jsonl`) and past failures.
- Version it in the repo; run it in CI on every prompt/model/retrieval change. Treat a drop as a failing test.

### A2. Scoring methods (match to task)
| Output type | How to score |
|-------------|--------------|
| Exact/structured | Deterministic assert (==, schema, set match) — cheapest, do this when possible |
| Retrieval | recall@k / precision@k / MRR vs expected sources ([[rag-retrieval]]) |
| Open-ended prose | **LLM-as-judge** with an explicit rubric; use a *stronger* model than the answerer (Lumen verifies Qwen/Haiku answers with Sonnet) |
| Faithfulness | Does every claim trace to provided context? (grounding check, below) |

### A3. Grounding / hallucination check (the verify-gate pattern)
- After the model answers, **extract concrete claims** (numbers, names, roles) and check each against the grounding (retrieved context / tool results / graph). Lumen does exactly this before streaming.
- On violation: rewrite grounded-facts-only, or fall back to a safe answer — never emit the unverified claim.
- Keep `eval-invariants` (properties that must always hold, e.g. "an 'off' asset is never reported as 'running'").

### A4. Regression + drift
- Re-run the eval set on model upgrades, prompt edits, retrieval changes (the same model that writes/answers shouldn't be the only one reviewing — use an independent judge).
- Track scores over time; alert on regressions. Sandbox/replay traces so eval doesn't hit prod data.

---

## PART B — Guardrails (runtime safety)

### B1. Input
- **Validate** request inputs at the boundary (schema, ranges) before they reach the model.
- **Prompt-injection defense**: isolate untrusted/retrieved content in a data block; re-assert system rules; don't let input change role/tools (see [[prompt-engineering]] §7).
- **PII/secret redaction**: strip secrets/credentials/keys from anything sent to the model; never log them.

### B2. Output
- **Validate** model output before use/display (schema for structured; grounding check for factual).
- **Allow-list actions**: if the model can trigger actions/tools, the action set is constrained and authorized — an injected instruction can't reach a destructive op (confirm-gate destructive ops, per [[engineering-standards]] / [[engineering-ai-assistant]]).
- **Output filtering**: block leaked secrets, unsafe content, or off-domain answers before they reach the user.

### B3. Cost & abuse control
- **Rate-limit** expensive LLM endpoints per user/tenant (token bucket; Lumen's `/chat/stream` currently lacks this — a known gap). Return clean 429, never 500.
- **Cost caps / budgets**: meter tokens+cost per request (Lumen emits a `meta` event); cap max tokens/turns; guard model **escalation** so a pathological query can't loop Opus and burn $$.
- **Timeouts + retries with backoff** on the model call; circuit-break on provider outage.

### B4. Reliability & fallbacks
- Always handle the model failing/timing out: degrade gracefully (cached/last-known/"try again"), never crash the request. Loading + error + empty + partial states in UI ([[engineering-standards]]).
- **Observability**: structured trace per call (inputs hash, model/tier, tokens, cost, latency, tools, verdict). Without traces you can't debug AI.

---

## ✅ Checklist
- [ ] Versioned eval set (happy + edge + adversarial + refusal) run in CI on every change
- [ ] Deterministic scoring where possible; LLM-as-judge (stronger model) for open-ended
- [ ] Grounding/verify-gate: claims checked vs context; unverified output never emitted
- [ ] Inputs validated + PII/secrets redacted; injection isolated; nothing secret logged
- [ ] Output validated; actions allow-listed; destructive ops confirm-gated
- [ ] Rate limits + cost/token caps + escalation guard on expensive endpoints
- [ ] Timeouts/retries/fallbacks; graceful UI states
- [ ] Per-call structured trace for observability
