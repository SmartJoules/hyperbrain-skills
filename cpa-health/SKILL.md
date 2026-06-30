---
name: cpa-health
description: Holistic health audit of CPA (Chiller Plant Automation) and the full IoT stack — sensors, PostgreSQL, CPA runtime, InfluxDB, commands, BMS.
origin: DeJoule
---

# CPA Health Monitor

Holistic health audit of CPA (Chiller Plant Automation) and the full IoT stack that enables it.

Checks every layer: sensors → PostgreSQL → CPA runtime → InfluxDB → commands → BMS — and reports what's healthy, degraded, or broken.

## Trigger

User says anything like:
- "how is CPA doing at {site}?"
- "health check {site}"
- "is CPA working at {site}?"
- "/cpa-health {site}"
- "daily audit for {site}"
- "what's the status of {site}?"

## Input Parsing

- **site_id**: Map hospital name to site ID (same mapping as /cpa-rca)
- **time_range**: Default to last 6 hours. If "today" → since midnight IST. If "yesterday" → 24h.
- **depth**: "quick" (5 min, top-level only) vs "full" (15 min, all layers). Default: full.

## Health Check Layers

Run ALL layers in parallel where possible. Each layer produces a status: HEALTHY / DEGRADED / DOWN / UNKNOWN.

---

### Layer 1: Controller & Gateway Connectivity

**What**: Is the JouleBox online and talking to the cloud?

**Query** `mcp__morpheus__query_metrics`:
```
bucket: iot-cloud-metrics
measurement: controllerconnectivity_1
site_id filter: siteid == {site}
time_range: 1h
```

Also check gateway:
```
bucket: iot-cloud-metrics
measurement: gatewayconnectivity_1
site_id filter: siteid == {site}
time_range: 1h
```

| Signal | Meaning |
|--------|---------|
| `status = 1` | Controller online (AWS IoT connected OR CPU metrics present) |
| `status = 0` | Controller offline (both AWS IoT AND CPU metrics down) |
| Gateway `status = 1` | JouleBox master identified, single master consensus |
| Gateway `status = 0` | No master or multiple masters (consensus failure) |

**Healthy**: Both controller and gateway status = 1 consistently
**Degraded**: Intermittent 0s (flapping)
**Down**: Sustained 0s for 15+ minutes

---

### Layer 2: Sensor Data Quality

**What**: Are sensors feeding fresh data into the system?

**Controller uptime (KEY — identifies offline controllers):**
```
bucket: iot-cloud-metrics
measurement: controllerservicesuptime_1
site_id filter: siteid == {site}
time_range: 1h
```

Fields: `uptimestatus` (int, 1=UP, 0=DOWN)
Tags: `controllerid`, `controllertype`, `siteid`

Check every 1 minute. If `uptimestatus=0` persistently, that controller's devices won't have fresh data. This is KEY for identifying which controllers are offline.

**Component data quality:**

Use `mcp__morpheus__query_metrics`:
```
bucket: iot-cloud-metrics
measurement: componentdataqualityabsolute_1
site_id filter: siteid == {site}
time_range: 6h
```

Fields:
- `Expected` — expected data points in window
- `ActualNonNull` — actual non-null data points received
- `NullDeviceParams` — count of null device parameters
- `DataExpressionEvalError` — computed parameter evaluation errors
- `DataExpressionSyntaxError` — syntax errors in data expressions
- `DataExpressionBadOperandError` — bad operand errors
- `AbsentDeviceParams` — absent/missing device parameters
- `ContextNotFound` — context lookup failures
- `OutOfBoundsError` — values outside expected bounds
- `MaintenanceMode` — parameters in maintenance mode
- `SiteIsDown` — site down indicator

Tags: `componentid`, `siteid`

Quality formula: `ActualNonNull / Expected * 100`

**Device-level data quality (complementary to component-level):**
```
bucket: iot-cloud-metrics
measurement: devicedataquality_1
site_id filter: siteid == {site}
time_range: 6h
```

Also check for data errors:
```
bucket: data-errors-context
site_id: {site}
time_range: 6h
```

And check CPA's `data_not_available` events:
```
bucket: cpa_logs_30_days
measurement: asset_event
site_id: {site}
time_range: 6h
Filter: event_type = "data_not_available"
```

| Signal | Meaning |
|--------|---------|
| Data quality > 95% | Sensors feeding reliably |
| Data quality 80-95% | Some gaps — RL may intermittently fail |
| Data quality < 80% | Significant data loss — CPA running on stale/missing data |
| `data_not_available` events | CPA explicitly couldn't get sensor data |

**Data flow**: Sensors → controllerFirmware → MQTT `data/+/recent` → iot-application → PostgreSQL `component_data` → CPA reads. Breakage at any point = stale data.

**CPA staleness rule**: Data older than 5 minutes = `None`. CPA falls to fail_safe.

---

### Layer 3: CPA Service Health

**What**: Is the CPA service running and producing optimization records?

**Query** `mcp__morpheus__query_metrics`:
```
bucket: cpa_logs_30_days
measurement: asset_optimize
site_id: {site}
time_range: 6h
aggregate_fn: count
aggregate_window: 1h
fields: ["setpoint"]
```

This gives optimization record counts per asset per hour.

| Signal | Meaning |
|--------|---------|
| Consistent records every hour per asset | CPA running normally |
| Records for some assets but not others | Partial — some assets not being optimized |
| Zero records for 1+ hours | CPA may be stopped or crashed |
| Records present but low count | Alternate cycle or asset was offline part of the time |

**Also check Loki** (use `mcp__grafana__query_loki_logs`):

> **Loki URL**: Use `url: https://loki-2.smartjoules.org` for ALL Loki queries. This instance has both edge/IoT logs (firmware, application, systemd, gateway, hostservice) and CPA logs (`chillerplantautomation`).

Edge health check:
```
url: https://loki-2.smartjoules.org
logql: {iot_siteid="{site}", iot_service_name="firmware"} |~ "(?i)(NoResponseError|error|exception)"
```

CPA service check:
```
url: https://loki-2.smartjoules.org
logql: {iot_siteid="{site}", iot_service_name="chillerplantautomation"} |~ "(?i)(error|exception|traceback|restart)"
```

---

### Layer 4: RL Performance

**What**: Is the RL making good decisions or falling back to emergency mode?

**Query** `mcp__morpheus__query_metrics`:
```
bucket: cpa_logs_30_days
measurement: asset_event
site_id: {site}
time_range: 6h
aggregate_fn: count
aggregate_window: 6h
fields: ["event_id"]
```

Group by event_type and asset. Count:
- `rl_optimize` (id=7) = healthy RL decisions
- `rl_fail_safe` (id=11) = RL fallback (observable outside bounds)
- `condition_not_met` (id=1) = normal command cycle
- `data_not_available` (id=2) = sensor data missing

**Fail-safe ratio** per asset: `rl_fail_safe / (rl_optimize + rl_fail_safe) * 100`

| Fail-safe ratio | Meaning |
|-----------------|---------|
| < 5% | Healthy — RL is learning and exploiting |
| 5-20% | Degraded — RL falling back periodically (check observable bounds) |
| > 20% | Problem — RL barely controlling, mostly proportional correction |
| 100% | Critical — RL not functioning, pure emergency mode |

**Also check** `rl_failed` measurement:
```
bucket: cpa_logs_30_days
measurement: rl_failed
site_id: {site}
time_range: 6h
```

| error_code | Meaning | Action |
|------------|---------|--------|
| 1 (INSUFFICIENT_REWARDS) | No Q-table data (bootstrap or 24h purge) | Wait for data accumulation, or seed rewards |
| 2 (OBSERVABLE_DATA_NOT_FOUND) | Sensor offline | Check Layer 2 |
| 3 (ACTION_DATA_NOT_FOUND) | VFD/BMS not reporting action value | Check BMS |

---

### Layer 5: Command Execution

**What**: Are CPA's commands reaching the equipment and executing?

**Query** `mcp__morpheus__query_metrics`:
```
bucket: cpa_logs_30_days
measurement: command_feedback
site_id: {site}
time_range: 6h
aggregate_fn: count
aggregate_window: 6h
fields: ["action_status"]
```

Count by asset and status. Compute per-asset:
- **Success rate**: `(status 1 + 4 + 17 + 18) / total * 100`
- **Timeout rate**: `(status -1 + 7) / total * 100`
- **Failure rate**: `(status 0 + 3 + 6) / total * 100`
- **Mode mismatch rate**: `(status 8) / total * 100`

| Metric | Healthy | Degraded | Problem |
|--------|---------|----------|---------|
| Success rate | > 90% | 70-90% | < 70% |
| Timeout rate | < 5% | 5-15% | > 15% |
| Failure rate | < 5% | 5-10% | > 10% |
| Mode mismatch | 0% | — | > 0% (BMS issue) |

**Per-asset breakdown** is critical — one bad asset can drag down the site average.

---

### Layer 6: Safety Net Status

**What**: Are safety nets configured, and are they firing when they should?

**Query Loki**:
```
url: https://loki-2.smartjoules.org
logql: {iot_siteid="{site}", iot_service_name="chillerplantautomation"} |~ "Safety Net"
time_range: 6h
limit: 50
```

Look for:
- `Safety Net [{asset_id}@{action}]: DISABLED` — expected for unconfigured actions
- `{asset_id} state set to Emergency State` — modulate safety net firing
- Alert logs with `SUPERSEDE_CONDITION_MET_*` — safety net overrides active

**Also check** `asset_event` for `event_type: safety_net` (id=10):
```
bucket: cpa_logs_30_days
measurement: asset_event
site_id: {site}
time_range: 6h
Filter: event_type containing "safety"
```

---

### Layer 7: Watchdog & Service Health

**What**: Are edge services running? Has anything been restarted?

**Query** `mcp__morpheus__query_metrics`:
```
bucket: iot-metrics
measurement: containersping
site_id filter: siteid == {site}
time_range: 1h
```

Fields: `response` (1 = alive, 0 = dead per container)

Also check for restarts:
```
bucket: iot-metrics
measurement: containersrestart
site_id filter: siteid == {site}
time_range: 24h
```

Fields: `status` (string, values: "success")
Tags: `container`, `controllerid`, `controllertype`, `siteid`

`status = "success"` means that container was restarted.

**JouleBox Health (BEST single measurement for overall health):**
```
bucket: iot-metrics
measurement: jouleboxhealthandstate
site_id filter: siteid == {site}
time_range: 10m
```

Fields:
- `healthscore` (float, 0-100) — overall health percentage
- `networkhealth` (int, 0/1) — network connectivity
- `overallhealth` (int, 0/1) — overall health flag
- `postresqlhealth` (int, 0/1) — PostgreSQL database health (note: typo in field name is intentional — "postresql" not "postgresql" in InfluxDB)
- `ssdhealth` (int, 0/1) — SSD storage health
- `state` (int) — 1=master, 2=CPA/slave

Tags: `controllerid`, `controllertype` (joulebox_v2), `siteid`

Healthy: healthscore=100, all fields=1
Degraded: healthscore<100 or any field=0
Down: no records in last 10 minutes

**Controller Reboots:**
```
bucket: iot-metrics
measurement: controllerrestart
site_id filter: siteid == {site}
time_range: 24h
```

Fields: `restarttime` (string, timestamp of last reboot)
Tags: `controllerid`, `controllertype`, `siteid`

**NAS & Network Connectivity:**
```
bucket: iot-metrics
measurement: basicnetworkhealth
site_id filter: siteid == {site}
time_range: 1h
```

Fields: `nasconnectionstatus` (float, 1.0=connected, 0.0=disconnected)
Tags: `controllerid`, `controllertype`, `siteid`

**Loki check for CPA restarts**:
```
url: https://loki-2.smartjoules.org
logql: {iot_siteid="{site}", iot_service_name="chillerplantautomation"} |~ "(?i)(starting|started|restart|shutdown)"
```

**Loki check for container restarts**:
```
url: https://loki-2.smartjoules.org
logql: {iot_siteid="{site}", iot_service_name="hostservice"} |~ "(?i)(restart|chillerplantautomation)"
```

---

### Layer 8: Config Generation

**What**: Is cpa-conf-csv-gen running and producing fresh configs?

**Query Loki** (runs on cloud):
```
url: https://loki-2.smartjoules.org
logql: {job="cpa-autogen"} |~ "{site}"
time_range: 24h
limit: 20
```

Also check:
```
url: https://loki-2.smartjoules.org
logql: {job="cpa-autogen"} |~ "(?i)(error|failed|exception)"
time_range: 24h
```

| Signal | Meaning |
|--------|---------|
| Recent orchestration logs with site_id | Config generation active |
| No logs for site in 24h | Config may be stale |
| Error/failed logs | Config generation broken |

---

### Layer 9: Asset Selection Health

**What**: Is the right number of assets running?

**Query** `mcp__morpheus__query_metrics`:
```
bucket: cpa_logs_30_days
measurement: asset_selection_config
site_id: {site}
time_range: 6h
limit: 50
```

Compare `asset_required` vs `asset_running` per `asset_type`. If they match, selection is healthy. If `asset_running > asset_required`, too many running (waste). If `asset_running < asset_required`, too few (comfort risk).

---

### Layer 10: Circuit Health & Plant State

**What**: Are plant circuits healthy? Is any plant unexpectedly stopped?

**Query Loki**:
```
url: https://loki-2.smartjoules.org
logql: {iot_siteid="{site}", iot_service_name="chillerplantautomation"} |~ "circuits_healthy|circuit_unhealthy|Plant.*current=|Plant.*intended="
time_range: 6h
limit: 30
```

| Signal | Meaning |
|--------|---------|
| `Plant {id}: current=ON, intended=ON, circuits_healthy=True` | Plant running normally |
| `Plant {id}: current=OFF, intended=OFF` | Plant intentionally stopped (no chillers selected) |
| `circuits_healthy=False` | **PROBLEM** — a required circuit (pumps/CTs) is UNHEALTHY, blocking chiller start |
| `set_circuit_unhealthy` | Hardware state detected issue in a circuit |
| `ready_to_start=False (condenser=False)` | Condenser circuit not ready — pump/CT not operational |

**Multi-plant sites**: Each `plant_id` runs independently. Check per-plant, not just site-level.

---

### Layer 11: Edge Services & Non-CPA Health

**What**: Are non-CPA edge services healthy? (aws-jobs, firmware, recipe)

**Query Loki**:
```
url: https://loki-2.smartjoules.org
logql: {iot_siteid="{site}", iot_service_name="systemd"} |~ "aws-jobs|joule-recipe|firmware" |~ "restart|failed|Scheduled restart"
time_range: 24h
limit: 20
```

Also check recipe command mode mismatches:
```
url: https://loki-2.smartjoules.org
logql: {iot_siteid="{site}", iot_service_name="application"} |~ "does not match mode"
time_range: 6h
limit: 20
```

| Signal | Meaning |
|--------|---------|
| `aws-jobs.service: Scheduled restart job, restart counter is at {N}` | **aws-jobs crash loop** — controller may show "inactive" on JouleTrack despite being online |
| `Command source {X} does not match mode {Y}` | **Mode mismatch** — recipe/thermostat commands rejected. BMS operational issue. |
| High restart counter (>1000) | Service has been crash-looping for extended period |

**Important**: `aws-jobs` crash loop does NOT affect CPA or data flow. It only affects OTA updates and may cause JouleTrack dashboard to show "inactive".

---

### Layer 12: DL Model & Solution Freshness

**What**: For sites using `asl_forecast_dl_control` or `q_rl_lookUP`, are the DL solutions available?

Check if optimization records exist but with low counts or constant values — suggests PlantSolutionManager returning None.

**Query Loki**:
```
url: https://loki-2.smartjoules.org
logql: {iot_siteid="{site}", iot_service_name="chillerplantautomation"} |~ "PlantSolution|wetbulb|tonnage|solution.*None"
time_range: 6h
limit: 20
```

Also check `rl_failed` for the specific assets using DL control:
```
bucket: cpa_logs_30_days
measurement: rl_failed
site_id: {site}
time_range: 6h
```

If `error_code=1` (INSUFFICIENT_REWARDS) on assets with `q_rl_lookUP` logic → DL target may be missing/changing too fast for Q-table to build rewards.

---

## Output Format

```
# CPA Health Report: {Site Name} ({site_id})
**Time**: {timestamp} | **Window**: last {time_range}

## Overall: {HEALTHY / DEGRADED / DOWN}

| Layer | Status | Summary |
|-------|--------|---------|
| 1. Controller/Gateway | {status} | {one-line} |
| 2. Sensor Data | {status} | {one-line} |
| 3. CPA Service | {status} | {one-line} |
| 4. RL Performance | {status} | {one-line} |
| 5. Commands | {status} | {one-line} |
| 6. Safety Nets | {status} | {one-line} |
| 7. Watchdog/Services | {status} | {one-line} |
| 8. Config Generation | {status} | {one-line} |
| 9. Asset Selection | {status} | {one-line} |
| 10. Circuit/Plant Health | {status} | {one-line} |
| 11. Edge Services | {status} | {one-line} |
| 12. DL Model Freshness | {status} | {one-line} |

## Issues Found

### {Issue 1 title}
**Layer**: {N} | **Severity**: {HIGH/MEDIUM/LOW}
**What**: {description}
**Evidence**: {specific data}
**Impact**: {what this means for the plant}
**Action**: {what to do}

### {Issue 2 title}
...

## Asset-Level Detail

| Asset | Optimize Records | RL Fail-safe % | Cmd Success % | RL Failed | Notes |
|-------|-----------------|----------------|---------------|-----------|-------|
| {asset_name} | {count} | {pct}% | {pct}% | {count} | {flags} |
...

## Recommendations
1. {Prioritized action items}
```

---

## Quick Mode (5 min)

If `depth=quick`, only check:
- Layer 3 (CPA Service) — are optimization records arriving?
- Layer 4 (RL Performance) — fail-safe ratio
- Layer 5 (Commands) — success rate

Skip Layers 1, 2, 6, 7, 8, 9.

---

## Comparison / Trend Mode

If user asks "how is CPA compared to yesterday" or "trend for last week":

Query `asset_optimize` with `aggregate_window: 1d` for last 7 days. Compare:
- Daily optimization record counts
- Daily rl_fail_safe counts
- Daily command success rates

Flag any day with significant deviation from the 7-day average.

---

## Multi-Site Mode

If user asks "how are all sites doing":

1. Get all active sites from Neo4j: `MATCH (s:Site) RETURN s.siteId`
2. For each site, run Quick Mode in parallel (Layer 3 + 4 + 5 only)
3. Produce a summary table sorted by health score (worst first)

---

## IoT Data Flow Reference

```
Sensors/BMS
    |
    v
controllerFirmware (Modbus/BACnet → MQTT)
    |
    v
MQTT local broker (port 1884)
    |
    ├──> iot-application → PostgreSQL component_data
    |                          |
    |                          v
    |                      CPA reads (5-min freshness)
    |                          |
    |                          v
    |                    Optimization decisions
    |                          |
    |                          v
    |                    Commands → MQTT → BMS
    |                          |
    |                          v
    |                    Feedback → command_feedback
    |
    ├──> iot-gateway → AWS IoT → Kafka
    |                              |
    |                              v
    |                         InfluxDB cloud
    |                         (device_component/autogen)
    |
    └──> iot-metrics-uploader → InfluxDB cloud
                                (iot-metrics, cpa_logs_30_days)
```

## Key InfluxDB Buckets

| Bucket | Instance | Site tag name | Contents | Use for |
|--------|----------|---------------|----------|---------|
| `cpa_logs_30_days` | iot-influxdb (v2) | `site_id` | CPA optimization logs | Layers 3,4,5,6,9 |
| `iot-cloud-metrics` | iot-influxdb (v2) | `siteid` | Controller/gateway connectivity, data quality | Layers 1,2 |
| `iot-metrics` | iot-influxdb (v2) | `siteid` | Watchdog pings, container restarts, JouleBox health, resource usage | Layer 7 |
| `data-errors-context` | iot-influxdb (v2) | unknown | Component data error context | Layer 2 |
| `device_component/autogen` | timeseries (v1) | — | Raw sensor data | Sensor verification |

### Measurement Lists

**iot-cloud-metrics** (19 measurements):
```
controllerconnectivity_1, controllerconnectivity
gatewayconnectivity_1, gatewayconnectivity
componentdataqualityabsolute_1, componentdataqualityabsolute
devicedataquality_1, devicedataquality
controllerservicesuptime_1, controllerservicesuptime
controllerpackagesversions_1, controllerpackagesversions
absentdevicecontribution_1, absentdevicecontribution
nulldevicecontribution_1, nulldevicecontribution
lokicpu, lokidisk, lokimem
```

**iot-metrics** (28 measurements):
```
awsbroker, basicnetworkhealth, bmsxdevicemetricsv2, bmsxobjectmetricsv2,
commandstatus, containersping, containersrestart, controllerrestart,
cpuhealth, devconfigupdate, diskio, diskusage, gatewaybroker,
joulebox_services_status, jouleboxhealthandstate, networkinfo,
networkusage, pingstats, processesresourceusage, recipeeval,
recipeupdate, resourceusage, retentionrecipeassetstate,
retentionrecipecommandslog, service_detail, ssdstatus,
systemd_service_health, thermostat
```

**cpa_logs_30_days** (known measurements):
```
asset_state, asset_event, asset_optimize, command_feedback,
rl_failed, q_rl_actions_explained, asset_selection_config,
ordering_config, ti_events
```

> **MORPHEUS TOOL LIMITATIONS:**
> - `mcp__morpheus__influx_schema` only knows about `cpa_logs_30_days` and `device_component/autogen`. It does NOT know about `iot-cloud-metrics` or `iot-metrics` measurements.
> - `mcp__morpheus__query_metrics` `site_id` parameter only maps to `site_id` tag (`cpa_logs_30_days`). For `iot-cloud-metrics` and `iot-metrics`, MUST use `raw_flux` with `r["siteid"]` filter.
> - Always use `raw_flux` for `iot-cloud-metrics` and `iot-metrics` queries.
>
> **IMPORTANT: `mcp__morpheus__query_metrics` `site_id` parameter**: The tool's `site_id` parameter ONLY works for `cpa_logs_30_days` bucket (which uses `site_id` tag). For `iot-cloud-metrics` and `iot-metrics` buckets (which use `siteid` tag, all lowercase), you MUST use `raw_flux` with the correct filter:
> ```
> raw_flux: from(bucket: "iot-cloud-metrics")
>   |> range(start: -1h)
>   |> filter(fn: (r) => r["_measurement"] == "controllerconnectivity_1")
>   |> filter(fn: (r) => r["siteid"] == "{site}")
>   |> aggregateWindow(every: 5m, fn: last, createEmpty: false)
> ```

## Key Loki Labels

**Loki URL**: `https://loki-2.smartjoules.org` — use `url: https://loki-2.smartjoules.org` for ALL Loki queries.

Available labels: `iot_controllerid`, `iot_job`, `iot_service_name`, `iot_siteid`

| Label | Value | What |
|-------|-------|------|
| `iot_siteid` | `{site_id}` | Filter by site |
| `iot_service_name` | `chillerplantautomation` | CPA logs |
| `iot_service_name` | `firmware` | Controller firmware logs |
| `iot_service_name` | `application` | iot-application logs |
| `iot_service_name` | `hostservice` | Watchdog/service manager |
| `iot_service_name` | `gateway` | IoT gateway |
| `iot_service_name` | `metricsupload` | Metrics uploader |
| `iot_service_name` | `systemd` | System service logs |
| `job` | `cpa-autogen` | Config generation (cloud) |

## Quick JouleBox Health Check (Recommended First Query)

Fastest way to check if the site's JouleBox is healthy:

```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -10m)
  |> filter(fn: (r) => r["_measurement"] == "jouleboxhealthandstate")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> last()
  |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: ["_value"])
```

If healthscore=100 and all flags=1, JouleBox is healthy. If no data, JouleBox is offline.

---

## Loki Edge Diagnostics

Useful edge-level queries (always use `url: https://loki-2.smartjoules.org`):

**Firmware NoResponseErrors — identifies dead VFDs/sensors:**
```
url: https://loki-2.smartjoules.org
{iot_siteid="{site}", iot_service_name="firmware"} |~ "NoResponseError"
```
When ALL params for a device show NoResponseError, the device is completely unresponsive (dead VFD, broken Modbus cable, or device powered off).

**Service restarts:**
```
url: https://loki-2.smartjoules.org
{iot_siteid="{site}", iot_service_name="(systemd)"} |~ "Started|Stopped|Failed"
```

**Available service names on Loki** (`loki-2.smartjoules.org`):
firmware, application, gateway, hostservice, joule-recipe, metrics-upload, edgebolt, edgeboltfrontend, nas-interface, telegraf, promtail, systemd, containerd, dockerd, aws-iot-device-client, ahu-auto-*

---

## Critical Diagnostic Rules

- **Zero InfluxDB data does NOT mean CPA is down.** Check Loki first — CPA may be running fine but `iot-metrics-uploader` is broken (kih-mah pattern).
- **Controller "inactive" on JouleTrack can mean `aws-jobs` crash loop**, not actual offline. Check `controllerconnectivity_1` — if status=1, controller IS online (gob-coi pattern).
- **`condition_not_met` events are NORMAL.** They fire every optimization cycle. Only investigate if `suggested_value - present_value` is large and persistent.
- **Per-plant not per-site**: Multi-plant sites need per-plant breakdown. One plant can be healthy while another is UNHEALTHY.
- **Mode mismatch is NOT CPA**: `Command source X does not match mode Y` is an `iot-application` validation issue. Fix in JouleTrack controller settings.
- **Safety net expression typos**: Check for malformed numbers like `29.7.0` (double decimal). All CTs at a site often share the same expression — one typo breaks all.

## Severity Classification

| Severity | Criteria | Example |
|----------|----------|---------|
| **CRITICAL** | CPA down, controller offline, commands not executing | No optimize records 1h+, gateway status=0 |
| **HIGH** | RL not learning, significant command failures | Fail-safe >50%, timeout rate >15%, mode mismatch |
| **MEDIUM** | Partial degradation, some assets affected | Individual asset rl_failed, data quality 80-95% |
| **LOW** | Minor issues, informational | Bootstrap rl_failed after restart, occasional timeouts |
