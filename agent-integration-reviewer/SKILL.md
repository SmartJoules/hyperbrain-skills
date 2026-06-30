---
name: agent-integration-reviewer
description: Use after multiple AI agents have produced plans, research, code changes, reviews, tests, or PR feedback and their outputs must be merged, reconciled, conflict-checked, verified, summarized, or prepared for final handoff. Covers integration review, contract reconciliation, duplicate/conflicting edits, diff review, final verification gates, and release-readiness decisions for multi-agent work.
---

# Agent Integration Reviewer

**Purpose:** Turn many agent outputs into one correct result. This is the final gate for multi-agent work.

## Inputs to Collect

- Original user request and acceptance criteria
- Agent roster and each agent's contract
- Each agent's structured result
- Diffs, changed files, test output, screenshots, logs, query results, or diagrams
- Known decisions and open questions

## Integration Checklist

1. Confirm each agent answered its assigned contract.
2. Map all changed files to one owner and detect overlap.
3. Reconcile shared contracts: API shape, DTOs, DB schema, event names, ontology classes, auth/RBAC rules, UI state, telemetry, analytics.
4. Compare conflicting findings by evidence quality, not confidence language.
5. Remove duplicate, speculative, or unsupported recommendations.
6. Run or request focused verification for the combined result.
7. Produce a final handoff with changes, tests, risks, and follow-ups.

## Conflict Rules

- If two agents disagree, prefer the answer with direct code/log/schema/test evidence.
- If both have evidence, preserve the disagreement and assign a targeted cross-check.
- If code compiles only with one contract shape, update all dependent outputs to that shape.
- If a write agent touched outside scope, inspect and either justify or revert only that agent's unrelated change.
- If verification fails, integration is not complete.

## Diff Review Focus

Inspect for:

- Accidental broad rewrites, formatting churn, or unrelated file changes
- Missing imports, broken types, broken routes, or stale mocks
- Inconsistent API/frontend/DB contracts
- Missing RBAC/auth/permission checks
- Missing Google Analytics for frontend interactions where HyperBrain standards require it
- Missing loading/error/empty states
- Weak tests or no regression coverage for the changed behavior
- Performance, query, cache, retry, timeout, and observability gaps

## Final Verification Gate

Choose checks based on the changed surface:

- Unit/integration tests for code
- Typecheck/lint/build for apps
- Browser QA or screenshots for UI
- Query validation for DB/Neptune/Influx changes
- Security/RBAC review for auth-sensitive changes
- Deployment or rollback checks for DevOps changes

If a check cannot run, document why and state the residual risk.

## Final Handoff Format

```text
Integrated result:
Agent outputs used:
Conflicts resolved:
Files changed:
Verification:
Risks:
Follow-ups:
Release decision:
```

Use `Release decision: ready`, `ready-with-risk`, or `not-ready`.
