---
name: agent-orchestration
description: Use when planning, creating, allocating, delegating to, coordinating, or reviewing multiple AI agents or subagents: agent allocation, agent creation, planning agents, specialist agents, context management, orchestration loops, delegation contracts, handoffs, verification gates, worktree isolation, and multi-agent execution across engineering, research, QA, review, DevOps, architecture, RCA, RBAC, ontology, or frontend/backend work.
---

# Agent Orchestration

**Purpose:** Turn one vague AI task into a managed team of focused agents with clear roles, small context packets, safe permissions, and a real integration/verification gate.

Use this with `advanced-ai-workflow` for the operating model, `agentic-engineering` for low-token execution, `tokensmax` for routing to real agent seats, and `agent-tool-design` when building runtime LLM agents and tools.

## When to Orchestrate

Create an agent plan when the task has independent workstreams, high ambiguity, cross-repo impact, architecture risk, review/security needs, or enough surface area that one context window would get noisy.

Skip orchestration for tiny single-file fixes, obvious mechanical edits, or tasks already fully understood in the active context.

## Core Roles

- **Planning Agent:** Convert the goal into workstreams, dependencies, risks, acceptance criteria, and the integration plan.
- **Research Agent:** Read-only discovery of code, docs, schemas, tickets, logs, PR history, or external references. Return evidence with file paths, line numbers, URLs, or query results.
- **Architecture Agent:** Produce HLD/LLD, API contracts, data model choices, ADRs, sequence diagrams, and tradeoffs.
- **Implementation Agent:** Own one bounded code surface: backend, frontend, database, DevOps, ontology, RBAC, alerts, tests, or migration.
- **QA Agent:** Build or run verification: unit, integration, e2e, browser QA, fixtures, regression cases, and release checks.
- **Security/Review Agent:** Inspect diffs, auth/RBAC, injection risk, secrets, permissions, data exposure, reliability, and test gaps.
- **Integrator Agent:** Merge outputs, reconcile conflicts, run final checks, and produce the handoff.

## Allocation Rules

Allocate by independence, risk, and context locality:

- Give one agent one mission and one ownership boundary. Avoid two write agents editing the same files unless an integrator explicitly sequences them.
- Prefer read-only agents for research, review, RCA, logs, and design discovery.
- Use write agents only with a scoped repo/path, branch/worktree expectation, files allowed, and verification command.
- Send shared contracts first to a planner or architect: API shape, DB schema, RBAC policy, event topic, ontology class, UI state contract.
- Use specialists for fragile domains: `dejoule-rbac`, `dejoule-authentication`, `ontology-service-knowledge-base`, `neptune-graph`, `brick`, `jouletrack-angular`, `dejoule-geofencing-alerts`, or DevOps skills.
- Keep live production, customer data, credentials, destructive DB updates, and cloud writes out of delegated tasks unless the user explicitly approves.

## Agent Creation Contract

Every created or delegated agent must receive a compact brief:

```text
Agent name:
Mission:
Scope:
Non-scope:
Required context:
Files/repos:
Tools allowed:
Write permissions:
Deliverables:
Output format:
Constraints:
Verification:
Stop conditions:
```

Require agents to return:

```text
Summary:
Evidence:
Files read:
Files changed:
Decisions:
Risks:
Verification run:
Open questions:
Recommended next step:
```

## Context Management

The orchestrator owns the full plan; agents get only the context needed for their task.

- Start with `AGENTS.md`, repo README/package files, graph/local KB, targeted `rg`, and prior decisions.
- Send snippets, symbol names, contracts, and acceptance criteria instead of whole subsystems.
- Summarize each agent result into decisions, changed files, risks, and verification state. Do not keep raw transcript dumps.
- Preserve a small orchestration state: goal, workstreams, assignment status, contract decisions, integration risks, verification status.
- Refresh context at phase boundaries: after research, after architecture, after implementation, after review.

## Orchestration Patterns

**Planner -> Builders -> Reviewer -> Integrator**
Use for feature work. Planner defines contracts, builders implement independent surfaces, reviewer checks the diff, integrator resolves the final state.

**Parallel Research -> Synthesis**
Use for unfamiliar codebases, RCA, migrations, or architecture decisions. Separate agents inspect code, logs, schemas, commits, and docs; one synthesis agent reconciles findings.

**Contract-First Pipeline**
Use for full-stack work. Architecture/API contract comes first, then backend/frontend/database/QA run in parallel against that contract.

**Cross-Check**
Use for high-risk design, auth/RBAC, data migration, ontology updates, billing, or production fixes. Two agents independently inspect the same plan or diff; the orchestrator compares disagreements.

**Escalation Ladder**
Use cheap/read-only agents for discovery, mid-tier agents for bounded implementation, and stronger reviewer/judge agents for correctness-critical decisions.

## Planning Output

When asked to orchestrate agents, return this plan before dispatching:

1. Goal and success criteria
2. Workstreams and dependencies
3. Agent roster with role, scope, and ownership
4. Context packet for each agent
5. Execution order and parallelizable work
6. Integration plan
7. Verification gate
8. Risks and stop conditions

## Verification Gate

No orchestration is complete until the integrator verifies:

- Each agent returned the required structured result.
- Shared contracts match across outputs.
- No two agents made conflicting edits.
- Tests, builds, lint, browser QA, security checks, or query validation were run as appropriate.
- Diff review found no unintended churn.
- Remaining risks are explicit and actionable.

## Guardrails

- Do not delegate secrets, credentials, PII, production write access, or destructive commands.
- Do not let agents invent repo conventions. Ground them in real files, KB, or skill guidance.
- Do not over-orchestrate simple work.
- Do not accept an agent answer without evidence for code, architecture, RBAC, database, ontology, or live-data claims.
- Stop and ask the user when the next step requires irreversible production action or missing business authority.

## Examples

**Full-stack JouleTRACK feature**
Planning Agent defines API/UI/state contract; Backend Agent edits jt-api-v2 service/controller; Frontend Agent edits Angular components/NgRx; QA Agent adds tests/browser checks; Review Agent checks RBAC, analytics, error states, and performance; Integrator runs final build/test.

**Production RCA**
Research agents split logs, recent commits, DB/query evidence, and runtime config. Synthesis Agent builds the timeline and root cause. Fix Agent implements the narrow patch. Review Agent validates blast radius and prevention.

**Create a specialist agent**
Define a "RBAC Review Agent" with read-only access to policies/routes/frontend guards, required context from `dejoule-rbac`, output as policy gaps + suggested fixes, and verification through route/API permission tests.
