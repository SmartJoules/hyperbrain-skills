# jt-api-v2 PR 1927 Learning

- **Date:** 2026-07-01
- **Scope:** `jt-api-v2`, DeJoule backend PR hygiene, Sails/Waterline recovery APIs, batch APIs
- **Source:** SmartJoules/jt-api-v2 PR #1927 (`fix/restore-device-parameter-mapping`)
- **Confidence:** High; grounded in implemented code, reviewer feedback, focused mocha tests, and remote PR diff checks.

## Decision / Pattern

When building jt-api-v2 operational APIs, keep the change repo-native and PR-clean:

- Recovery APIs must validate route ownership (`siteId`, `deviceId`) against the recovered packet before mutating rows.
- Restore only the intended fields when repairing device configuration state; for parameter mappings this means `address`, `objectRefId`, and `matchParam`.
- Report real datastore update counts, not attempted updates.
- Batch APIs must cap input size, chunk work, bound concurrency, preserve response order, and return per-item success/failure.
- Prefer repo-supported CommonJS dependencies already in the codebase, such as `async.mapLimit` and `async.eachOfSeries`, over introducing ESM-only packages into this CommonJS service.
- Await async audit side effects when they are part of the operation, but log and fail open when the business mutation already succeeded and audit failure should not hide success.
- For service methods exported through `*.public.js`, avoid relying on `this.*` binding. Use module-local helpers or explicit module exports so bare exported functions do not crash.

## Why It Matters

This PR exposed two repeated risks:

- A polluted feature branch can accidentally push unrelated Slack, monitoring, or generated files.
- Operational APIs can appear correct while still over-reporting update counts, losing deterministic response order, or leaving audit promises unhandled.

Both risks make reviewers less confident and make production recovery workflows harder to trust.

## How To Apply

Before pushing a jt-api-v2 PR:

```bash
gh pr diff <PR_NUMBER> --repo SmartJoules/jt-api-v2 --name-only
git diff --check origin/dev...HEAD
```

For polluted branches, rebuild from the base branch and reapply only narrow hunks. Treat broad files like `config/routes.js` and `config/policy.json` carefully; do not copy whole versions from a polluted branch.

For batch endpoint work:

```js
async.eachOfSeries(chunks, async (chunk) => {
  await async.mapLimit(chunk, chunkSize, worker);
});
```

Keep controller logic thin, validate inputs at the boundary, put business behavior in services, and add focused unit tests for partial failure, ordering, and update count semantics.

## Verification

PR #1927 used:

```bash
NODE_ENV=testing ./node_modules/mocha/bin/mocha --timeout 10000 \
  test/unit/services/parameter/restore-device-parameter-mapping.test.js \
  test/unit/services/superRecipe/batch-deploy-super-recipe.test.js

git diff --check origin/dev...HEAD
gh pr diff 1927 --repo SmartJoules/jt-api-v2 --name-only
```

## Do Not Do

- Do not expose destructive wording such as `operationType: DELETE` for a restore API when the endpoint is a `PUT` recovery action.
- Do not confuse `deviceId` with `controllerId` in user-facing contracts or validation.
- Do not remove payload fields from batch deploy payloads unless the batch contract explicitly requires that behavior.
- Do not introduce unrelated Slack, Grafana, monitoring, local memory, or generated files into product PRs.
