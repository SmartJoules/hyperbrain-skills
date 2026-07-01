# jt-api-v2 PR 1927 Review Feedback Learning

- **Date:** 2026-07-01
- **Scope:** `jt-api-v2`, PR #1927, restore-device-parameter-mapping and batch super-recipe deploy APIs
- **Source:** GitHub review comments by `itsatif` on SmartJoules/jt-api-v2 PR #1927
- **Confidence:** High; implemented in commit `ca3b31722` and verified with focused mocha tests.

## Decision / Pattern

Apply jt-api-v2 PR review feedback in the repo's existing layers:

- Move reusable mapping builders/helpers to `api/utils/<domain>/utils*.js`.
- Move request or packet validators to `api/utils/<domain>/inputValidation*.js`.
- Keep service files focused on orchestration, datastore behavior, and domain decisions.
- Prefer explicit API operation names over ambiguous booleans. For restore flows, use `operation: "debug"` for preview and `operation: "update"` for mutation.
- If an audit/event service already handles async delivery and errors, emit without awaiting in the controller.
- Remove full payload logs from services unless needed for an explicit operational/debug workflow.
- For batch APIs, pre-index input items and write results into request-order slots instead of using repeated `indexOf` lookups and sorting pushed arrays after concurrent work.

## Why It Matters

These review comments clarified the local reviewer expectations for jt-api-v2:

- Utility placement matters because controllers/services are already large and reviewers expect reusable helpers outside service files.
- API mode names must be clear to operators running recovery actions.
- Batch endpoints need deterministic, efficient responses without leaking internal implementation fields.
- Event-driven audit behavior should follow the existing service contract instead of adding duplicate error handling at every caller.

## How To Apply

For future jt-api-v2 operational APIs:

```json
{
  "operation": "debug"
}
```

and for mutation:

```json
{
  "operation": "update"
}
```

For batch services, shape the implementation like:

```js
const indexedItems = items.map((item, requestedIndex) => ({ item, requestedIndex }));
const results = new Array(items.length);

await async.eachOfSeries(chunks, async (chunk) => {
  await async.mapLimit(chunk, chunkSize, async ({ item, requestedIndex }) => {
    results[requestedIndex] = await worker(item);
  });
});
```

Then derive `successful`, `failed`, and `summary` from `results` in one pass.

## Verification

Used in jt-api-v2:

```bash
node --check api/controllers/parameters/restore-device-parameter-mapping.js
node --check api/controllers/superRecipe/batch-deploy-super-recipe.js
node --check api/services/parameter/parameter.service.js
node --check api/services/superRecipe/recipe.service.js
node --check api/utils/parameter/utils.js
node --check api/utils/parameter/inputValidation.js

NODE_ENV=testing ./node_modules/mocha/bin/mocha --timeout 10000 \
  test/unit/services/parameter/restore-device-parameter-mapping.test.js \
  test/unit/services/superRecipe/batch-deploy-super-recipe.test.js
```

## Do Not Do

- Do not keep reusable validators/helpers inside service files after reviewer asks for utility placement.
- Do not expose `apply: true/false` when the reviewer asks for operation-driven behavior.
- Do not await event-driven audit emits when the owning service already handles delivery errors.
- Do not log full IoT recipe payloads from the service path.
- Do not use `recipeIds.indexOf(recipeId)` inside batch workers; duplicate validation helps, but pre-indexing is clearer and cheaper.
