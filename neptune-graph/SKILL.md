---
name: neptune-graph
description: Use when writing, reviewing, fetching, or updating SmartJoules Amazon Neptune RDF/SPARQL graph data for ontology-service: site graphs, equipment, devices, points, controllers, locations, telemetry refs, water loops, and Brick/sj relationships.
---

# SmartJoules Neptune Graph

The ontology graph is RDF/SPARQL in Amazon Neptune. Use the repo tools; do not hand-roll signed HTTP requests.

For on-prem deployments, the same graph model can run on Apache Jena Fuseki. Keep SPARQL, graph IRIs, and named-graph scoping identical; only the transport/adapter changes.

---

## Graphs

| Graph | Content |
|---|---|
| `http://smartjoules.org/<siteId>/brick` | One named graph per site; instance data |
| `http://smartjoules.org/schema` | Shared `sj:` class/property definitions |

Always scope site queries with `GRAPH <http://smartjoules.org/<siteId>/brick> { ... }`.

---

## Prefixes

```sparql
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX sj:    <http://smartjoules.org/schema/BrickExtension#>
PREFIX ref:   <https://brickschema.org/schema/Brick/ref#>
PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>
PREFIX unit:  <http://qudt.org/vocab/unit/>
```

---

## CLI

Run from `SmartJoules/ontology-service`:

```bash
node tools/neptune.ts graphs
node tools/neptune.ts query --query 'SELECT * WHERE { ?s ?p ?o } LIMIT 5'
node tools/neptune.ts query --file query.rq --format table
node tools/neptune.ts update --file update.rq
node tools/neptune.ts export --out neptune-dump --format turtle
node tools/neptune.ts load --source s3://<bucket>/<prefix>/ --role <iamRoleArn>
```

Prerequisites: VPN, AWS profile `sjpl-aws`, Node >= 22, `.env` Neptune endpoints.

For local/on-prem Fuseki:

```bash
docker volume create fuseki-data
docker run --name ontology-fuseki -p 3030:3030 -e ADMIN_PASSWORD=change-me -v fuseki-data:/fuseki stain/jena-fuseki
```

Use:

```text
http://localhost:3030/ontology/query
http://localhost:3030/ontology/update
http://localhost:3030/ontology/data
```

Copy from Neptune to Fuseki by exporting named graphs with `node tools/neptune.ts export --out neptune-dump --format turtle`, then loading each file into the same graph IRI through Fuseki's Graph Store Protocol (`/ontology/data?graph=<encoded graph IRI>`). Verify with per-graph triple counts.

---

## Query Guardrails

- Include a site `GRAPH` for every per-site query.
- Include `LIMIT` for list queries.
- Use `COUNT` for counts.
- Avoid unanchored property paths.
- Prefer identity keys over labels: `sj:deviceId`, `sj:siteId`, `sj:abbr`, `sj:groupId`.
- Live telemetry values are not in Neptune; fetch `ref:hasTimeseriesId` and query the time-series store.
- Do not query the union graph for normal user questions.

---

## Safe Update Runbook Pattern

Writes target the writer endpoint and are irreversible. Agents must not execute Neptune `DELETE`, `DELETE WHERE`, graph rebuild, or broad `INSERT/DELETE/WHERE` operations. Load `production-safety-guards`, show multiple warnings, and provide only a reviewed human-run runbook.

Start with a read-only preview:

```sparql
PREFIX sj: <http://smartjoules.org/schema/BrickExtension#>

SELECT ?node ?old
WHERE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?node sj:deviceId "known-id" .
    OPTIONAL { ?node sj:mutablePredicate ?old . }
  }
}
LIMIT 25
```

If a human operator still approves a destructive graph change, mark the artifact as `DO NOT RUN WITHOUT HUMAN APPROVAL` and include backup, rollback, affected triple count, site graph, ticket, and two-person review.

```sparql
# DO NOT RUN WITHOUT HUMAN APPROVAL.
# Human-run runbook artifact only. Agent must not execute.
PREFIX sj: <http://smartjoules.org/schema/BrickExtension#>

DELETE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?node sj:mutablePredicate ?old .
  }
}
INSERT {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?node sj:mutablePredicate "newValue" .
  }
}
WHERE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?node sj:deviceId "known-id" .
    OPTIONAL { ?node sj:mutablePredicate ?old . }
  }
}
```

Rules:
- Do not run destructive graph queries as an agent.
- Show multiple warnings and require explicit human-run approval via `production-safety-guards`.
- Provide `SELECT`/`ASK` preview and affected triple count first.
- Require graph backup/export and rollback plan before any human execution.
- Never update without a site graph scope.
- Do not delete identity or type triples unless doing an explicit full rebuild.
- Test on one site first, verify with `SELECT`/`ASK`, then roll out via approved human/pipeline execution.
- Prefer repo tools or `NeptuneClient` for programmatic updates.

---

## Common Recipes

```sparql
# Count energy meters.
PREFIX sj: <http://smartjoules.org/schema/BrickExtension#>
SELECT (COUNT(DISTINCT ?d) AS ?n) WHERE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?d a sj:Device ; sj:deviceType "em" .
  }
}
```

```sparql
# Fetch timeseries ids for an asset.
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX ref: <https://brickschema.org/schema/Brick/ref#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX sj: <http://smartjoules.org/schema/BrickExtension#>
SELECT ?abbr ?tsId WHERE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?asset rdfs:label "Emergency Critical AHU" ; brick:hasPoint ?p .
    ?p sj:abbr ?abbr ; ref:hasExternalReference [ ref:hasTimeseriesId ?tsId ] .
  }
} LIMIT 100
```

```sparql
# Immediate upstream equipment.
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX sj: <http://smartjoules.org/schema/BrickExtension#>
SELECT ?upstream ?deviceType WHERE {
  GRAPH <http://smartjoules.org/kmssh-nas/brick> {
    ?target rdfs:label "Chiller 1 180TR" ; brick:isFedBy ?u .
    ?u rdfs:label ?upstream ; sj:deviceType ?deviceType .
  }
} LIMIT 50
```
