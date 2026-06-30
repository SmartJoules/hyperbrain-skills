---
name: iot-health
description: Deep IoT infrastructure health diagnosis — controllers, network, firmware, data pipeline, services. Answers "why is data not reaching CPA" not "why is CPA making bad decisions".
origin: DeJoule
---

# IoT Health Diagnostics

Deep infrastructure health check for SmartJoules IoT sites. Diagnoses the physical layer: controllers, network, firmware, data pipeline, services.

## Trigger

User says anything like:
- "iot health for {site}"
- "what's happening with controllers at {site}"
- "why is data not coming from {site}"
- "check infrastructure at {site}"
- "/iot-health {site}"
- "controller issues at {site}"
- "network problems at {site}"

## Input Parsing

- **site_id**: Map hospital name to site ID (Apollo=aph-*, Aster=ash-*, KIMS=khh-*/kims/kih-*, Sunshine=suh-*, etc.)
- **time_range**: Default last 1 hour for real-time, 6h for deep dive. If "today" → since midnight IST.
- **focus**: Optional — "controllers", "network", "firmware", "data quality", "services", or "all" (default)

## Data Sources

### InfluxDB Buckets & Tag Names

> **CRITICAL**: `mcp__morpheus__query_metrics` `site_id` parameter ONLY works for `cpa_logs_30_days` bucket. For `iot-cloud-metrics` and `iot-metrics`, you MUST use `raw_flux` with `r["siteid"]` filter (all lowercase, no underscore).

| Bucket | Site tag | Use for |
|--------|----------|---------|
| `iot-cloud-metrics` | `siteid` | Controller connectivity, data quality, service uptime |
| `iot-metrics` | `siteid` | JouleBox health, containers, network, resources |

### Loki (Edge Logs)

**Instance**: `loki-2.smartjoules.org` — use `url: https://loki-2.smartjoules.org` for ALL Loki queries.
**Labels**: `iot_siteid`, `iot_controllerid`, `iot_service_name`, `iot_job`

Active services on Loki:
| Service | What it logs |
|---------|-------------|
| `firmware` | Modbus communication, device errors (NoResponseError, Read failed, STM_ERROR), data upload |
| `application` | Data processing, command routing, mode mismatches, recipe execution |
| `hostservice` | Container management, watchdog actions, service lifecycle |
| `joule-recipe` | Recipe evaluation, thermostat command processing |
| `systemd` | Service start/stop/fail/restart events |
| `aws-iot-device-client` | AWS IoT MQTT connection, auth, disconnects |
| `chillerplantautomation` | CPA-specific logs |

**Note**: `gateway`, `metrics-upload`, `edgebolt`, `nas-interface`, `telegraf`, `containerd`, `dockerd` may NOT be present on all sites. Check availability before relying on them.

---

## Health Check Layers

Run ALL layers in parallel where possible. Each layer produces: HEALTHY / DEGRADED / DOWN / UNKNOWN.

### Layer 1: Controller Fleet Status

**What**: Which controllers are online, offline, or flapping?

**InfluxDB Query** (primary):
```
raw_flux: from(bucket: "iot-cloud-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "controllerconnectivity_1")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> filter(fn: (r) => r["_field"] == "status")
  |> last()
  |> yield(name: "result")
```

Returns per controller: `status` (1=online, 0=offline), `controllerid`, `controllertype`, `awsiotregistered`.

**Also get disconnect reasons**:
```
raw_flux: from(bucket: "iot-cloud-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "controllerconnectivity_1")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> filter(fn: (r) => r["_field"] == "disconnectreason")
  |> last()
  |> yield(name: "disconnect_reasons")
```

Disconnect reason values:
- `UNKNOWN` — generic, usually benign
- `REQUEST_FAILED` — AWS IoT API call failed
- `MQTT_KEEP_ALIVE_TIMEOUT` — MQTT connection dropped
- `AUTH_ERROR` — authentication failure (certificate issue)
- `CLIENT_INITIATED_DISCONNECT` — intentional disconnect

**Service uptime (KEY — catches controllers alive but services dead)**:
```
raw_flux: from(bucket: "iot-cloud-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "controllerservicesuptime_1")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> filter(fn: (r) => r["_field"] == "uptimestatus")
  |> filter(fn: (r) => r["_value"] == 0)
  |> last()
  |> yield(name: "down_services")
```

`uptimestatus=0` persistently → controller's services are down even if the box is physically on.

**Classification**:
- Count total controllers, online (status=1), offline (status=0)
- Separate by type: `joulebox_v2`, `jouleleaf_v1`, `joulelogger_v4`
- Flag `awsiotregistered=0` controllers — they're not registered with AWS IoT, may be legacy
- Cross-reference: controller connectivity=1 but uptimestatus=0 → services crashed but box is alive

**Severity**:
- HEALTHY: >95% controllers online
- DEGRADED: 85-95% online, or any flapping
- DOWN: <85% online, or JouleBox offline

---

### Layer 2: JouleBox Health

**What**: Is the site's JouleBox (brain) healthy?

**Quick health check** (recommended FIRST query):
```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -10m)
  |> filter(fn: (r) => r["_measurement"] == "jouleboxhealthandstate")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> last()
  |> yield(name: "result")
```

Fields:
| Field | Type | Meaning |
|-------|------|---------|
| `healthscore` | float 0-100 | Overall health percentage |
| `networkhealth` | int 0/1 | Network connectivity |
| `overallhealth` | int 0/1 | Overall health flag |
| `postresqlhealth` | int 0/1 | PostgreSQL database (note: typo "postresql" is intentional in InfluxDB) |
| `ssdhealth` | int 0/1 | SSD storage health |
| `state` | int | 1=master, 2=CPA/slave |

Tags: `controllerid`, `controllertype` (joulebox_v2), `siteid`

**Multi-JouleBox sites**: Some sites have 2 JouleBoxes (master + CPA slave). Check BOTH. If master is down, slave may take over but CPA won't run.

**Gateway consensus**:
```
raw_flux: from(bucket: "iot-cloud-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "gatewayconnectivity_1")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> filter(fn: (r) => r["_field"] == "status")
  |> last()
  |> yield(name: "gateway")
```

Gateway status=1 means single master identified (healthy). Status=0 means no master or multiple masters (split brain).

**Severity**:
- HEALTHY: healthscore=100, all fields=1
- DEGRADED: healthscore<100 OR any field=0
- DOWN: no data in last 10 minutes

---

### Layer 3: Network Health

**What**: Is the network connecting controllers to cloud and NAS?

**NAS connectivity**:
```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "basicnetworkhealth")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> filter(fn: (r) => r["_field"] == "nasconnectionstatus")
  |> last()
  |> yield(name: "nas_health")
```

`nasconnectionstatus`: 1.0=connected, 0.0=disconnected. Per controller.

**Ping latency**:
```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "pingstats")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> last()
  |> yield(name: "ping")
```

Fields: `internetlatency` (ms to internet), `gatewaylatency` (ms to local gateway).

**AWS IoT connection (Loki)**:
```
url: https://loki-2.smartjoules.org
{iot_siteid="{site}", iot_service_name="aws-iot-device-client"} |~ "(?i)(error|disconnect|refused|timeout|auth)"
```

Look for:
- `Connection refused` → network/firewall issue
- `Auth error` → certificate expired or revoked
- `MQTT_KEEP_ALIVE_TIMEOUT` → intermittent network drops
- `Reconnecting` patterns → flapping connection

**Severity**:
- HEALTHY: NAS=1 for all, latency <100ms, no AWS IoT errors
- DEGRADED: Some NAS disconnects, latency 100-500ms, intermittent AWS errors
- DOWN: NAS=0 for JouleBox, latency >500ms or timeout, sustained AWS disconnects

---

### Layer 4: Container & Service Health

**What**: Are edge services running? Any crash loops?

**Container pings**:
```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -10m)
  |> filter(fn: (r) => r["_measurement"] == "containersping")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> filter(fn: (r) => r["_field"] == "response")
  |> last()
  |> yield(name: "container_health")
```

`response`: 1=alive, 0=dead. Per container per controller.

**Container restarts (last 6h)**:
```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -6h)
  |> filter(fn: (r) => r["_measurement"] == "containersrestart")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> yield(name: "restarts")
```

Fields: `status` (string "success"). Tags: `container`, `controllerid`.

**Controller reboots**:
```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -24h)
  |> filter(fn: (r) => r["_measurement"] == "controllerrestart")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> yield(name: "reboots")
```

Fields: `restarttime` (string, timestamp of last reboot).

**Loki — hostservice (watchdog actions)**:
```
url: https://loki-2.smartjoules.org
{iot_siteid="{site}", iot_service_name="hostservice"} |~ "(?i)(restart|kill|unhealthy|crash|oom|memory)"
```

**Loki — systemd (service lifecycle)**:
```
url: https://loki-2.smartjoules.org
{iot_siteid="{site}", iot_service_name="systemd"} |~ "(?i)(Started|Stopped|Failed|restart|Scheduled restart)"
```

Key patterns:
- `Scheduled restart job, restart counter is at {N}` → crash loop. N>100 = chronic.
- `Failed to start` → service won't start
- `Main process exited, code=killed` → OOM kill or signal

**Severity**:
- HEALTHY: All containers response=1, <3 restarts in 6h, no crash loops
- DEGRADED: Some containers dead, 3-10 restarts, crash loop on non-critical service
- DOWN: JouleBox containers dead, >10 restarts, crash loop on critical service (application, firmware)

---

### Layer 5: Firmware & Device Health

**What**: Are devices communicating? Which are dead?

**Loki — firmware errors (PRIMARY diagnostic for device issues)**:

**Dead devices (NoResponseError)**:
```
url: https://loki-2.smartjoules.org
{iot_siteid="{site}", iot_service_name="firmware"} |~ "NoResponseError"
```

When ALL params for a device show NoResponseError → device is completely unresponsive:
- Dead VFD
- Broken Modbus cable
- Device powered off
- Wrong Modbus address

Parse: extract `device_id` from `DATA ERROR LOG : {device_id}` and `controllerid` from labels.

**Modbus communication failures**:
```
url: https://loki-2.smartjoules.org
{iot_siteid="{site}", iot_service_name="firmware"} |~ "Read failed|Write failed|ModbusError|ConnectionException"
```

- `Read failed, retrying in {N} seconds` → transient Modbus error, firmware retries
- `ConnectionException` → complete Modbus bus failure
- Frequency matters: occasional = normal, continuous = cable/device issue

**STM errors (hardware/firmware)**:
```
url: https://loki-2.smartjoules.org
{iot_siteid="{site}", iot_service_name="firmware"} |~ "STM_ERROR"
```

`STM_ERROR` = sensor/actuator hardware failure. The device physically can't read/write.

**Data expression errors**:
```
url: https://loki-2.smartjoules.org
{iot_siteid="{site}", iot_service_name="firmware"} |~ "DataExpression|EvalError|SyntaxError"
```

Computed parameters failing — usually because source params are null (cascading from device errors).

**Analysis approach**:
1. Count unique devices with NoResponseError per controller → dead device map
2. Count Read failed frequency per controller → communication quality
3. Identify STM_ERROR devices → hardware failures
4. Cross-reference with Layer 1 down controllers

**Severity**:
- HEALTHY: No NoResponseErrors, <5 Read failures/hour
- DEGRADED: 1-5 dead devices, intermittent Read failures
- DOWN: >5 dead devices, sustained Read failures on critical controller

---

### Layer 6: Data Quality & Pipeline

**What**: Is sensor data actually reaching the cloud? What's missing?

**Component data quality**:
```
raw_flux: from(bucket: "iot-cloud-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "componentdataqualityabsolute_1")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> filter(fn: (r) => r["_field"] == "ActualNonNull" or r["_field"] == "Expected" or r["_field"] == "NullDeviceParams" or r["_field"] == "DataExpressionEvalError" or r["_field"] == "AbsentDeviceParams" or r["_field"] == "SiteIsDown")
  |> last()
  |> pivot(rowKey: ["_time", "componentid"], columnKey: ["_field"], valueColumn: "_value")
  |> filter(fn: (r) => r["Expected"] > 0)
  |> map(fn: (r) => ({r with quality: float(v: r["ActualNonNull"]) / float(v: r["Expected"]) * 100.0}))
  |> filter(fn: (r) => r["quality"] < 95.0)
  |> yield(name: "degraded_components")
```

Quality formula: `ActualNonNull / Expected * 100`

Fields explained:
| Field | Meaning |
|-------|---------|
| `Expected` | Expected data points in 15-min window |
| `ActualNonNull` | Actually received non-null data points |
| `NullDeviceParams` | Device returned null (device online but param not available) |
| `DataExpressionEvalError` | Computed param failed (source data missing) |
| `DataExpressionSyntaxError` | Config error in data expression |
| `DataExpressionBadOperandError` | Bad operand in expression |
| `AbsentDeviceParams` | Device completely absent (not mapped or offline) |
| `ContextNotFound` | Component config issue |
| `OutOfBoundsError` | Value outside expected range |
| `MaintenanceMode` | Param in maintenance mode (intentional) |
| `SiteIsDown` | Site marked as down |

**Classify components**:
- **DEAD (0%)**: ActualNonNull=0, high EvalErrors → device completely offline
- **CRITICAL (<50%)**: Most data missing, high null/absent → intermittent connection
- **DEGRADED (50-80%)**: Partial data loss → some params failing
- **MARGINAL (80-95%)**: Minor gaps → occasional nulls or eval errors
- **HEALTHY (>95%)**: Normal operation

**Null device contribution**:
```
raw_flux: from(bucket: "iot-cloud-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "nulldevicecontribution_1")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> last()
  |> yield(name: "null_devices")
```

**Absent device contribution**:
```
raw_flux: from(bucket: "iot-cloud-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "absentdevicecontribution_1")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> last()
  |> yield(name: "absent_devices")
```

**Device-level quality**:
```
raw_flux: from(bucket: "iot-cloud-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "devicedataquality_1")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> last()
  |> yield(name: "device_quality")
```

**Severity**:
- HEALTHY: >95% components above 95% quality
- DEGRADED: 5-20% components below 95%
- CRITICAL: >20% components below 95% OR any component at 0%

---

### Layer 7: Application & Command Layer

**What**: Is the application processing data and routing commands correctly?

**Loki — application errors**:
```
url: https://loki-2.smartjoules.org
{iot_siteid="{site}", iot_service_name="application"} |~ "(?i)(error|failed|exception|timeout)"
```

**Loki — mode mismatches** (commands rejected):
```
url: https://loki-2.smartjoules.org
{iot_siteid="{site}", iot_service_name="application"} |~ "does not match mode|ASSET_NOT_IN_RECIPE_MODE"
```

Pattern: `Command source {X} does not match mode {Y}` with status_code=8:
- `source=joulerecipe, mode=jouletrack` → controller in JouleTrack mode, recipe commands rejected
- `source=thermostat, mode=joulerecipe` → thermostat commands rejected in recipe mode
- Fix: change controller mode in JouleTrack UI

**Loki — recipe evaluation**:
```
url: https://loki-2.smartjoules.org
{iot_siteid="{site}", iot_service_name="joule-recipe"} |~ "(?i)(error|failed|invalid|timeout)"
```

**Loki — data bridge issues (important for data freshness)**:
```
url: https://loki-2.smartjoules.org
{iot_siteid="{site}", iot_service_name="application"} |~ "(?i)(Cache MISS|No data found|BridgeService|DataServiceBridge)"
```

Pattern: `Cache MISS for get_data_with_timestamp: {controller}.{controllertype} (available keys: [])` → data cache empty for that controller. Data not flowing from firmware to application.

**InfluxDB — command status**:
```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "commandstatus")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> last()
  |> yield(name: "commands")
```

**Severity**:
- HEALTHY: No application errors, no mode mismatches, data bridge healthy
- DEGRADED: Intermittent errors, some mode mismatches
- DOWN: Sustained errors, widespread cache misses

---

### Layer 8: Resource Usage

**What**: Are controllers running out of CPU/RAM/disk?

**CPU & RAM**:
```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "resourceusage")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> filter(fn: (r) => r["_field"] == "cpu" or r["_field"] == "ram")
  |> last()
  |> yield(name: "resources")
```

**Disk usage**:
```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "diskusage")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> last()
  |> yield(name: "disk")
```

**SSD health**:
```
raw_flux: from(bucket: "iot-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "ssdstatus")
  |> filter(fn: (r) => r["siteid"] == "{site}")
  |> last()
  |> yield(name: "ssd")
```

**Severity**:
- HEALTHY: CPU<80%, RAM<85%, disk<80%, SSD healthy
- DEGRADED: CPU 80-95%, RAM 85-95%, disk 80-90%
- CRITICAL: CPU>95% (throttling), RAM>95% (OOM risk), disk>90% (data loss risk)

---

## Cross-Correlation Analysis

After collecting all layers, CORRELATE findings:

1. **Down controller → dead components**: Map controllerid from Layer 1 (down) to componentid in Layer 6 (0% quality). This confirms data loss is because the controller is offline, not a data pipeline bug.

2. **Firmware errors → data quality**: Devices with NoResponseError in Layer 5 should show as NullDeviceParams in Layer 6. If NoResponseError exists but data quality is OK → device has multiple params, only some are failing.

3. **NAS down → no data upload**: If NAS is disconnected for a controller (Layer 3), that controller's data won't reach PostgreSQL → CPA gets stale data.

4. **Service restarts → data gaps**: Container restarts (Layer 4) cause brief data gaps. Map restart timestamps to data quality drops.

5. **Resource exhaustion → service crashes**: High CPU/RAM (Layer 8) correlating with container restarts (Layer 4) → OOM kills or CPU throttling causing timeouts.

---

## Output Format

```
# IoT Health Report: {Site Name} ({site_id})
**Time**: {timestamp} | **Window**: last {time_range}

## Overall: {HEALTHY / DEGRADED / CRITICAL / DOWN}

| Layer | Status | Summary |
|-------|--------|---------|
| 1. Controller Fleet | {status} | {X}/{total} online, {Y} offline, {Z} flapping |
| 2. JouleBox | {status} | healthscore={X}%, state={master/slave} |
| 3. Network | {status} | NAS={ok/issues}, latency={X}ms |
| 4. Services | {status} | {X} restarts, {Y} crash loops |
| 5. Firmware/Devices | {status} | {X} dead devices, {Y} read failures |
| 6. Data Quality | {status} | {X} components <95%, {Y} at 0% |
| 7. Application | {status} | {X} errors, {Y} mode mismatches |
| 8. Resources | {status} | CPU={X}%, RAM={Y}%, disk={Z}% |

## Controller Breakdown

| Controller | Type | Connectivity | Services | Disconnect Reason | Issues |
|-----------|------|-------------|----------|-------------------|--------|
| {id} | {type} | {online/offline} | {up/down} | {reason} | {notes} |

## Dead/Failing Devices

| Device ID | Controller | Error Type | All Params? | Component |
|-----------|-----------|------------|-------------|-----------|
| {id} | {controller} | NoResponseError/STM_ERROR | Yes/Partial | {component_id} |

## Degraded Components (quality <95%)

| Component | Quality | Expected | Actual | EvalErrors | NullDevice | Likely Cause |
|-----------|---------|----------|--------|------------|------------|-------------|
| {id} | {pct}% | {n} | {n} | {n} | {n} | {controller down / device dead / expression error} |

## Cross-Correlation

{Map down controllers → dead devices → 0% components. Identify the ROOT chain.}

## Recommendations
1. {Prioritized action items with specific controller/device IDs}
```

---

## Quick Mode (3 min)

If depth=quick, only check:
- Layer 1 (controller fleet status)
- Layer 2 (JouleBox health)
- Layer 6 (data quality — degraded components only)

Skip Layers 3, 4, 5, 7, 8 and Loki queries.

---

## Common Patterns

### "Site shows inactive on JouleTrack"
1. Check Layer 1 → controllerconnectivity. If status=1, controller IS online
2. Check Loki `systemd` for `aws-jobs` crash loop → `Scheduled restart job, restart counter is at {N}`
3. `aws-jobs` crash loop causes JouleTrack to show "inactive" but does NOT affect data or CPA
4. Fix: SSH into controller, restart aws-jobs service

### "Data not reaching CPA / stale data"
1. Check Layer 1 → which controllers are down?
2. Check Layer 3 → NAS connected? If NAS=0, data can't reach PostgreSQL
3. Check Layer 5 → firmware NoResponseErrors on specific devices
4. Check Layer 7 → application data bridge cache misses
5. Trace: firmware reads device → MQTT local → application → PostgreSQL → CPA reads

### "Widespread data quality drop"
1. Check Layer 1 → mass controller offline (network outage?)
2. Check Layer 3 → NAS/internet connectivity
3. Check Layer 8 → disk full? RAM exhausted?
4. Check Layer 4 → JouleBox services crashed?

### "Single device not reporting"
1. Check Layer 5 → NoResponseError for that device
2. If NoResponseError → Modbus communication failure (cable, address, power)
3. If STM_ERROR → hardware failure
4. If no errors but null data → device mapped but not connected

### "Controller flapping (intermittent online/offline)"
1. Check Layer 3 → ping latency fluctuating?
2. Check Loki `aws-iot-device-client` → reconnection patterns
3. Check Layer 8 → CPU/RAM spikes causing timeouts?
4. If disconnect reason = `MQTT_KEEP_ALIVE_TIMEOUT` → network instability

---

## Important Notes

- **`awsiotregistered=0`** controllers won't have AWS IoT connectivity data. They may still be online locally (check `statusfromcontrollermetric`).
- **Controller connectivity has 3 sub-fields**: `status` (combined), `statusfromawsiot` (AWS IoT), `statusfromcontrollermetric` (CPU metrics). A controller can be online via metrics but offline on AWS IoT.
- **NAS connectivity is critical for data flow**. If NAS is down, firmware writes to local buffer but data doesn't reach PostgreSQL/InfluxDB.
- **Container restart ≠ controller reboot**. Container restart = individual service restart. Controller reboot = full hardware reboot (check `controllerrestart.restarttime`).
- **DataExpressionEvalError cascades**: When a source param is null (device dead), ALL computed params that depend on it will show EvalError. Fix the source device, not the expressions.
- **Site has multiple controller types**: JouleBox (joulebox_v2) runs CPA. JouleLeaf (jouleleaf_v1) connects to lowside BMS. JouleLogger (joulelogger_v4) does energy metering. Different types have different failure modes.
- **Loki time format**: Use RFC3339 for `start`/`end` parameters (e.g., `2026-03-30T14:00:00Z`). Relative formats like `6h` don't work.
