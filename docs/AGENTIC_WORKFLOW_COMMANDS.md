# Agentic Workflow Commands

This guide shows how to use the HyperBrain agentic workflow, including Pi-like skill loading, model selection, planning, multi-agent execution, repo-specific KB skills, and verification.

## Update And Install

Run these from the `hyperbrain-skills` repo:

```bash
cd /Users/atif-salafi/Desktop/workspace/office-space/hyperbrain-skills
git pull origin main
./install.sh --assistant codex
```

Install for other assistants:

```bash
./install.sh --assistant claude
./install.sh --assistant cursor
./install.sh --assistant copilot
```

## Default Prompt

Use this for most non-trivial engineering work:

```text
Use skill-loading-runtime, model-selection-runtime, production-safety-guards, advanced-ai-workflow, agent-planning-harness, prompt-harness, and self-verification.

Goal:
<your task>

Load skills like Pi:
1. Scan skill frontmatter first.
2. Rank skills by user intent, repo signals, and risk.
3. Load only selected SKILL.md files.
4. Select the smallest safe model tier: fast, balanced, deep, or specialist.
5. Load production-safety-guards for production/destructive/customer-data work.
6. Do not run destructive delete/drop/truncate/flush/broad-update commands as an agent; warn and draft dry-run/runbooks only.
7. Load references/scripts/assets only on demand.
8. Plan, execute, verify, and summarize.
```

## Production Safety Guards

Use whenever a task touches production, customer data, databases, graph writes, deployments, migrations, auth/RBAC, alerts, device control, or irreversible operations:

```text
Use production-safety-guards, model-selection-runtime, and self-verification.

Task:
<production or destructive task>

Rules:
- Do not execute DELETE, DROP, TRUNCATE, FLUSH, broad UPDATE, graph DELETE, Kubernetes/cloud delete, or irreversible control commands.
- Warn the user three times: destructive risk, blast radius, and agent non-execution.
- Provide read-only preview/dry-run first.
- If still needed, draft only a DO NOT RUN WITHOUT HUMAN APPROVAL runbook with backup, rollback, scope, ticket, and two-person review.
```

## Pi-Style Coding Agent

Use when working with Pi.dev, a custom coding agent, or a CLI/SDK/RPC agent runtime:

```text
Use pi-coding-agent, skill-loading-runtime, and model-selection-runtime.

Build or run a Pi-style coding agent workflow for this repo:
- Read AGENTS.md and README first.
- Scan HyperBrain skill frontmatter.
- Select the smallest useful skill set.
- Select the smallest safe model tier and escalation policy.
- Use agent-planning-harness before coding.
- Use self-verification before final output.
- Report selected skills, changed files, and checks run.
```

## Multi-Agent Execution

Use this for large features, migrations, refactors, audits, or work that benefits from parallel research/review/build lanes:

```text
Use skill-loading-runtime, model-selection-runtime, agent-planning-harness, agent-orchestration, agent-fleet-runner, agent-context-manager, agent-delegation-contracts, agent-integration-reviewer, and self-verification.

Goal:
<large task>

Create worker context packets, assign agents, select model tiers per worker, define acceptance criteria, run verification, and merge outputs safely.
```

## Model Selection

Use when you need Pi-like model/tier routing before work starts:

```text
Use model-selection-runtime and skill-loading-runtime.

Task:
<task>

Select the smallest safe model tier:
- fast for search, summaries, formatting, and mechanical changes.
- balanced for bounded implementation, tests, and focused reviews.
- deep for architecture, security, RBAC, deployments, migrations, production RCA, or ambiguous debugging.
- specialist for long-context, graph/RAG, browser/vision, or tool-heavy workflows.

Return the tier, score, rationale, and escalation policy before execution.
```

## Bug Fix And Postmortem Learning

Use when a bug is solved or needs RCA:

```text
Use root-cause-analyzer, bug-postmortem-learning, self-learning, and long-term-memory.

Analyze this bug:
<bug details>

Find root cause, fix pattern, regression test, and ask before ingesting reusable KB.
```

## DeJoule Ontology, Neptune, Brick

Use for semantic graph, SPARQL, RDF, Brick Schema, Neptune, and on-prem Apache Jena/Fuseki work:

```text
Use ontology-service-knowledge-base, neptune-graph, brick, skill-loading-runtime, and self-verification.

Task:
<ontology / SPARQL / Neptune / Brick schema task>
```

## Kubernetes Deployments

Use for services that should deploy through the shared `sj-k8s` patterns:

```text
Use sj-k8s-knowledge-base, devops-deployment-planner, deployment-patterns, skill-loading-runtime, and self-verification.

Task:
<new service deployment / manifest / Helm / EKS task>
```

## RBAC And Authentication

Use for API permissions, UI guards, auth flows, MFA, JWT, sessions, and sensitive access changes:

```text
Use dejoule-rbac, dejoule-authentication, security-review, api-design, skill-loading-runtime, and self-verification.

Task:
<API or UI RBAC/auth task>
```

## JouleTRACK Frontend

Use for Angular, PrimeNG, Boxicons, telemetry, and JouleTRACK UI work:

```text
Use jouletrack-angular, sj-ui-design-system, frontend-telemetry, skill-loading-runtime, and self-verification.

Task:
<PrimeNG / Angular / UI task>

Rules:
- Follow PrimeNG.
- Use Boxicons.
- Add Google Analytics tracking for every frontend interaction.
```

## Skill Loader Output Contract

When building an agent runtime, return selected skills in a machine-readable shape:

```json
{
  "selectedSkills": [
    {
      "name": "skill-loading-runtime",
      "reason": "Needed for Pi-like progressive skill loading",
      "loaded": true,
      "resources": []
    }
  ],
  "modelSelection": {
    "tier": "balanced",
    "reason": "Medium implementation with deterministic verification",
    "score": 72,
    "escalationPolicy": "Escalate to deep if verification fails twice or auth/RBAC code is touched"
  },
  "rejectedSkills": [],
  "contextBudget": {
    "estimatedTokens": 0,
    "dropped": []
  },
  "nextStep": "plan"
}
```

## Verification Commands

Run these after editing skills or docs:

```bash
git status --short --branch
git diff --check
node -e "JSON.parse(require('fs').readFileSync('package.json','utf8')); console.log('package ok')"
find . -maxdepth 2 -name SKILL.md -print
rg -n "skill-loading-runtime|model-selection-runtime|production-safety-guards|advanced-ai-workflow|agent-planning-harness|pi-coding-agent" .
```

If the official skill validator is available with PyYAML installed:

```bash
python3 /Users/atif-salafi/.codex/skills/.system/skill-creator/scripts/quick_validate.py skill-loading-runtime
```

## Recommended Completion Report

Ask the agent to finish with:

```text
Final response:
- Selected skills
- Selected model tier and escalation policy
- Changed files
- Tests/checks run
- Risks or follow-ups
- Any reusable KB learned, and whether ingestion needs approval
```
