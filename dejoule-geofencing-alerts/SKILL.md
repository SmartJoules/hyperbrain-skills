---
name: dejoule-geofencing-alerts
description: Geofencing and spatial-context alerting guide for DeJoule/SmartJoules. Use when improving smart alerts with site, floor, zone, component geofences, location-aware suppression/routing/escalation, or integrating geospatial logic with Neptune, ontology-service, and Brick Schema.
---

# DeJoule Geofencing Alerts

**Scope:** Smart Alert services, `jt-api-v2`, `JouleTRACK`, `ontology-service`, Amazon Neptune, Apache Jena/Fuseki on-prem graph.
**Goal:** Improve alert quality by adding spatial and semantic context: where the alert happened, what zone/floor/system it affects, who should receive it, and whether it should be suppressed, grouped, escalated, or enriched.

For DeJoule, prefer **semantic geofencing** from the ontology graph before GPS-only logic. HVAC assets are fixed plant/building objects, so `brick:hasLocation`, `brick:isPartOf`, `brick:feeds`, and SmartJoules identity keys usually produce better alert decisions than latitude/longitude alone.

---

## When To Use

Use this skill when asked to:

- Improve alert routing, suppression, deduplication, severity, or escalation using location.
- Add site/floor/zone/component geofences to smart alerts.
- Connect alert events to Brick locations in Neptune or Fuseki.
- Detect alerts from unmapped, moved, or location-inconsistent devices.
- Build APIs or UI that show impacted zones, nearby equipment, upstream/downstream blast radius, or responsible teams.
- Model geofence definitions in ontology-service.

---

## Geofencing Model

Use three layers, in this order:

| Layer | Best for | Source |
|---|---|---|
| Semantic geofence | Fixed building assets, AHUs, chillers, pumps, sensors, controllers | Neptune/Fuseki Brick graph |
| Physical geofence | Mobile users, service engineer position, campus/site boundary | lat/lon, circle/polygon |
| Hybrid geofence | Cross-checking event coordinates against ontology location | ontology + lat/lon |

Semantic geofence example:

```text
Alert asset
  -> device/component/controller IRI
  -> brick:hasLocation HVAC zone
  -> brick:isPartOf floor/building
  -> brick:feeds / brick:isFedBy related systems
  -> route, group, suppress, escalate, enrich
```

Physical geofence example:

```text
Point(lat, lon)
  -> site circle / campus polygon
  -> inside/outside/near-boundary
  -> allow, suppress, require confirmation, or flag mismatch
```

---

## Algorithms

### Site Circle

Use Haversine distance for quick site proximity checks.

```js
function haversineMeters(a, b) {
  const radius = 6371008.8;
  const toRad = (deg) => (deg * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLon = toRad(b.lon - a.lon);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return 2 * radius * Math.asin(Math.sqrt(h));
}

function insideCircle(point, fence) {
  return haversineMeters(point, fence.center) <= fence.radiusMeters;
}
```

Use for:
- engineer/user proximity to site
- site-level alert validation
- "outside site boundary" anomaly detection

Do not use this as the only location model for fixed HVAC equipment.

### Polygon Fence

Use polygon geofences for campuses, buildings, parking/service zones, and manually mapped critical areas. Apply a bounding-box prefilter before ray casting.

```js
function pointInPolygon(point, polygon) {
  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const xi = polygon[i].lon;
    const yi = polygon[i].lat;
    const xj = polygon[j].lon;
    const yj = polygon[j].lat;
    const intersects =
      yi > point.lat !== yj > point.lat &&
      point.lon < ((xj - xi) * (point.lat - yi)) / (yj - yi) + xi;
    if (intersects) inside = !inside;
  }
  return inside;
}
```

Use for:
- campus/building boundary checks
- contractor access windows
- mobile app task/acknowledgement proof
- zone polygons if available

### Grid Index

For many fences, prefilter by grid cell before exact geometry:

- Geohash: simple storage and prefix matching.
- S2/H3: stronger spatial indexing and neighborhood queries.
- Bounding box: enough for small per-site fence sets.

Start with bounding boxes for DeJoule sites unless there are hundreds of polygons per site.

### Semantic Geofence

Use graph traversal instead of geometry when the alert source is a known building object.

Inputs:
- `siteId`
- `deviceId`, `componentId`, `controllerId`, point id, or asset IRI
- optional alert family, metric abbreviation, source service

Output:
- site, floor, zone, asset labels
- nearby assets in same zone
- upstream/downstream related equipment
- location confidence
- mapping quality flags

Decision rule:

```text
If alert has known asset identity:
  resolve semantic geofence from Neptune/Fuseki
If alert also has lat/lon:
  cross-check physical fence against semantic site
If semantic location is missing:
  fall back to site-level context and emit mapping-health signal
```

---

## Alert Improvements

Use geofence context to improve alerts in these ways:

| Improvement | Rule |
|---|---|
| False-positive reduction | Suppress or lower severity when the event is outside the expected site/fence and source confidence is low |
| Better routing | Notify subscribers for the affected site, floor, zone, system, or equipment family |
| Deduplication | Group alerts by `siteId + zoneIri + alertFamily + timeWindow` |
| Severity escalation | Raise severity when multiple assets in one zone/system alert within a window |
| Blast-radius analysis | Include upstream/downstream equipment and same-zone assets |
| Maintenance awareness | Suppress or annotate alerts for zones under maintenance |
| Mapping health | Create low-priority mapping alerts when `brick:hasLocation` is missing or inconsistent |
| UI clarity | Show floor/zone/system names, not only device labels |

Recommended grouping key:

```text
geoGroupKey = siteId + ":" + (zoneIri || floorIri || assetIri) + ":" + alertFamily
```

Recommended escalation:

```text
sameZoneOpenAlerts >= 3 within 15 minutes -> escalate one level
sameZoneCriticalAsset + upstreamFailure -> escalate to plant/site owner
outsideFence + lowSourceConfidence -> suppress noisy notification, keep audit record
missingOntologyLocation -> notify internal mapping/ontology owners, not end operators
```

---

## Integration Points

### Smart Alert Brain

Add geofence enrichment before notification fan-out.

Suggested hook points:
- `smart-alert-brain-service/services/EventTransformer.js`: attach `geoContext` while transforming events.
- Alert brain/facade/service: dedupe, suppress, escalate, and group using `geoGroupKey`.
- Reminder/escalation service: escalate by zone/floor/site owner, not only generic subscriber list.
- Observer/status monitor: flag assets with missing or stale ontology mappings.

Recommended event extension:

```json
{
  "geoContext": {
    "siteId": "suh-hyd",
    "assetIri": "http://smartjoules.org/suh-hyd#Device_123",
    "deviceId": "suh-hyd_123",
    "componentId": "ahu-1",
    "source": "ontology",
    "siteDistanceMeters": null,
    "insideSiteFence": true,
    "zoneIri": "http://smartjoules.org/suh-hyd#Region_2_icu",
    "zoneLabel": "ICU AHU Zone",
    "floorIri": "http://smartjoules.org/suh-hyd#Floor_2",
    "floorLabel": "Second Floor",
    "nearbyAssets": [],
    "upstreamAssets": [],
    "downstreamAssets": [],
    "confidence": 0.92,
    "flags": []
  }
}
```

Keep `geoContext` small in hot paths. Store large related-asset lists separately or fetch on demand for alert detail pages.

### Notification Service

Use `geoContext` to:
- choose subscriber groups by `siteId`, `floorIri`, `zoneIri`, asset family, and severity
- include floor/zone names in SMS/WhatsApp/email templates
- avoid one notification per asset when one zone-level alert is enough
- add "same zone affected" counts in operator-facing messages

### JouleTRACK UI

Display:
- site, floor, zone, asset label
- confidence/mapping status for internal users
- related open alerts in the same zone/system
- impacted upstream/downstream equipment from ontology

UI guards:
- Never make authorization decisions from frontend geofence state.
- Hide internal mapping-health details from normal customer operators unless intended.
- Keep RBAC checks server-side for zone/floor scoped actions.

### API Boundary

Expose resolved context through a stable API shape:

```http
GET /api/alerts/:id/geo-context
GET /api/sites/:siteId/geofences
POST /api/alerts/:id/acknowledge
```

For acknowledgement APIs that use user/device geofencing:
- validate user session and RBAC first
- validate location freshness, accuracy, and fence server-side
- record the decision inputs in audit metadata

---

## Neptune And Ontology Integration

Use Neptune/Fuseki for relatively stable semantic facts:
- site lat/lon
- floors and zones
- `brick:hasLocation` relations
- equipment feeds/is-fed-by relationships
- controller/device/component identity
- optional geofence definitions

Do not store fast-changing alert incidents in Neptune. Keep incidents/events in the alert store/PostgreSQL/Vigilante path, and enrich them from the graph.

### Named Graph Rule

Always scope queries:

```sparql
GRAPH <http://smartjoules.org/<siteId>/brick> {
  ...
}
```

### Prefixes

```sparql
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX sj:    <http://smartjoules.org/schema/BrickExtension#>
PREFIX ref:   <https://brickschema.org/schema/Brick/ref#>
PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>
PREFIX xsd:   <http://www.w3.org/2001/XMLSchema#>
```

### Fetch Site Coordinates

```sparql
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX sj: <http://smartjoules.org/schema/BrickExtension#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?site ?label ?lat ?lon WHERE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?site a brick:Building ;
          sj:siteId "suh-hyd" ;
          rdfs:label ?label ;
          brick:latitude ?lat ;
          brick:longitude ?lon .
  }
} LIMIT 1
```

### Resolve Asset Location

Anchor by identity, not label. Prefer exact ids such as `sj:deviceId`, `sj:abbr`, or component ids modeled by the ontology.

```sparql
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX sj: <http://smartjoules.org/schema/BrickExtension#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?asset ?assetLabel ?zone ?zoneLabel ?floor ?floorLabel WHERE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?asset sj:deviceId "suh-hyd_1" ;
           rdfs:label ?assetLabel .

    OPTIONAL {
      ?asset brick:hasLocation ?zone .
      OPTIONAL { ?zone rdfs:label ?zoneLabel . }
      OPTIONAL {
        ?zone brick:isPartOf ?floor .
        ?floor a brick:Floor ;
               rdfs:label ?floorLabel .
      }
    }
  }
} LIMIT 20
```

### Find Same-Zone Assets

```sparql
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX sj: <http://smartjoules.org/schema/BrickExtension#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?thing ?label ?type WHERE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?anchor sj:deviceId "suh-hyd_1" ;
            brick:hasLocation ?zone .
    ?thing brick:hasLocation ?zone ;
           a ?type ;
           rdfs:label ?label .
  }
} LIMIT 100
```

### Find Impacted Equipment

```sparql
PREFIX brick: <https://brickschema.org/schema/Brick#>
PREFIX sj: <http://smartjoules.org/schema/BrickExtension#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

SELECT ?relation ?asset ?label ?deviceType WHERE {
  GRAPH <http://smartjoules.org/suh-hyd/brick> {
    ?target sj:deviceId "suh-hyd_1" .
    {
      ?target brick:feeds ?asset .
      BIND("downstream" AS ?relation)
    }
    UNION
    {
      ?target brick:isFedBy ?asset .
      BIND("upstream" AS ?relation)
    }
    OPTIONAL { ?asset rdfs:label ?label . }
    OPTIONAL { ?asset sj:deviceType ?deviceType . }
  }
} LIMIT 100
```

### Store Optional Geofence Definitions

If geometry needs to live in the ontology, use `sj:` extension terms and keep WKT/GeoJSON literals compact. Validate with SHACL before ingestion.

Example shape of data:

```turtle
@prefix sj: <http://smartjoules.org/schema/BrickExtension#> .
@prefix brick: <https://brickschema.org/schema/Brick#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<http://smartjoules.org/suh-hyd#SiteFence>
  a sj:Geofence ;
  sj:appliesTo <http://smartjoules.org/suh-hyd#suh-hyd> ;
  sj:centerLat "17.4483"^^xsd:decimal ;
  sj:centerLon "78.3915"^^xsd:decimal ;
  sj:radiusMeters "250"^^xsd:decimal .

<http://smartjoules.org/suh-hyd#ICUZoneFence>
  a sj:Geofence ;
  sj:appliesTo <http://smartjoules.org/suh-hyd#Region_2_icu> ;
  sj:geoJson "{\"type\":\"Polygon\",\"coordinates\":[...]}" .
```

Prefer semantic `brick:hasLocation` for floor/zone decisions until exact polygons are maintained.

---

## On-Prem Jena/Fuseki

The same SPARQL queries should run against Apache Jena Fuseki if named graph IRIs stay identical.

Recommended sync:

```text
Neptune export
  -> Turtle/N-Quads named graph dump
  -> load into Fuseki dataset
  -> verify graph list and triple counts
  -> configure alert service graph adapter endpoint
```

Operational rules:
- Keep graph IRIs identical between cloud Neptune and on-prem Fuseki.
- Treat cloud Neptune as source of truth unless an on-prem deployment explicitly owns site graph writes.
- Sync static ontology data separately from alert events.
- Version each graph export with site id, timestamp, source commit, and triple count.
- Use one adapter interface in alert code: `query(siteId, sparql, params)` with Neptune/Fuseki selected by environment.

---

## Implementation Pattern

Create a small enrichment service rather than scattering graph queries through alert code.

```text
Alert event
  -> GeoContextService.enrich(event)
  -> OntologyLocationResolver
  -> PhysicalFenceEvaluator
  -> AlertDecisionEngine
  -> Notification routing/escalation
```

Pseudocode:

```js
async function enrichAlertWithGeoContext(event) {
  const identity = event.deviceId || event.componentId || event.assetId;
  const semantic = identity
    ? await ontologyLocationResolver.resolve(event.siteId, identity)
    : null;

  const physical = event.lat && event.lon
    ? await physicalFenceEvaluator.evaluate(event.siteId, {
        lat: event.lat,
        lon: event.lon,
        accuracyMeters: event.accuracyMeters,
        capturedAt: event.locationCapturedAt
      })
    : null;

  return mergeGeoContext({ siteId: event.siteId, semantic, physical });
}

function decideAlert(event, geoContext) {
  if (geoContext.flags.includes("outside_site_fence") && event.sourceConfidence < 0.7) {
    return { action: "suppress_notification", keepAudit: true };
  }
  if (geoContext.sameZoneOpenAlertCount >= 3) {
    return { action: "escalate", groupBy: geoContext.geoGroupKey };
  }
  return { action: "notify", routeBy: geoContext.zoneIri || geoContext.siteId };
}
```

### Caching

Cache ontology lookups aggressively:

| Cache key | TTL |
|---|---|
| `site:<siteId>:coords` | 24 hours |
| `asset-location:<siteId>:<identity>` | 1-6 hours |
| `same-zone-assets:<siteId>:<zoneIri>` | 15-60 minutes |
| `feed-impact:<siteId>:<assetIri>` | 15-60 minutes |

Invalidate on graph version change, site bootstrap update, device mapping update, or explicit ontology sync.

### Data Storage

Store event decisions with alert records:

```json
{
  "geoGroupKey": "suh-hyd:http://smartjoules.org/suh-hyd#Region_2_icu:temp-high",
  "geoContextSummary": {
    "zoneLabel": "ICU AHU Zone",
    "floorLabel": "Second Floor",
    "confidence": 0.92,
    "flags": []
  },
  "decision": {
    "action": "escalate",
    "reason": "same-zone-alert-threshold"
  }
}
```

Do not put full geometry or large graph traversals into every alert row. Store compact summaries and fetch detailed context on demand.

---

## Testing

Unit tests:
- Haversine distance with known coordinate pairs.
- Point-in-polygon including boundary, vertex, and outside cases.
- Bounding-box prefilter.
- Semantic merge behavior when ontology is missing or partial.

Contract tests:
- SPARQL queries against fixture TTL in Fuseki or a mocked graph client.
- Site graph scoping is always present.
- Identity keys are used instead of labels for production lookups.

Alert behavior tests:
- outside site fence suppresses noisy notification but keeps audit record.
- same-zone multiple alerts group and escalate.
- missing `brick:hasLocation` falls back to site context and emits mapping-health signal.
- upstream/downstream impact list enriches high-severity messages.

Performance tests:
- one graph lookup per alert group, not per recipient.
- cache hit path does not call Neptune/Fuseki.
- batch enrichment handles alert bursts without unbounded parallel queries.

---

## Review Smells

- Querying Neptune once per subscriber or notification template.
- Unscoped SPARQL queries without `GRAPH <http://smartjoules.org/<siteId>/brick>`.
- Storing every alert incident as triples in Neptune.
- Using frontend-only geofencing for acknowledgement or access decisions.
- Relying on labels instead of `sj:deviceId`, component ids, controller ids, or IRIs.
- Treating GPS as authoritative for fixed plant assets when ontology has a better semantic location.
- Suppressing alerts permanently when ontology mapping is missing.
- Adding polygon checks without accuracy/freshness checks for mobile coordinates.
- Returning internal graph IRIs to normal users when labels are enough.
- Mixing RBAC decisions with geofence decisions without audit logs.
