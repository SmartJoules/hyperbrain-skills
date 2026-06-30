---
name: model-selection-runtime
description: Use when selecting AI model tiers for Pi.dev, Codex, Claude, tokensmax, custom coding agents, SDK/RPC workflows, or multi-agent fleets. Defines a Pi-like model selection algorithm that scores task complexity, risk, context size, tool needs, latency, cost, and verification requirements to route work to fast, balanced, deep-reasoning, or specialist models with escalation and downgrade rules.
---

# Model Selection Runtime

Use this skill to choose the smallest model that can safely complete the task, then escalate only when complexity, risk, or verification failures justify it.

## Core Principle

Default to the cheapest reliable model, not the biggest available model. Escalate for ambiguity, architecture, security, data risk, production impact, large context, or repeated failed verification.

## Inputs

Collect these signals before selecting a model:

- **Task type:** answer, edit, refactor, debug, review, architecture, migration, deployment, RCA, agent orchestration.
- **Complexity:** number of files, unknowns, cross-service dependencies, algorithmic reasoning, schema depth.
- **Risk:** auth/RBAC, customer data, production deployment, destructive query/command, migrations, billing, security, privacy, safety.
- **Context size:** short prompt, selected skill bodies, large repo windows, logs, traces, diffs, KB references.
- **Tool intensity:** shell, tests, browser, database, GitHub, cloud, MCP, graph queries, multi-agent handoff.
- **Latency target:** interactive/fast, normal, overnight/deep.
- **Cost budget:** low, balanced, high.
- **Verification demand:** unit tests, e2e, build, static checks, review, canary, human approval.

## Model Tiers

Use generic tier names so the workflow can run on Pi, Codex, Claude, Bedrock, or another provider without hardcoding model versions.

| Tier | Use for | Avoid for |
|---|---|---|
| `fast` | search, summarization, small docs, simple bug hints, formatting, command generation | architecture, security, multi-file edits |
| `balanced` | normal implementation, medium debugging, focused reviews, tests, repo-aware answers | high-risk auth/deploy/migration decisions |
| `deep` | architecture, ambiguous debugging, multi-service changes, security/RBAC, data migrations, complex planning | cheap repetitive subtasks |
| `specialist` | tool-heavy, long-context, code-review, vision/browser, graph/RAG, or provider-specific strengths | tasks outside that model's strength |

When a runtime exposes concrete models, map them into these tiers at startup from current provider metadata, `tokensmax status`, Pi config, or local agent configuration.

## Selection Algorithm

Score the task and choose the first tier that satisfies the threshold:

```text
score = complexity * 20
      + risk * 25
      + context_size * 15
      + tool_intensity * 10
      + ambiguity * 20
      + verification_demand * 10
      - latency_pressure * 10
      - cost_pressure * 10
```

Use 0-3 for each input:

- `0`: absent or trivial
- `1`: low
- `2`: medium
- `3`: high

Tier thresholds:

```text
0-35    -> fast
36-85   -> balanced
86-145  -> deep
146+    -> deep + specialist review or multi-agent split
```

## Mandatory Escalation

Escalate at least one tier when any of these are true:

- User asks for architecture, HLD/LLD, system design, or agent orchestration.
- Work touches authentication, authorization, RBAC, secrets, customer data, billing, production deployment, migrations, or destructive operations.
- Work mentions `DELETE`, `DROP`, `TRUNCATE`, `FLUSH`, broad `UPDATE`, graph `DELETE`, infrastructure delete, cache flush, or irreversible control changes.
- The first attempt fails verification twice.
- The task spans more than one service or more than five meaningful files.
- The answer requires reconciling conflicting evidence.
- A subagent or lower-tier model reports low confidence.

Use `deep` immediately for RBAC/auth, security review, deployment planning, graph ontology migrations, destructive-operation runbooks, and production incident RCA unless the user explicitly asks for a cheap draft. Also load `production-safety-guards` and refuse agent-side execution for destructive operations.

## Downgrade Rules

Downgrade to a cheaper tier when:

- The plan is already approved and the next step is mechanical.
- The task is formatting, search, summarization, command drafting, or simple test log triage.
- A deep model produced a stable plan and workers only need bounded implementation.
- Verification is deterministic and cheap.

## Multi-Agent Routing

For fleet work, assign tiers by role:

| Role | Default tier |
|---|---|
| Planner / architect | `deep` |
| Repo scanner / context gatherer | `fast` or `balanced` |
| Implementer | `balanced`, escalate to `deep` for complex files |
| Test fixer | `balanced` |
| Security/RBAC reviewer | `deep` |
| Integration reviewer | `deep` |
| Documentation updater | `fast` or `balanced` |

Use `agent-context-manager` to keep each worker's context small. Use `agent-integration-reviewer` on `deep` for final merge and risk review.

## Pi-Style Runtime Flow

1. Use `skill-loading-runtime` to select skills first.
2. Estimate model score from the user request, selected skills, repo signals, and risk surfaces.
3. Choose the initial tier.
4. Run the plan or task.
5. Verify results.
6. Escalate when verification fails or hidden complexity appears.
7. Record the model tier, reason, and any escalation in the final response or machine-readable output.

## Output Contract

Return model selection in this shape for SDK/RPC agents:

```json
{
  "modelSelection": {
    "tier": "balanced",
    "reason": "Medium implementation with repo context and deterministic tests",
    "score": 72,
    "signals": {
      "complexity": 2,
      "risk": 1,
      "contextSize": 2,
      "toolIntensity": 2,
      "ambiguity": 1,
      "verificationDemand": 2,
      "latencyPressure": 1,
      "costPressure": 1
    },
    "escalationPolicy": "Escalate to deep if tests fail twice or auth/RBAC code is touched"
  }
}
```

## Completion Checklist

- The selected tier is named with a short reason.
- High-risk work is escalated before implementation, not after damage.
- Cheap models handle bounded subtasks whenever safe.
- Failed verification triggers escalation or narrower context, not repeated blind retries.
- Final output includes selected tier, checks run, and whether any escalation occurred.
