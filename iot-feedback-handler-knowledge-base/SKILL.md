---
name: iot-feedback-handler-knowledge-base
description: Knowledge base for the iot-feedback-handler service — an enterprise event-driven TypeScript microservice that consumes IoT device-feedback from Kafka (mode change, recipe, relinquish-control, bulk-assets), validates/transforms it, and persists to DynamoDB/MongoDB + PostgreSQL audit + Redis cache. Use when working on, reviewing, or designing for iot-feedback-handler: its layered architecture (handlers→orchestrators→services→repositories), mandated Repository/Factory/Strategy/Singleton patterns, KafkaJS+snappy consumer, cloud/edge document-store abstraction, or its coding standards. Provides architecture + convention context so changes follow the repo's real structure.
---

# IoT Feedback Handler — Knowledge Base

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Real architecture + conventions of the iot-feedback-handler service so changes build on the actual code
**Version:** 1.0.0
**Repo:** `office-space/iot-communication/iot-feedback-handler` (authoritative docs: `ARCHITECTURE_AND_STANDARDS.md`, `AGENTS.md`, `README.md`)

---

## 🎯 When to Use

Any work on iot-feedback-handler — features, reviews, or design docs targeting it. Build on the real structure below, don't re-infer it. Enforce [[engineering-standards]] (the repo's own `ARCHITECTURE_AND_STANDARDS.md` wins for repo-specifics); for IoT/stream context see [[iot-knowledge-base]], [[kafka-patterns]]; for query perf [[database-query-optimizer]].

---

## 1. What It Is

Enterprise, **event-driven TypeScript microservice** that consumes asynchronous **device-feedback** messages from Kafka (mode change, recipe update, relinquish-control, bulk-asset management), validates/transforms them through strict layered logic, and persists to polyglot stores. **Dual deployment**: `cloud` (DynamoDB) / `edge` (MongoDB), Blue-Green compatible (forward/backward-compatible schema, feature flags). Observability via **pino** (structured JSON) + **Sentry**.

## 2. Stack

TypeScript 5.9 / Node 18+ (ES2020). **KafkaJS 2.2** + `kafkajs-snappy` (Snappy). Stores: **DynamoDB** (cloud) / **MongoDB** (edge) for devices+modes; **PostgreSQL** (`pg`) for audit/tracking (`audit_logs`, `mode_change_logs`, `mode_change_status`); **Redis** for mode-state cache (TTL 3600s). Express 4 (health on :7000). Zod (validation), Sentry, pino/pino-pretty, InfluxDB client (present, not core), Vitest (tests). Note: `tsconfig` `strict:false` but explicit typing is mandated for new code (tech-debt: migrate to strict).

## 3. Architecture & Layering (strict, downward-only deps)

`src/index.ts` (bootstrap) · `src/server.ts` (Express health) →
**handlers/** (THIN — parse Kafka envelope, validate, route; NO business logic) →
**orchestrators/** (coordinate multi-step workflows, e.g. `BulkJobOrchestrator` — job lifecycle/audit/progress) →
**services/** (FAT — business logic, domain rules, transactions; NO direct DB queries) →
**repositories/** (data-access abstraction — get/put/update/query; NO business logic) →
**config/connections/** (singleton clients).
Also `interface/` (TS interfaces, `I`-prefixed), `constants/`, `utils/`.

**Architectural rules:** no business logic in handlers · no DB logic in services (use repositories via DI) · no direct infra calls from business logic (abstract via interfaces like `IDocumentStore`) · dependencies flow downward only · all schema changes Blue-Green compatible.

## 4. Mandated Design Patterns (per ARCHITECTURE_AND_STANDARDS.md §Design Patterns)

- **Repository** — `src/repositories/{DeviceRepository,AuditRepository,JobRepository}.ts`; all data access behind repos, services never touch drivers. REQUIRED for mutations.
- **Factory** — `src/services/store/DocumentStoreFactory.ts`; `DEPLOYMENT_MODE=cloud→DynamoDocumentStore`, `edge→MongoDocumentStore` (single cached instance). REQUIRED for the store abstraction.
- **Strategy** — `src/services/recipe/core/RecipeFeedbackStrategyRegistry.ts` + `RecipeFeedbackStrategies.ts`; pluggable legacy vs super-recipe handlers in a registry. REQUIRED for interchangeable handlers.
- **Singleton** — `src/config/connections/{PostgresConnection,redis,KafkaConnection}.ts`; all external clients are singletons (frozen after init). REQUIRED.
- GoF expected for extensions: Observer (SocketBroadcastService), Command (AuditLogService), Decorator (logging/cache wrappers). OOP-only in main flows (procedural forbidden); interfaces (`IDocumentStore`, `IRecipeFeedbackStrategy`) for swappable impls.

## 5. Coding Standards

Explicit typing on every param/return/complex var (no `any` except `unknown`+guards). Classes only in main logic (no procedural). Naming: Class PascalCase, method camelCase, const UPPER_SNAKE, interface `I`-prefixed, private `_`/`#`. **Logging**: `logger.error()` = handled exceptions (→Sentry); `logger.critical()` ONLY for architectural faults (DB-down, integrity/security violation, missing config, unhandled); `logger.warn()` = expected errors (validation/not-found); always structured JSON with `{operation, step, requestId, deviceId,...}`. JSDoc on all public methods/classes/interfaces (incl. the "why"). TDD (Vitest), ≥80% coverage new code / 100% audit+security paths. **Bare-minimum changes** — no unrelated refactor.

## 6. Data Flow (device-feedback, end-to-end)

Kafka (Snappy) → `index.ts eachBatch` decompress + `unwrapBridgeEnvelope()` (merge siteId/controllerId from the Go MQTT bridge into `extra`) → route by topic → e.g. `modeChangeFeedbackHandler` → validate (siteId, config device.param→mode) → per unique deviceId: `Store.get('devices')` → diff modes → `Store.update('devices' SET mode)` + `Store.put('modes', ...)` via `DocumentStoreFactory` → `Promise.allSettled` (parallel, fault-tolerant) → `updateModeChangeStatus(transactionId,...)` (PG) → Redis `set(mode:deviceId:...:commandAbbr:..., TTL 3600)` → structured log + optional Socket.IO broadcast.

**Idempotency/offsets:** `eachBatchAutoResolve=false`; `resolveOffset()` AFTER successful processing; periodic `commitOffsetsIfNecessary()` + `heartbeat()`; `JobProgressTracker.isJobRunnable(jobUUID)` dedups jobs. **`requestId ?? transactionId`** (newer vs older producers).

## 7. Connections (all singletons, graceful shutdown)

- **Kafka** (`KafkaConnection.ts` + `KafkaConsumerService.ts`): SASL auth, pattern subscribe (e.g. `+/feedback/+/mode`), Snappy registered globally in `index.ts`, manual offset, heartbeat. SIGINT/SIGTERM → `consumer.disconnect()`.
- **Postgres** (`PostgresConnection.ts`): singleton Pool, `testConnection()` at boot, BEGIN/COMMIT/ROLLBACK + release client in `finally`.
- **Redis** (`config/connections/redis.ts`): singleton client, reconnect strategy (exp backoff), safe-handled `set/get/del`, TTL 3600 for mode keys.
- **DynamoDB** (`dynamoClient.ts` + `DynamoDocumentStore.ts`): AWS SDK v3 DocumentClient; tables `devices`/`modes`/`jobs` via env.
- **MongoDB** (`mongoClient.ts` + `MongoDocumentStore.ts`): mirrors `IDocumentStore`; `bootstrapMongoIndexes()` in edge mode.

## 8. Runtime / Entry

`index.ts` boot: register Snappy → start Express health (:7000) → test PG → test Vigilante (smart-alert) DB → bootstrap Mongo indexes (edge) → connect KafkaConsumerService → subscribe topics (mode/bulk-assets/relinquish/recipe) → run `eachBatch` (no auto-resolve) → SIGINT/SIGTERM handlers. Config in `src/config/appConfig.ts` (dotenv): `NODE_ENV`, `DEPLOYMENT_MODE` (cloud/edge), `KAFKA_*` + topics, `DATABASE_*`, `SMART_ALERT_DB_NAME`, `CACHE_*`, `AWS_REGION`+`DYNAMODB_*` tables, `MONGODB_URL`, `SENTRY_DSN`. (Secrets via env — see [[engineering-standards]] §5B; never hardcode.)

## 9. MCP / AI-Agent Mandate

`AGENTS.md` + `ARCHITECTURE_AND_STANDARDS.md` **require** AI agents to query the **Morpheus MCP** (`https://cody.smartjoules.org/sse`) before proposing changes: pre-analysis (existing patterns/decisions/deps) → cross-reference generated code against MCP context → update MCP docs post-implementation. MCP config in `.claude/settings.json` / `.cursor/mcp.json`; scripts `npm run mcp:install|verify|test`.

## 10. Known Gaps / Gotchas

- **No explicit DLQ** — failed messages log to Sentry and the offset is still resolved (message skipped); monitor Sentry + Kafka lag. (Consider a poison-pill topic.)
- `tsconfig strict:false` (migrate to strict). InfluxDB client imported but not in core flow. Socket.IO `SocketBroadcastService` exists but may not be wired. Legacy vs super-recipe strategy — confirm the active path.
- Snappy: check `message.headers.compression === 'snappy'` before decompressing. Redis TTL 3600 duplicated across handlers — change in all. Socket broadcast errors are swallowed by design (must not crash the consumer).
