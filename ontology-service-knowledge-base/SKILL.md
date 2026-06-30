---
name: ontology-service-knowledge-base
description: Knowledge base for SmartJoules/ontology-service. Use when working with DeJoule semantic building graphs, Amazon Neptune RDF/SPARQL, Brick Schema modeling, site named graphs, graph ingestion/update tooling, graph explorer, or when answering "how is this building wired?" questions.
---

# Ontology Service Knowledge Base

**Repository:** `SmartJoules/ontology-service`
**Purpose:** Queryable semantic model of SmartJoules buildings: equipment, controllers, devices, points, locations, loops, telemetry references, and control relationships.
**Primary store:** Amazon Neptune RDF graph, queried with SPARQL.
**Model:** Brick Schema plus SmartJoules extension vocabulary `sj:`.

---

## What This Repo Is

`ontology-service` turns scattered building configuration into a connected semantic graph.

It answers questions such as:
- Which AHUs serve this floor or zone?
- What feeds this chiller?
- Which controller hosts this device?
- Which device points feed this component metric?
- Which telemetry stream ID should be used for this point?
- What breaks if this controller/device/component fails?

The long-term service design is a read-side Ontology Service that hides RDF/SPARQL behind stable HTTP/MCP JSON APIs. Current repo tooling builds, validates, ingests, queries, explores, and documents the graph.

---

## Source Repo Map

| Path | Meaning |
|---|---|
| `README.md` | Product and operator overview |
| `CLAUDE.md` | Agent/engineer operating notes and current modeling decisions |
| `tools/neptune.ts` | Main CLI for graph list/query/export/update/S3 load |
| `tools/neptune-client.ts` | Shared IAM SigV4-signed Neptune HTTP client; use this instead of reimplementing signing |
| `tools/ingest.ts` | Node-by-node ingestion from site bootstrap JSON |
| `tools/build-*.ts` | Build CPA/config-derived graph artifacts: pumping groups, water loops, rated specs |
| `tools/brick.ts` | Offline Brick ontology lookup/query/validate helper |
| `tools/sj-schema.rq` | SmartJoules extension vocabulary definitions |
| `tools/sj-shapes.ttl` | SHACL validation shapes |
| `brick-kb/` | Vendored pinned Brick ontology, docs, examples, validation |
| `docs/neptune-graph-skill.md` | Repo-local Neptune query card |
| `docs/ontology-service-architecture-design.md` | CQRS/read-side service architecture |
| `node-reference.md` | Quick card for graph node types and edge meanings |
| `ontology-nodes.md` | Deeper modeling rationale |
| `web/explorer.html` and `tools/explorer.ts` | Read-only graph explorer UI |

Repo-local skills found in `SmartJoules/ontology-service`:
- `brick` - resolve Brick ontology questions from vendored `brick-kb`, never memory.
- `neptune-graph` - write/review safe SPARQL queries for the SmartJoules Neptune graph.

Both are included in this HyperBrain library as standalone skills.

---

## Runtime Prerequisites

Use these when working inside the ontology-service repo:

```bash
npm install
node --version   # Node >= 22; TypeScript files run directly
```

Neptune access needs:
- VPN to the Neptune VPC
- AWS profile `sjpl-aws` unless overridden with `AWS_PROFILE`
- `.env` with `NEPTUNE_READER`, `NEPTUNE_WRITER`, `NEPTUNE_PORT=8182`, `NEPTUNE_REGION=us-west-2`
- `SJ_API_TOKEN` only for tools that fetch source data from M2 APIs

If Neptune calls fail with `ENOTFOUND`, `ETIMEDOUT`, or `ECONNREFUSED`, check VPN first.

---

## Graph Model

| Concept | Convention |
|---|---|
| Per-site graph | `http://smartjoules.org/<siteId>/brick` |
| Shared schema graph | `http://smartjoules.org/schema` |
| Instance namespace | `http://smartjoules.org/<siteId>#<LocalName>` |
| Standard vocabulary | `brick: <https://brickschema.org/schema/Brick#>` |
| SmartJoules extension | `sj: <http://smartjoules.org/schema/BrickExtension#>` |
| Timeseries refs | `ref: <https://brickschema.org/schema/Brick/ref#>` |
| Query language | SPARQL 1.1 |
| Inference | Do not assume inference; parent Brick types and inverse edges are materialized where needed |

Always scope per-site queries with `GRAPH <http://smartjoules.org/<siteId>/brick> { ... }`.

---

## Core Node Types

| Node | Local IRI shape | Main types | Key fields |
|---|---|---|---|
| Site | `<siteId>` | `brick:Building` | `sj:siteId`, `rdfs:label`, timezone, location, tariff |
| Network | `<networkId>` | `sj:Network`, `brick:Collection` | `sj:networkId` |
| Controller | `Controller_<id>` | `sj:GatewayController` or `sj:MasterController`, `brick:Controller` | `sj:deviceId`, type, hardware/software |
| Slave controller | `SlaveController_<id>` | `sj:SlaveController`, `brick:Controller` | `sj:slaveId` |
| Device | `Device_<id>` | `sj:Device`, `brick:Equipment` | `sj:deviceId`, `sj:deviceType` |
| Point | `Point_<deviceOrComponentId>_<abbr>` | Brick point class plus `brick:Point` | `sj:abbr`, `sj:ioDirection`, unit, bounds |
| Component | `Component_<componentId>` | `sj:Component`, `brick:Equipment` plus native class | `sj:deviceId`, `sj:deviceType`, system side |
| Floor/Zone | `Floor_<id>`, `Region_<id>_<slug>` | `brick:Floor`, `brick:HVAC_Zone` | label, region/floor id |
| Timeseries reference | `TsRef_<id>_<abbr>` | `ref:TimeseriesReference` | `ref:hasTimeseriesId "<id>:<abbr>"` |
| Water loops | `CDW_System`, `CHW_System` | `brick:Condenser_Water_System`, `brick:Chilled_Water_System` | members, inferred feeds provenance |
| Pumping group | `ParallelPumpingGroup_*` | `sj:ParallelPumpingGroup`, `brick:Collection` | group id/function/device/circuit |

Family filtering often uses `sj:deviceType` strings, not only Brick classes. Example: energy meters are `sj:deviceType "em"`.

---

## Query Technique

Use the repo CLI. Do not hand-roll signed HTTP:

```bash
node tools/neptune.ts graphs
node tools/neptune.ts query --format table --query 'SELECT * WHERE { ?s ?p ?o } LIMIT 5'
node tools/neptune.ts query --file query.rq --format table
node tools/neptune.ts export --out neptune-dump --format turtle
```

For application code or scripts, import `NeptuneClient` from `tools/neptune-client.ts`. It signs requests with IAM SigV4 and exposes `query`, `select`, `ask`, `update`, `startLoad`, and `loadStatus`.

### Safe Query Template

```sparql
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX sj:    <http://smartjoules.org/schema/BrickExtension#>
PREFIX ref:   <https://brickschema.org/schema/Brick/ref#>
PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?label ?type WHERE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?x a ?type ;
       rdfs:label ?label .
  }
} LIMIT 50
```

Rules:
- Always include a site `GRAPH`.
- Always include `LIMIT` for row-returning `SELECT`.
- Count with `COUNT`, not by fetching rows.
- Avoid unanchored property paths.
- Avoid bare `?s ?p ?o` except for one known IRI with a tight limit.
- Prefer exact `sj:deviceId`, `sj:abbr`, `sj:deviceType`, or `rdfs:label` matches.
- Live values are not in Neptune; fetch `ref:hasTimeseriesId`, then query the time-series store.

### Common Recipes

```sparql
# Count energy meters at a site.
PREFIX sj: <http://smartjoules.org/schema/BrickExtension#>
SELECT (COUNT(DISTINCT ?d) AS ?n) WHERE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?d a sj:Device ; sj:deviceType "em" .
  }
}
```

```sparql
# Get telemetry stream ids for an asset's points.
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX ref: <https://brickschema.org/schema/Brick/ref#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX sj: <http://smartjoules.org/schema/BrickExtension#>
SELECT ?abbr ?tsId WHERE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?comp rdfs:label "Emergency Critical AHU" ; brick:hasPoint ?p .
    ?p sj:abbr ?abbr ;
       ref:hasExternalReference [ ref:hasTimeseriesId ?tsId ] .
  }
} LIMIT 100
```

```sparql
# Trace which device points feed a component metric.
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX sj: <http://smartjoules.org/schema/BrickExtension#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?device ?abbr WHERE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?comp rdfs:label "Emergency Critical AHU" ; brick:hasPoint ?cp .
    ?cp rdfs:label "Area Temperature" ; sj:derivedFrom ?dp .
    ?dp sj:abbr ?abbr ; brick:isPointOf ?dev .
    ?dev rdfs:label ?device .
  }
} LIMIT 50
```

```sparql
# Water-loop overview.
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX sj: <http://smartjoules.org/schema/BrickExtension#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT ?label ?type (COUNT(DISTINCT ?m) AS ?members) (SAMPLE(?d) AS ?feedsProvenance) WHERE {
  GRAPH <http://smartjoules.org/kmssh-nas/brick> {
    ?loop a ?type ; rdfs:label ?label .
    VALUES ?type { brick:Condenser_Water_System brick:Chilled_Water_System }
    OPTIONAL { ?loop brick:hasPart ?m }
    OPTIONAL { ?loop sj:feedsDerivation ?d }
  }
} GROUP BY ?label ?type ORDER BY ?type
```

---

## Update Technique

Writes are irreversible. Use surgical, idempotent SPARQL updates scoped to one site graph. Do not use `DROP GRAPH` unless the user explicitly asked for a full rebuild.

Use:

```bash
node tools/neptune.ts update --file update.rq
node tools/neptune.ts update --query '...'
```

Preferred update pattern:

```sparql
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX sj:    <http://smartjoules.org/schema/BrickExtension#>
PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>

DELETE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?component sj:someMutablePredicate ?oldValue .
  }
}
INSERT {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?component sj:someMutablePredicate "newValue" .
  }
}
WHERE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?component a sj:Component ;
               sj:deviceId "suh-hyd_1" .
    OPTIONAL { ?component sj:someMutablePredicate ?oldValue . }
  }
}
```

Update rules:
- Scope every `DELETE`/`INSERT`/`WHERE` to `GRAPH <.../<site>/brick>`.
- Match target nodes by stable identity keys (`sj:siteId`, `sj:deviceId`, `sj:abbr`, `sj:groupId`) rather than labels when possible.
- Do not delete immutable identity triples: `rdf:type` and identity keys.
- Use `OPTIONAL` in `WHERE` so updates are idempotent and no-op cleanly.
- Run on one site, verify with `SELECT`/`ASK`, then roll out.
- For large site loads, emit N-Quads and use S3 bulk loader. Per-site named graphs require N-Quads because the graph IRI is the fourth term.

Bulk load flow:

```bash
node tools/ingest.ts suh-hyd --emit-nq
node tools/s3-stage.ts suh-hyd
node tools/setup-loader-role.ts
node tools/neptune.ts load --source s3://<bucket>/batch-ingestion/suh-hyd/ \
  --role arn:aws:iam::<acct>:role/NeptuneLoadFromS3Role
```

---

## Brick Schema Technique

Use the vendored offline `brick-kb`, not memory:

```bash
node tools/brick.ts define Chiller
node tools/brick.ts subclasses Equipment
node tools/brick.ts superclasses Air_Handler_Unit
node tools/brick.ts search "pressure sensor"
node tools/brick.ts example Chiller
node tools/brick.ts points Air_Handler_Unit
node tools/brick.ts validate model.ttl
```

Brick modeling rules used in this repo:
- Brick classes describe standard building concepts; `sj:` extends them for SmartJoules-specific device families, control metadata, telemetry references, and network topology.
- Neptune does not infer; emit parent types explicitly, such as `sj:Device, brick:Equipment` or leaf point class plus `brick:Point`.
- Use `brick:hasPoint` / `brick:isPointOf` for equipment-point links.
- Use `brick:hasLocation` for equipment/controller/device/component placement.
- Use `brick:feeds` / `brick:isFedBy` for flow/energy path, not spatial containment.
- Use `brick:hasPart` / `brick:isPartOf` for collection/system/spatial membership where valid.
- Validate candidate TTL with Brick/SHACL before writing.
- If Brick aliases are confusing, run `define`; Brick uses `owl:equivalentClass` aliases such as AHU names.

Spatial modeling:
- Prefer the most specific available location.
- Equipment has `brick:hasLocation`; spatial nodes do not have location to equipment.
- Current live clean model often uses `brick:Building -> brick:Floor -> brick:HVAC_Zone`; newer spatial guidance may use `Site -> Building -> Floor -> Room`.
- Check repo docs before changing spatial hierarchy, because older docs and live graph conventions differ.

---

## Verification

Use repo tools:

```bash
node tools/verify.ts <site> --json
node tools/verify.ts <site> --only=components
node tools/regenerate.ts <site> --out /tmp/<site>.bootstrap.json
node tools/explorer.ts
```

For query correctness:
- Run an aggregate first.
- Verify target node by identity.
- Run the exact traversal with `LIMIT`.
- If updating, run `ASK`/`SELECT` before and after.

For ontology correctness:
- Look up Brick definitions from `brick-kb`.
- Validate Turtle locally.
- Use SHACL checks where available.

---

## When Answering Users

1. Ask for `siteId` if the graph query is site-specific and the user did not provide one.
2. Use `ontology-service-knowledge-base` for repo architecture and safe operations.
3. Use `neptune-graph` for SPARQL query details.
4. Use `brick` for Brick correctness.
5. Never invent graph facts. Query Neptune or say what needs to be queried.
6. Never make write/update claims without a scoped SPARQL update and verification query.
