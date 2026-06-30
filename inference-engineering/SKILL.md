---
name: inference-engineering
description: Use when designing, building, reviewing, or optimizing production inference systems for LLMs, ML models, RAG, agents, Bedrock/OpenAI/Claude/Qwen providers, streaming chat, structured output, tool calling, model routing, batching, caching, retries, rate limits, eval gates, observability, cost/latency controls, prompt/model versioning, fallback behavior, or safe AI serving in DeJoule/Lumen/JouleTRACK workflows.
---

# Inference Engineering

Use this skill for production AI inference paths. Treat inference as a distributed system with contracts, budgets, telemetry, guardrails, and rollback, not as a single model call.

## Core Stack

Pair this skill with:

- `model-selection-runtime` for tier routing.
- `prompt-engineering` for prompt contracts.
- `llm-eval-guardrails` for correctness, safety, and regression gates.
- `agent-tool-design` for tool schemas and agent loops.
- `rag-retrieval` for grounding and retrieval quality.
- `production-safety-guards` for production/customer-data/destructive actions.
- `lumen-knowledge-base` for DeJoule/Lumen Bedrock + Neptune + SSE chat patterns.

## Inference Contract

Before implementation, define:

- **Input contract:** user text, context snapshot, retrieved evidence, tool state, tenant/site/user auth, locale, and feature flags.
- **Output contract:** JSON schema, UI text, citations, tool calls, confidence, refusal/error shape, and streaming events.
- **Model contract:** provider, tier, temperature, max tokens, stop conditions, timeout, retry policy, and fallback model.
- **Safety contract:** PII/secret handling, prompt-injection isolation, allowed tools/actions, RBAC/site scope, and production guardrails.
- **Eval contract:** golden cases, adversarial cases, regression threshold, judge model independence, and release gate.

## Model Routing

Use `model-selection-runtime` first:

- `fast`: intent classification, routing, summarization, simple extraction.
- `balanced`: normal answer generation, bounded code/doc generation, structured transforms.
- `deep`: ambiguous reasoning, architecture, RCA, auth/RBAC, security, graph ontology, complex tool plans.
- `specialist`: long-context, vision/browser, graph/RAG-heavy, code-review, or provider-specific strengths.

Never hardcode model versions in app logic. Resolve current provider IDs through configuration, feature flags, or model registry.

## Prompt And Context

- Version prompts like code.
- Keep stable system/developer instructions before cache points when provider prompt caching exists.
- Separate trusted instructions from untrusted retrieved/user content.
- Keep retrieved evidence compact, cited, and scoped.
- Avoid sending secrets, raw credentials, or unnecessary customer data.
- Keep temperature low for structured output, control decisions, data transforms, and safety-sensitive responses.

## Structured Output

For machine-consumed outputs:

- Require JSON schema or strongly typed object validation.
- Reject or repair invalid output through a bounded retry.
- Validate enum/action names against allow-lists.
- Treat model output as untrusted until parsed and validated.
- Include a safe fallback response when parsing fails.

## Tool Calling

- Use narrow tools with explicit schemas and side-effect labels: `read`, `write`, `destructive`, `external`.
- Require `production-safety-guards` before any write/destructive tool call.
- Enforce tenant/site/RBAC scope outside the model.
- Cap loop turns, parallel tool calls, and tool output size.
- Log every tool request, result summary, latency, and error class.

## Latency And Cost Controls

- Add timeouts at provider call, tool call, request, and stream levels.
- Use request budgets: max tokens, max tool turns, max retries, max retrieved chunks.
- Cache stable prompts, retrieval snapshots, embeddings, and deterministic classification results.
- Prefer streaming for long answers, but preserve final validated state.
- Use batching only when it does not break tenant isolation, latency SLOs, or per-item traceability.
- Track cost by feature, tenant/site, model tier, and request type.

## Reliability Pattern

Use this order:

1. Validate input and auth scope.
2. Load context/retrieval.
3. Select model tier.
4. Build prompt/tool contract.
5. Execute inference with timeout and trace ID.
6. Validate output.
7. Retry once with targeted repair if validation fails.
8. Fall back to safe response or higher tier if allowed.
9. Record telemetry and eval sample.

## Observability

Log structured telemetry:

- Request ID, user/site/tenant hash, feature, model tier, provider, prompt version.
- Input/output token counts, latency, cost estimate, cache hit, retry count.
- Retrieval IDs/citations, tool calls, validation status, fallback path.
- Safety flags: PII redaction, injection detected, RBAC/site-scope decision.

Do not log raw secrets, credentials, or sensitive customer data.

## Eval And Release Gates

Before shipping inference changes:

- Add golden and adversarial eval cases.
- Run regression on prompt/model/retrieval/tool changes.
- Use an independent judge or deterministic assertions where possible.
- Block release on schema failures, unsupported tool calls, unsafe content leakage, missing citations, or cost/latency regression beyond threshold.
- Canary by feature flag, tenant/site, or user cohort.

## DeJoule/Lumen Notes

- For JouleTRACK chat/AI UI, use SSE/streaming with loading, partial, error, retry, and final states.
- For Bedrock/Lumen flows, keep tool registry schemas stable and trace every tool call.
- For Neptune/RAG answers, cite graph/retrieval evidence and do not invent live telemetry values.
- For RBAC/site-scoped answers, enforce access in backend services before inference.
- For alerts or control workflows, require production safety and human approval for irreversible actions.

## Final Checklist

- Model tier and prompt version are explicit.
- Input, output, tool, safety, and eval contracts are defined.
- Output is parsed/validated before use.
- Timeouts, retries, fallback, rate limits, and cost caps are in place.
- Telemetry includes trace ID, model tier, tokens, latency, cost, validation, and fallback.
- Eval gate covers correctness, safety, regression, and cost/latency.
