---
name: agent-fleet-runner
description: Use when running multiple AI agents at once: dispatching parallel workers, choosing solo vs fleet execution, assigning model tiers, using tokensmax or subagents, isolating write agents, tracking status, retrying failed workers, merging results, and controlling cost/time for multi-agent engineering, research, review, QA, debugging, or architecture tasks.
---

# Agent Fleet Runner

**Purpose:** Run several AI workers as one controlled execution system: fast where work is independent, cautious where output must be merged.

Use with `agent-orchestration` for the plan, `agent-context-manager` for context packets, `agent-delegation-contracts` for briefs, `agent-integration-reviewer` for final reconciliation, and `tokensmax` when the user's external agent seats are available.

## Dispatch Decision

- Use **solo execution** for one-file or already-understood tasks.
- Use **parallel research** when multiple sources can be inspected independently: code, logs, schema, PR history, docs, browser, metrics.
- Use **parallel build** only when ownership boundaries are clean: frontend vs backend, API vs tests, docs vs infrastructure, read-only review vs write work.
- Use **cross-check** for risky plans: RBAC, auth, database migration, ontology updates, production incidents, billing, security, large refactors.
- Use **sequential pipeline** when one result becomes the next contract: architecture -> API -> implementation -> QA -> review.

## Fleet Run Loop

1. Define the goal, acceptance criteria, risk level, and deadline.
2. Split work into independent units with one owner per repo area.
3. Decide execution mode: research, review, build, QA, cross-check, or synthesis.
4. Assign model tier by risk: cheap for search, mid for bounded edits, strong for architecture/security/review.
5. Give each agent a context packet and delegation contract.
6. Track status as `queued`, `running`, `blocked`, `needs-retry`, `ready-for-integration`, or `done`.
7. Retry only with a changed prompt, narrower scope, or better evidence.
8. Integrate outputs and run the verification gate.

## Routing Rules

- Prefer read-only fleet work until the plan and contracts are stable.
- Keep write agents isolated by path, module, branch, or worktree.
- Give each write agent an explicit "do not touch" list.
- Never let a fleet agent modify secrets, credentials, production config, billing rules, or live data without explicit user approval.
- Do not dispatch more agents than the task can integrate. More workers can make the final merge slower.
- If using `tokensmax`, run status first and route based on the actual available seats, not hardcoded model names.

## Status Board

Track every worker in a compact table:

```text
Agent | Mode | Scope | Status | Output expected | Risk | Verification
```

Require each worker to return a structured result with evidence, files read/changed, decisions, risks, tests, and open questions.

## Failure Handling

- **Ambiguous output:** ask the same agent for a narrower answer, not a full redo.
- **Conflicting outputs:** send both to a reviewer/cross-check agent with the original contract.
- **Low-evidence answer:** mark it incomplete and request citations, file lines, logs, query results, or test output.
- **Write conflict:** stop parallel writes, assign an integrator, and sequence the remaining changes.
- **Budget overrun:** collapse to one integrator plus one reviewer.

## Completion Gate

A fleet run is done only when every workstream is `done` or intentionally dropped, the integrator has reconciled conflicts, and verification has been run or explicitly documented as unavailable.
