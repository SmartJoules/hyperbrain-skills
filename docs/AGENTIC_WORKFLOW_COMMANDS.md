# Agentic Workflow Commands

This guide shows how to use the HyperBrain agentic workflow, including Pi-like skill loading, planning, multi-agent execution, repo-specific KB skills, and verification.

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
Use skill-loading-runtime, advanced-ai-workflow, agent-planning-harness, prompt-harness, and self-verification.

Goal:
<your task>

Load skills like Pi:
1. Scan skill frontmatter first.
2. Rank skills by user intent, repo signals, and risk.
3. Load only selected SKILL.md files.
4. Load references/scripts/assets only on demand.
5. Plan, execute, verify, and summarize.
```

## Pi-Style Coding Agent

Use when working with Pi.dev, a custom coding agent, or a CLI/SDK/RPC agent runtime:

```text
Use pi-coding-agent and skill-loading-runtime.

Build or run a Pi-style coding agent workflow for this repo:
- Read AGENTS.md and README first.
- Scan HyperBrain skill frontmatter.
- Select the smallest useful skill set.
- Use agent-planning-harness before coding.
- Use self-verification before final output.
- Report selected skills, changed files, and checks run.
```

## Multi-Agent Execution

Use this for large features, migrations, refactors, audits, or work that benefits from parallel research/review/build lanes:

```text
Use skill-loading-runtime, agent-planning-harness, agent-orchestration, agent-fleet-runner, agent-context-manager, agent-delegation-contracts, agent-integration-reviewer, and self-verification.

Goal:
<large task>

Create worker context packets, assign agents, define acceptance criteria, run verification, and merge outputs safely.
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
rg -n "skill-loading-runtime|advanced-ai-workflow|agent-planning-harness|pi-coding-agent" .
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
- Changed files
- Tests/checks run
- Risks or follow-ups
- Any reusable KB learned, and whether ingestion needs approval
```
