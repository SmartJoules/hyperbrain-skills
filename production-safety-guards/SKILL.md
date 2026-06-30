---
name: production-safety-guards
description: Use before any production, staging, database, graph, Neptune, PostgreSQL, MongoDB, InfluxDB, Redis, Kubernetes, deployment, migration, customer-data, destructive, delete, drop, truncate, update, insert, overwrite, cache flush, command/control, or irreversible operation. Enforces hard guardrails: agents must not run destructive delete/drop/truncate/flush queries, must warn the user multiple times, must prefer read-only dry-runs and backups, and must require explicit human confirmation/runbook ownership for risky operations.
---

# Production Safety Guards

Use this skill whenever an operation can change production, customer data, graph state, deployment state, access control, billing, alerts, device control, or irreversible history.

## Hard Rule

Do not run destructive commands or queries as an agent.

This includes:

- SQL: `DELETE`, `DROP`, `TRUNCATE`, broad `UPDATE`, schema rewrites, irreversible migrations.
- SPARQL/Neptune/Jena: `DELETE`, `DELETE WHERE`, `DROP GRAPH`, broad `INSERT/DELETE/WHERE`, graph rebuilds.
- MongoDB/DynamoDB/Redis: `deleteMany`, `drop`, `flushall`, `flushdb`, mass updates, TTL rewrites.
- InfluxDB/time-series: bucket delete, retention policy changes, broad deletes.
- Kubernetes/cloud: delete namespace/deployment/service/PVC, scale production to zero, destroy infrastructure, rotate secrets, change ingress/DNS.
- App/control systems: device commands, automation overrides, alert suppression, RBAC/auth policy changes.

The agent may draft a runbook or query, but must not execute it. The final execution owner must be a human operator or approved production pipeline.

## Warning Protocol

When a user asks for any risky operation, show multiple warnings before proceeding:

1. **First warning:** state the operation is destructive or production-affecting.
2. **Second warning:** name the exact blast radius: data, site, service, tenant, graph, table, namespace, cache, device, or alert path.
3. **Third warning:** state that the agent will not execute the destructive command and can only prepare a reviewed runbook or dry-run.

Ask for explicit confirmation before drafting the runbook:

```text
This is a production/destructive operation.

Warning 1: It can permanently change or delete data/state.
Warning 2: Blast radius appears to be <scope>.
Warning 3: I will not execute this. I can only prepare a dry-run, backup plan, reviewed command, and rollback runbook.

Please confirm you want me to draft the runbook, and specify:
- environment
- exact scope
- backup/snapshot location
- rollback owner
- approval/ticket link
```

## Safe Alternatives First

Always offer safe alternatives before a destructive plan:

- Read-only `SELECT`, `ASK`, `CONSTRUCT`, `DESCRIBE`, `MATCH`, `EXPLAIN`, `COUNT`, `LIMIT`.
- Dry-run diff or preview query.
- Query that identifies candidate rows/triples/resources without changing them.
- Backup/snapshot/export command.
- Canary scope: one site, one tenant, one component, one graph, one namespace.
- Feature flag or soft-disable instead of delete.
- Archive or tombstone instead of hard delete.
- TTL/retention review instead of manual delete.

## Drafting Destructive Queries

If the user still needs a destructive operation, provide only a reviewed artifact:

- Mark it as `DO NOT RUN WITHOUT HUMAN APPROVAL`.
- Include explicit environment and scope fields for the human operator to fill.
- Include a read-only preview query.
- Include expected count and max allowed affected rows/triples/resources.
- Include backup/snapshot verification.
- Include rollback steps.
- Include monitoring/canary checks.
- Include an approval checklist.

Never silently generate a broad query such as:

```sql
DELETE FROM table;
UPDATE table SET ...
DROP TABLE table;
```

Never generate broad graph deletion without a scoped preview and explicit graph/site filters.

## Required Approval Checklist

Before a human runs any destructive operation, require:

- Environment is explicitly named.
- Scope is explicitly bounded by site, tenant, ID list, graph, namespace, or timestamp.
- Preview count is reviewed and below the max allowed affected count.
- Backup/snapshot/export exists and restore path is known.
- Rollback owner is named.
- Monitoring window is defined.
- Ticket/approval link is attached.
- Two-person review is complete for production.

## Stop Conditions

Stop and refuse to proceed beyond safe drafting if:

- The user asks the agent to run `DELETE`, `DROP`, `TRUNCATE`, `FLUSH`, broad `UPDATE`, graph `DELETE`, or infrastructure delete.
- Environment is production and scope is vague.
- No backup or rollback exists.
- The query affects all rows/triples/resources.
- The request involves auth/RBAC/admin access without approval.
- The operation can affect building controls, alerts, or customer-facing availability.

## Output Contract

For risky work, finish with:

```json
{
  "productionSafety": {
    "riskLevel": "high",
    "willExecute": false,
    "reason": "Destructive operations require human execution",
    "warningsShown": 3,
    "safeAlternative": "read-only preview query",
    "requiredApprovals": [
      "environment",
      "scope",
      "backup",
      "rollbackOwner",
      "ticket",
      "twoPersonReview"
    ]
  }
}
```

## Final Checklist

- Destructive command was not executed by the agent.
- User received multiple warnings.
- Safe read-only preview was provided first.
- Backup, rollback, scope, and approval requirements are listed.
- Any provided destructive command is clearly marked as a human-run runbook artifact only.
