# Backend conventions — jt-api-v2 (Sails.js)

How to map a prototype's backend onto jt-api-v2. Confirm every claim against the live repo via
Morpheus (`code_read`, `code_search`, `code_answer`) — patterns evolve.

> ⚠️ **`JouleTrack-API` is the LEGACY backend — never a target.** All new endpoints go in
> `jt-api-v2`. If functionality you need exists only in JouleTrack-API, cite it as reference and
> plan a jt-api-v2 implementation; do not extend the legacy repo.

## Action shape (actions-as-controllers)

One action per file under `api/controllers/<domain>/`. Canonical shape (see
`api/controllers/dashboard/fetch-savings.js`):

```json
{
  "friendlyName": "fetchThing",
  "description": "…",
  "inputs": {
    "_userMeta": { "type": "json", "required": true, "note": "auto-injected by isAuthorized policy" },
    "siteId":    { "type": "string", "required": true },
    "window":    { "type": "string", "required": false }
  },
  "exits": {
    "success":     { "outputDescription": "{ data, err }" },
    "serverError": { "responseType": "serverError", "statusCode": 500 },
    "notFound":    { "statusCode": 404 }
  },
  "fn": "async ({ _userMeta, siteId }, exits) => { … return exits.success({ data, err: null }); }"
}
```

- Always return the envelope **`{ data, err }`** via `exits.success(...)`.
- Auth: the **`isAuthorized`** policy injects `_userMeta` (Bearer token → user). Multi-site via the
  **`:siteId`** route param. Never hardcode a site.

## Services

Split responsibilities into separate files under `api/services/<domain>/` (keep each < 800 lines):
- **queries service** — all DB queries. For influx, run through the influx client with **parameterized
  `{{key}}` Flux templating** (e.g. `{{siteId}}`, `{{window}}`). Never f-string/concatenate values into
  a query.
- **config/loader service** — S3/YAML/ontology loaders, with the existing AWS SDK setup + TTL cache.
- **analytics service** — pure reshaping/aggregation (bins, derivations, calendars). No I/O.

## Data access

- **InfluxDB** via `@influxdata/influxdb-client`, wrapped in `api/services/influx/` (`influx2x.js`,
  `influxClient.js`). Config from **env vars**. Extra instances are **named configs**
  (pattern: `_getNamedConfig('iot_influxdb')` in `influx2x.js`) — not hardcoded URLs.
- **RDS / Dynamo**: follow the existing service wrappers. Infer which store + objects from the repo
  code that already touches that data.
- **Reuse first**: before writing a new service, search Morpheus for an existing one. Example:
  `api/services/dashboard/dashboard.service.js` `fetchSavings` already does savings math — reuse it,
  only add an overlay if the output genuinely differs. Recommend; let the reviewer decide.

## Routes

Add entries in `config/routes.js`, e.g. `GET /m2/site/:siteId/<domain>/<thing>`, behind
`isAuthorized`. Mirror the URL conventions of neighboring domains.

## Background work & realtime

- Prototype threads/schedulers (`threading.Thread`, `schedule`, cron in `start.sh`) do **not** port
  as threads — **jt-api-v2 has no cron framework**. Real homes in the ecosystem: an **sj-airflow
  DAG**, a **dedicated microservice** (pattern: `escalation-trigger-microservice/src/jobs/`), or a
  **Kafka consumer** (see `jt-api-v2/ai-context/KAFKA_STRATEGY.md`). Propose one per job, with
  cadence and data touched, as a reviewer decision.
- Realtime push exists: `api/services/socket/socket.service.js` —
  `notifyJouleTrackPublicRoom(siteId, topic, data)` publishes to per-site public rooms on agreed
  frontend topics (`SOCKET_FRONTEND_TOPICS`, e.g. `dj-notification`) via `eventBroadcast`. For
  prototype SSE/WebSocket: map onto this socket pattern, or use RxJS polling against a normal
  action as the honest v1 — recommend, let the reviewer decide.

## Security & quality

- No secrets in code — env vars only (handled separately by the user/ops).
- Parameterize all queries (kills injection surface).
- One action/class per file; comprehensive error handling via `exits`.

## Verification

Sails unit tests per action under `test/unit/controllers/...`, mocking the data client. Manually
`curl` the new endpoint with a Bearer token and diff the JSON against the prototype's response for the
same site/window — the shapes must match (the frontend contract).
