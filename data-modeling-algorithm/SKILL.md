---
name: data-modeling-algorithm
description: Use when designing or reviewing database models, entities, tables, collections, DynamoDB keys, GSIs/LSIs, MongoDB schemas, PostgreSQL/MySQL schemas, indexes, relationships, constraints, migrations, tenancy boundaries, audit fields, time-series models, or SQL/NoSQL access patterns. Provides an access-pattern-first algorithm for creating high-quality relational and non-relational data models with indexes, relationship design, query fit, scalability, and migration safety.
---

# Data Modeling Algorithm

Use this skill before creating or changing persistent data models. Design from access patterns, correctness boundaries, and query shape before choosing tables, collections, indexes, or GSIs.

## Core Principle

Model the data around invariants and access patterns:

- **Invariants:** what must always be true.
- **Relationships:** what owns, references, or aggregates what.
- **Access patterns:** exact reads/writes, filters, sorts, pagination, counts, joins, and lifecycle operations.
- **Scale shape:** cardinality, write rate, read rate, hot keys, retention, tenancy, and archival.
- **Safety:** migrations, rollback, backfill, production guards, and PII/secrets.

## Step 1: Capture Requirements

Write these first:

```text
Entities:
- <entity>: purpose, owner, lifecycle

Access patterns:
- AP1: actor, operation, filters, sort, expected cardinality, frequency, latency SLO

Relationships:
- A owns B
- A references B
- A aggregates B

Non-functional:
- tenants/sites/users
- consistency needs
- retention/audit/compliance
- expected rows/items now and in 12 months
```

Do not create indexes before access patterns are named.

## Step 2: Choose Store And Shape

| Need | Prefer |
|---|---|
| Strong relational integrity, joins, transactions, reporting | SQL: PostgreSQL/MySQL |
| Known key-value access at high scale | DynamoDB |
| Flexible document aggregates, sparse fields, nested config | MongoDB |
| Time-series telemetry and aggregations | InfluxDB/Timestream |
| Cache/session/rate limit/ephemeral state | Redis |
| Semantic relationships/ontology | Neptune/Jena/RDF |

If a workflow needs both transactional truth and fast read models, keep SQL as source of truth and create derived read models/search/cache separately.

## SQL Modeling Algorithm

1. Identify aggregate roots and transactional boundaries.
2. Normalize to 3NF by default for source-of-truth data.
3. Denormalize only for measured read paths, reporting, or read models.
4. Add primary keys, foreign keys, uniqueness, check constraints, and not-null constraints.
5. Add tenant/site/user scope columns where access control requires them.
6. Add audit fields: `created_at`, `updated_at`, `created_by`, `updated_by` where useful.
7. Add soft-delete or archive fields only when lifecycle requires recovery/audit.
8. Design indexes from queries, not from columns alone.

### SQL Index Rules

- Use composite indexes in query order: equality filters, then range/sort columns.
- Use covering indexes for high-frequency read paths when it avoids table lookups.
- Use partial indexes for sparse status/tenant/workflow filters.
- Use unique indexes for business invariants.
- Use expression indexes only when queries truly filter by that expression.
- Avoid indexing every foreign key blindly; index FKs used for joins/filtering/deletes.
- Avoid redundant prefix indexes: `(tenant_id, site_id)` can often cover `tenant_id`.
- Verify with `EXPLAIN`/`EXPLAIN ANALYZE` before claiming performance.

### SQL Relationship Patterns

- One-to-one: FK with unique constraint.
- One-to-many: child table has parent FK and parent-scope index.
- Many-to-many: join table with composite unique constraint.
- Hierarchy: adjacency list for simple trees; closure table/materialized path for deep traversal.
- Multi-tenant: include tenant/site scope in unique constraints and indexes.

## DynamoDB Modeling Algorithm

DynamoDB is access-pattern-first. Do not start with ERD normalization.

1. List every access pattern and expected cardinality.
2. Choose table partition key for even distribution and primary lookup.
3. Choose sort key for range queries, ordering, hierarchy, or entity grouping.
4. Use composite keys with stable prefixes, for example `SITE#123` and `ALERT#2026-06-30#abc`.
5. Add GSIs only for access patterns that cannot be served by the base table.
6. Add LSIs only when the same partition key needs an alternate sort key and item size/cardinality allows it.
7. Decide projection type: `KEYS_ONLY`, `INCLUDE`, or `ALL`.
8. Estimate read/write amplification and hot partition risk.

### GSI/LSI Rules

- One GSI per genuinely different partitioning need.
- Prefer sparse GSIs for workflow states, pending jobs, active alerts, or open tasks.
- Avoid low-cardinality partition keys like `status = OPEN` unless combined with tenant/site/time bucket.
- Use time buckets for high-write streams: `SITE#123#2026-06`.
- Include tenant/site scope in keys for authorization and blast-radius control.
- Keep GSI projections minimal to reduce write cost.
- Document eventual consistency implications for every GSI-backed query.

### DynamoDB Output Shape

```text
Table: <name>
PK: <partition key>
SK: <sort key>

Entities:
- <entity>: PK/SK pattern, attributes

Access patterns:
- AP1 -> base table query
- AP2 -> GSI1 query

GSI1:
- PK:
- SK:
- projection:
- consistency/cost note:
```

## MongoDB Modeling Algorithm

1. Start from read/write aggregate boundaries.
2. Embed data that is owned, small, bounded, and read together.
3. Reference data that is shared, large, independently updated, or unbounded.
4. Avoid unbounded arrays in hot documents.
5. Keep document size below MongoDB limits with growth headroom.
6. Add schema validation for required fields and enum-like states.
7. Design compound indexes with ESR: equality, sort, range.
8. Verify with `explain()` and `keysExamined/docsExamined/nReturned`.

### MongoDB Index Rules

- Use compound indexes that match the query filter and sort.
- Avoid regex leading wildcards and unindexed text search.
- Use partial indexes for sparse states.
- Use TTL indexes for true lifecycle expiry, not business archives.
- Avoid too many indexes on write-heavy collections.
- Keep shard key/high-cardinality routing in mind for future scale.

## Relationship Decision Matrix

| Relationship | SQL | DynamoDB | MongoDB |
|---|---|---|---|
| Strong integrity required | FK/constraint | Usually not ideal alone | Reference + app validation |
| Read together, bounded | Join or JSONB if not queried | Same item collection | Embed |
| Read separately, shared | FK reference | Separate item/entity | Reference |
| Many-to-many | Join table | Duplicated edges or adjacency items | Reference array only if bounded |
| High-scale lookup by alternate key | Unique index | GSI | Unique/compound index |

## Migration And Backfill Safety

Pair with `production-safety-guards` for production schema/data changes.

- Prefer expand-migrate-contract:
  1. Add nullable/new columns or new table/index.
  2. Dual-write if needed.
  3. Backfill in batches.
  4. Read from new path behind a feature flag.
  5. Verify counts and checksums.
  6. Remove old path after stability window.
- Never run destructive migrations without backup, rollback, owner, and approval.
- For large indexes, use online/concurrent index creation where supported.
- Include rollback scripts and validation queries.

## Output Contract

Return data models in this shape:

```json
{
  "dataModel": {
    "store": "postgresql | dynamodb | mongodb | redis | influxdb | neptune",
    "entities": [],
    "accessPatterns": [],
    "relationships": [],
    "indexes": [],
    "constraints": [],
    "migrationPlan": [],
    "risks": [],
    "verification": []
  }
}
```

## Verification Checklist

- Every index maps to a named access pattern.
- Every access pattern is served by a table/index/query path.
- Relationship cardinality and ownership are explicit.
- Tenant/site/RBAC scope is included where required.
- Hot partitions, unbounded arrays, full scans, N+1 queries, and write amplification are checked.
- Migration plan includes backfill, rollback, verification, and production safety.
- Query plan or explain validation is planned for critical paths.
