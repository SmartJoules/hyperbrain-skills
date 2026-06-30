---
name: skill-loading-runtime
description: Use when designing or implementing Pi-like skill loading for Codex, Pi.dev, custom coding agents, CLIs, SDK/RPC agents, or orchestration systems. Defines progressive skill discovery: scan SKILL.md frontmatter first, rank skills from user intent and repo signals, load only selected skill bodies, then hand off to model-selection-runtime and load references/scripts/assets only on demand while enforcing context budgets, trust boundaries, and verification.
---

# Skill Loading Runtime

Use this skill to make HyperBrain skills load like Pi-style skills: metadata first, selected instructions second, deep resources only when needed.

## Runtime Goal

Build an agent runtime that can discover many skills without stuffing every skill into the prompt. The runtime must preserve three layers:

1. **Index layer:** read only each `SKILL.md` frontmatter `name` and `description`.
2. **Instruction layer:** load full `SKILL.md` only for selected skills.
3. **Resource layer:** load `references/`, inspect `scripts/`, or use `assets/` only when the loaded skill explicitly calls for them.

## Skill Folder Contract

Each skill should follow this shape:

```text
skill-name/
  SKILL.md
  references/
  scripts/
  assets/
```

`SKILL.md` must start with:

```yaml
---
name: skill-name
description: Clear trigger text covering what the skill does and when to use it.
---
```

Keep `description` specific because it is the main routing surface. Include technologies, repos, task types, and risk surfaces that should trigger the skill.

## Loading Algorithm

Use this sequence for every non-trivial request:

1. Read repo-level instructions first: `AGENTS.md`, README, package/build metadata, and known KB indexes.
2. Build or refresh the skill index by scanning skill folders for frontmatter only.
3. Extract routing signals from the request:
   - Explicit skill names or words like "Pi", "RBAC", "Neptune", "PrimeNG", "K8s", "postmortem".
   - File signals such as `angular.json`, `deployment.yaml`, `api/controllers`, `.ttl`, `.rq`, `Dockerfile`, or `package.json`.
   - Risk signals such as authentication, authorization, production data, destructive query, delete/drop/truncate/flush, deployment, migration, billing, or customer-facing UI.
4. Rank skills with this priority:
   - Explicitly named skills.
   - Safety/security/data/deployment skills.
   - Repo-specific KB skills.
   - Workflow harness skills.
   - General framework/pattern skills.
5. Load only the smallest useful set of full `SKILL.md` bodies.
6. Run `model-selection-runtime` after skill selection to choose the smallest safe model tier for the selected skill stack.
7. Follow each loaded skill's resource instructions. Do not load all references just because a folder exists.
8. Produce a plan, execute, verify, and record reusable learnings when appropriate.

## Ranking Heuristic

Use a simple scoring model when implementing a loader:

```text
score = explicit_name_match * 100
      + description_keyword_match * 10
      + repo_signal_match * 15
      + risk_surface_match * 20
      + recent_success_or_memory_match * 8
      - context_cost_penalty
```

Select the top skills until the task is covered. Prefer three to five skills for most tasks. Add more only when the task spans multiple risk surfaces.

## Default Skill Stack

For ambiguous or large engineering tasks, start with:

- `advanced-ai-workflow`
- `production-safety-guards`
- `model-selection-runtime`
- `agent-planning-harness`
- `prompt-harness`
- `self-verification`

Then add domain skills from routing signals:

- Pi/custom agent runtime: `pi-coding-agent`, `agent-tool-design`, `prompt-engineering`
- Inference/LLM serving: `inference-engineering`, `model-selection-runtime`, `prompt-engineering`, `llm-eval-guardrails`
- Multi-agent execution: `agent-orchestration`, `agent-fleet-runner`, `agent-context-manager`
- Frontend/JouleTRACK: `jouletrack-angular`, `sj-ui-design-system`, `frontend-telemetry`
- Data modeling/schema design: `data-modeling-algorithm`, `database-patterns`, `database-query-optimizer`
- API/RBAC/auth: `api-design`, `dejoule-rbac`, `dejoule-authentication`, `security-review`
- Ontology/graph: `ontology-service-knowledge-base`, `neptune-graph`, `brick`
- Deployment: `sj-k8s-knowledge-base`, `deployment-patterns`
- Production/destructive changes: `production-safety-guards`, `security-review`, `self-verification`
- Bug learning: `bug-postmortem-learning`, `systematic-debugging`, `self-learning`

## Context Budget Rules

- Load frontmatter for all skills freely.
- Load full skill bodies only when they influence the task.
- Load references by path and purpose, not by directory sweep.
- Summarize long loaded references into a working note before execution.
- Drop low-relevance skills when context becomes tight.
- Preserve decisions, selected skills, files touched, and verification status during compaction.

## Runtime Output Contract

A custom loader should return:

```json
{
  "selectedSkills": [
    {
      "name": "skill-name",
      "reason": "Why it was selected",
      "loaded": true,
      "resources": ["references/example.md"]
    }
  ],
  "modelSelection": {
    "tier": "balanced",
    "reason": "Medium implementation with deterministic checks",
    "score": 72,
    "escalationPolicy": "Escalate to deep if verification fails twice or high-risk files are touched"
  },
  "rejectedSkills": [
    {
      "name": "other-skill",
      "reason": "Matched weakly but not needed"
    }
  ],
  "contextBudget": {
    "estimatedTokens": 0,
    "dropped": []
  },
  "nextStep": "plan | execute | ask_user | verify"
}
```

## Implementation Notes

- Use a structured frontmatter parser where available. Avoid brittle string parsing for production loaders.
- Cache the frontmatter index by content hash or modified time.
- Treat skills as trusted only when they come from an approved local repo, package, or signed source.
- Never include secrets, credentials, production customer data, or private tokens in skill files.
- For Pi.dev or SDK/RPC agents, expose the selected skill list in JSON so orchestrators can audit why context was loaded.

## Verification Checklist

- A request can select skills without loading every `SKILL.md`.
- Explicit skill names always win over fuzzy matches.
- High-risk surfaces add security, RBAC, deployment, or verification skills automatically.
- Destructive or production-affecting signals add `production-safety-guards` automatically.
- Model tier selection runs after skill selection and before implementation.
- References are loaded only when named by the selected skill or required by the task.
- Final output reports selected skills, selected model tier, checks run, and any skipped references or unresolved assumptions.
