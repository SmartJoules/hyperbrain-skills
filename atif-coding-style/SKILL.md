---
name: atif-coding-style
description: Use when writing, reviewing, planning, or refactoring code that should match Atif/itsatif's engineering style in SmartJoules JouleTRACK and jt-api-v2: small production bug fixes, PR feedback cleanups, Sentry-driven fixes, Angular/NgRx UI work, Sails/Waterline backend work, system design, LLD, tests, PR descriptions, and commit hygiene. Ground output in local repo patterns, Atif commit history, and existing architecture before coding.
---

# Atif Coding Style

Write code the way Atif/itsatif tends to land production changes in `JouleTRACK` and `jt-api-v2`: narrow, repo-native, evidence-driven, test-backed, and easy for reviewers to trust.

This skill is not "copy someone's formatting". It is an engineering operating style:

- diagnose the real failure path
- patch the smallest correct layer
- preserve existing architecture
- add regression tests where the repo supports them
- remove generated/planning artifacts from product PRs
- document root cause, behavior, test commands, risks, and rollout notes

---

## Evidence To Recheck

When time allows, refresh examples from local history before making broad claims:

```bash
git -C /Users/atif-salafi/Desktop/workspace/office-space/JouleTRACK log --all --author='Atif\|atif\|itsatif' --date=short --pretty=format:'%h %ad %s' -n 40
git -C /Users/atif-salafi/Desktop/workspace/office-space/jt-api-v2 log --all --author='Atif\|atif\|itsatif' --date=short --pretty=format:'%h %ad %s' -n 60
```

Useful sampled commits:

- `JouleTRACK` `f8f67625f`: stop recursive Angular time-picker writeback by removing the exact `(ngModelChange)` loop.
- `JouleTRACK` `09a71fcc1`: guard `contentDocument` and route SVG node writes through null-safe helpers.
- `JouleTRACK` `4de028996`: address PR feedback by removing local AI planning docs from the PR and correcting route policy to `Scheduler_View`.
- `jt-api-v2` `aefdd1531`: production Sentry fix for Waterline `.findOne()` duplicates; add duplicate-tolerant private helper, bulk update, focused tests, and explicit follow-up.
- `jt-api-v2` `91c6191b4`: preserve parameter mappings by snapshot -> recreate -> restore non-empty fields, with controller sequence and service helper tests.
- `jt-api-v2` `46fad8e13`: optimize comfort-index by server-side downsampling, short-TTL fail-open Redis cache, cache invalidation seam, and tests.

Do not freeze these examples as dogma. Use them as precedent for how to think.

---

## Core Habits

### 1. Fix The Actual Failure Path

Start from the production symptom, stack trace, Sentry issue, user complaint, or broken workflow.

Good Atif-style fixes say:

- what crashed or behaved incorrectly
- why the existing code did that
- what exact path changed
- why public behavior is otherwise unchanged
- what still needs a follow-up

Avoid generic rewrites when one bad call site, bad selector, bad policy, or bad data condition is the real issue.

### 2. Keep The Diff Small

Prefer a surgical change with high confidence.

- Patch the layer that owns the behavior.
- Do not reformat unrelated files.
- Do not rename broadly while fixing a bug.
- Do not move code unless the move itself removes real confusion.
- Remove generated docs, local plans, workspace files, and AI scratch artifacts from PRs.

PR-review history repeatedly cleans up generated docs and local workspace files. Product PRs should contain product changes, tests, and required docs only.

### 3. Match Repo Architecture

For `jt-api-v2`:

- Use Sails actions/controllers, services, Waterline models, policies, and existing utilities.
- Treat Waterline model + service as the repository layer; do not introduce a new ORM/repository framework.
- Keep controllers thin and put business behavior in services.
- Add private-layer helpers when they encapsulate datastore quirks, such as duplicate-tolerant lookup.
- Use existing `flaverr`/error-code style where present.
- Prefer additive helpers and stable public service signatures.

For `JouleTRACK`:

- Preserve Angular module/component/facade/selector/effect patterns already in the feature.
- For NgRx scheduler-style work, keep derivation in selectors and state transitions in reducer/effects/facade as established.
- Use route guards and `data.expectedPolicy` with the correct domain policy.
- Keep UI fixes scoped to the component/parent stylesheet when a shared component has many consumers.
- Use existing utilities/helpers instead of direct DOM writes when null-safe helpers exist.

### 4. Make Edge Cases First-Class

Atif-style fixes often handle bad production data and timing races gracefully:

- duplicate rows where `findOne()` expects one
- null/undefined values before Waterline create/update
- missing SVG `contentDocument` during asset switch
- missing device or optional array input
- stale docs/comments claiming wrong query range
- left-over active duplicate records after partial unsubscribe

Do not just prevent the throw. Ensure the business state becomes correct.

### 5. Add Focused Regression Tests

For `jt-api-v2`, add unit tests around the exact regression:

- mock private/data layers with `require.cache` when needed
- set up `global.sails` before requiring app code
- test success and failure/error codes
- assert sequencing when order matters
- test duplicate/bad-data behavior, not only happy path

For `JouleTRACK`, add selector/service tests when the changed logic is testable. For pure template/CSS fixes, document manual verification clearly.

---

## System Design And LLD Style

When asked for design or LLD in Atif style:

1. Start with current repo/system context.
2. State the product problem and the production failure modes.
3. Prefer modular, incremental changes over new subsystems.
4. Define service/module boundaries using the repo's real layers.
5. Include data flow, request flow, failure handling, cache/queue behavior, and auth/RBAC.
6. Identify the minimum schema/API changes.
7. Add observability, rollout, rollback, and follow-ups.

LLD should include:

- files to touch
- public API contract
- internal service methods
- DTO/input validation
- datastore queries and indexes
- cache keys and TTL/eviction
- error codes
- tests
- migration/rollout notes

If complexity is not justified, say so and choose the simpler modular-monolith/repo-native design.

---

## Backend Patterns From jt-api-v2

Use these patterns when building or fixing backend code:

- Controller orchestrates request validation, calls service, returns existing response shape.
- Service owns business logic and error decisions.
- Private layer or model wrapper owns datastore quirks.
- Duplicate-tolerant lookup: replace unsafe `.findOne()` with deterministic `find(...).sort('id DESC').limit(1)` only when duplicates are known/possible.
- Bulk update when business correctness requires mutating all duplicate rows.
- Snapshot -> destructive step -> restore when refresh/rebuild would otherwise lose device-specific fields.
- Preserve non-empty existing values; do not overwrite good defaults with blank/null/undefined.
- Cache read-heavy queries with short TTL only when stale data is acceptable; fail open on cache errors.
- Export pure helpers for tests when it improves coverage without exposing public API.
- Preserve nulls/gaps in telemetry; do not convert missing sensor data to zero.

Backend PR descriptions should include root cause, changes, tests, rollout, risks, and follow-ups.

---

## Frontend Patterns From JouleTRACK

Use these patterns when building or fixing frontend code:

- Diagnose event loops and reactive-form bugs by tracing writeback paths.
- Avoid mixing two writers on the same form control; if one-way display is enough, remove the writeback.
- Guard async/mid-load DOM/SVG access with optional chaining and early return.
- Prefer existing null-safe utility helpers over raw `querySelector(...).style`.
- Scope CSS to the owning component or parent when shared components are reused widely.
- Gate routes and deep links with the feature's actual policy, not a nearby unrelated policy.
- Keep local AI docs and planning files ignored or out of PRs.
- Preserve normal browser affordances where relevant: left-click same tab, middle/Cmd/Ctrl/right-click new tab if implementing navigation behavior.

Frontend PR descriptions should include root cause, behavior matrix when UX changes, test/manual verification checklist, rollout, and risk.

---

## PR Review Lessons To Apply

When addressing review feedback:

- remove auto-generated docs, local plans, workspace files, and scratch notes
- simplify over-abstracted helpers
- use the correct feature policy/RBAC key
- remove unused parameters and dead code
- add concurrency limits for batch work
- parallelize independent DB calls only when it is safe
- report partial failures instead of hiding them
- keep CSS or shared-component changes scoped
- keep public response shapes stable unless explicitly changing the contract

Reviewers should see a cleaner, smaller PR after feedback, not a larger tangential rewrite.

---

## Commit And PR Style

Commit messages are direct and often scoped:

```text
fix(recipe): stop infinite recursion in step-three time picker
fix(alerts): tolerate duplicate active subscriptions in findOne
perf(dashboard): downsample + cache comfort-index widget query
feat(scheduler): add low-side schedule service unioning pg + legacy sources
```

Good PR body template:

```markdown
## Summary

## Root Cause

## Changes Made

## Testing

## Rollout Notes

## Risks / Follow-ups
```

For production bugs, cite Sentry/ticket IDs when available and include exact commands run. If lint/test failures are pre-existing, say exactly what failed and why it is unrelated.

---

## Output Rules When Using This Skill

When writing code:

1. Inspect existing files first.
2. State the repo-native pattern being followed.
3. Make the smallest correct change.
4. Add or update focused tests where practical.
5. Provide PR-style summary and verification.

When reviewing code:

1. Ask whether the diff is repo-native.
2. Check for generated artifacts and unrelated docs.
3. Check correct RBAC/policy, datastore behavior, and failure states.
4. Check tests target the actual regression.
5. Suggest the smallest fix.

When planning:

1. Use `software-architecture-planner` for HLD/system design.
2. Use `backend-implementation-planner` or `api-service-generator` for LLD/API work.
3. Apply this skill to keep the plan in Atif's delivery style: incremental, testable, repo-native, and PR-clean.
