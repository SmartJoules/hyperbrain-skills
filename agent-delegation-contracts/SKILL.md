---
name: agent-delegation-contracts
description: Use when writing high-quality delegation prompts for AI agents or subagents: creating task briefs, acceptance criteria, role prompts, ownership boundaries, allowed tools, write permissions, stop conditions, evidence requirements, output schemas, retry prompts, and handoff contracts for planning, research, implementation, QA, review, RCA, DevOps, or architecture agents.
---

# Agent Delegation Contracts

**Purpose:** Make every delegated agent task precise enough to execute independently and easy to integrate later.

## Contract Template

```text
Role:
Mission:
Background:
Scope:
Non-scope:
Inputs:
Files/repos allowed:
Tools allowed:
Write permissions:
Constraints:
Acceptance criteria:
Verification required:
Evidence required:
Output schema:
Stop conditions:
```

## Acceptance Criteria

Good criteria are observable:

- Exact behavior or deliverable expected
- Files, modules, APIs, UI states, tests, diagrams, or docs in scope
- Compatibility requirements and non-regression areas
- Security, RBAC, auth, analytics, logging, and performance requirements where relevant
- Required commands, screenshots, query outputs, or manual checks

Avoid vague criteria like "make it better" or "analyze deeply" without an output schema.

## Permission Levels

- **Read-only:** Research, review, RCA, architecture discovery, PR feedback, logs, schema exploration.
- **Suggest-only:** Produce patch plan or code snippets, but no file writes.
- **Scoped write:** Modify only named paths/modules and run bounded verification.
- **Integrator write:** Reconcile outputs after workers finish.
- **Privileged/live:** Requires explicit user approval for production, secrets, cloud writes, data deletion, migrations, or customer data.

## Output Schemas

Research agent:

```text
Findings:
Evidence:
Confidence:
Gaps:
Recommended next action:
```

Implementation agent:

```text
Summary:
Files changed:
Behavior changed:
Tests added/updated:
Verification run:
Risks:
```

Reviewer agent:

```text
Findings by severity:
File/line evidence:
Missing tests:
Security/performance risks:
Approval decision:
```

Planner agent:

```text
Workstreams:
Dependencies:
Agent allocation:
Contracts:
Risks:
Verification plan:
```

## Retry Prompts

When retrying, state what failed and narrow the next attempt:

- "Return only missing evidence for findings 2 and 3."
- "Do not edit files; inspect why the test failed and propose the smallest fix."
- "Compare your answer against this conflicting result and decide which is better supported."
- "Reduce scope to the backend service only; ignore frontend follow-up."

## Stop Conditions

Tell agents to stop when:

- Required files, credentials, or tools are unavailable
- Scope would require production or destructive action
- They find a contract conflict that needs orchestration
- Verification fails in a way that changes the plan
- The task is larger than the assigned boundary
