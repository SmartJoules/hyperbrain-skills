---
name: self-verification
description: Use before finalizing any implementation, code review, plan, KB update, architecture decision, deployment manifest, data query, UI change, agent output, or bug fix. Forces the assistant to verify its own work against the user request, repo state, tests/builds, diffs, source evidence, security/privacy rules, and acceptance criteria before claiming completion.
---

# Self Verification

**Purpose:** Make every answer earn confidence. Verify claims, diffs, tests, sources, and risk before saying the work is done.

Use with `engineering-standards`, `code-reviewer`, `agent-integration-reviewer`, `bug-postmortem-learning`, and `long-term-memory`.

## Verification Loop

Before final response:

1. Re-read the latest user request and confirm the answer matches it.
2. Check repo state: `git status --short --branch`.
3. Inspect the diff or generated artifact.
4. Run the smallest relevant validation: tests, build, lint, typecheck, package parse, YAML/JSON parse, HTML smoke, query dry-run, or syntax check.
5. Verify security/privacy: no secrets, PII, credentials, destructive commands, or unsafe production changes.
6. Verify conventions: repo patterns, skill rules, UI standards, deployment standards, RBAC/auth requirements.
7. State what was verified and what could not be verified.

## Evidence Rules

- For code changes, cite files changed and commands run.
- For architecture/KB claims, cite source repo, commit, file, doc, or tool result when available.
- For live data claims, query the source instead of guessing.
- For generated deployment manifests, dry-run or parse when possible.
- For UI work, run browser/screenshot checks when a server exists; otherwise smoke-check static files.

## Self-Check Questions

Ask yourself:

- Did I answer the newest request, not an older thread context?
- Did I accidentally modify unrelated files?
- Did I preserve user changes already in the worktree?
- Did I run the right validation for the risk level?
- Did I avoid leaking secrets or copying sensitive source values?
- Did I mention limitations honestly?
- Is there a clear next action only if one is truly needed?

## Verification Output

Use a concise report:

```text
Verified:
- <check or command>

Not verified:
- <reason if any>

Residual risk:
- <risk or none>
```

## Minimum Gates By Work Type

- **Skill/KB docs:** frontmatter check, no unfinished scaffold text, duplicate skill-name scan, `git diff --check`, package JSON parse when package metadata changed.
- **Frontend:** lint/typecheck/build when available, browser QA for rendered behavior, analytics check for meaningful interactions, PrimeNG/Boxicons rule check.
- **Backend/API:** unit/integration tests, route/service contract check, validation/error handling check, auth/RBAC check.
- **Deployment/K8s:** YAML parse, `kubectl diff` or server dry-run when credentials exist, secret-reference scan, rollback plan.
- **Bug fix:** reproduction/verification command, regression test or manual check, postmortem learning proposal when solved.
- **Multi-agent work:** verify every agent returned required output, reconcile conflicts, run integration review.

## Completion Rule

Never say "done", "fixed", "shipped", or "verified" unless the relevant checks actually ran or the limitation is clearly stated.
