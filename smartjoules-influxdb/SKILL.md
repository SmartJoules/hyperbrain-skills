---
name: smartjoules-influxdb
description: How to query SmartJoules InfluxDB databases — TSDB (AWS Timestream, raw sensor data) and IoT InfluxDB (processed data). Covers auth, schema, Flux query patterns, and working Python examples.
---

# SmartJoules InfluxDB Query Guide

## Overview

There are two InfluxDB databases:

| | TSDB | IoT InfluxDB |
|---|---|---|
| **Purpose** | Raw sensor data (prod) | Processed/computed data |
| **Host** | AWS Timestream InfluxDB | iot-influxdb.smartjoules.org |
| **Auth** | Username + Password → session cookie | Token in Authorization header |
| **Protocol** | HTTPS (SSL verify off) | HTTPS |
| **Query Language** | Flux | Flux |
| **Credentials file** | `~/.claude/secrets/influxdb.json` → `tsdb` key | `~/.claude/secrets/influxdb.json` → `iot_influx` key |

---

## TSDB (AWS Timestream)

### Auth — Session Cookie (VERIFIED WORKING)

TSDB uses a two-step auth flow — do NOT use token auth or raw Basic auth on the query endpoint:

1. `POST /api/v2/signin` with `Authorization: Basic base64(username:password)` → get session cookie
2. `POST /api/v2/query` with that cookie attached

```python
import json, ssl, base64, urllib.request, urllib.parse, http.cookiejar

with open("/Users/satviksinghal/.claude/secrets/influxdb.json") as f:
    creds = json.load(f)["tsdb"]

base = f"https://{creds['host']}:{creds['port']}"

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE  # SSL verify disabled for this host

cookie_jar = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(
    urllib.request.HTTPSHandler(context=ctx),
    urllib.request.HTTPCookieProcessor(cookie_jar)
)

# Step 1: signin
signin_req = urllib.request.Request(f"{base}/api/v2/signin", data=b"", method="POST")
signin_req.add_header("Authorization", f"Basic {base64.b64encode(f\"{creds['username']}:{creds['password']}\".encode()).decode()}")
opener.open(signin_req, timeout=15)  # 204 = success

# Step 2: query (cookie is sent automatically by opener)
def run_flux(flux: str) -> str:
    org = creds["org"]
    url = f"{base}/api/v2/query?org={urllib.parse.quote(org)}"
    data = json.dumps({"query": flux, "type": "flux"}).encode()
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    req.add_header("Accept", "application/csv")
    resp = opener.open(req, timeout=60)
    return resp.read().decode("utf-8")
```

### Schema

**Bucket:** `device_component` (fixed — never changes)

#### Measurement: `components`
- **Purpose:** Equipment sensor readings (chillers, pumps, cooling towers)
- **Tags:** `siteId`, `componentId`
- **Fields by asset type:**

| Asset Type | Fields |
|---|---|
| `chiller` | `alarmstatus`, `chleff`, `chltwvpo`, `chlwaterflow`, `chwfs`, `chlwmval`, `chlwtdelta`, `condapproach`, `condewt`, `condlwt`, `condtdelta`, `condtwvpo`, `condwaterflow`, `condwmval`, `controltype`, `coolewt`, `coollwt`, `dispressure`, `evapproach`, `eff`, `hrs`, `kva`, `kvah`, `kw`, `mhchwintemp`, `mhchwouttemp`, `mhddtmp`, `mhdmdtr`, `nochr`, `oahum`, `oatmp`, `opernlstatus`, `scta`, `pertotcap`, `setpoint`, `ssta`, `status`, `sucpressure`, `tpcons`, `toteff`, `tptr`, `tr` |
| `condenserWaterPump` | `ikwtr`, `kva`, `kvah`, `kw`, `mode`, `nocondwpr`, `outputfrequency`, `status`, `waterflow` |
| `primaryChilledWaterPump` | `ikwtr`, `kva`, `kvah`, `kw`, `mode`, `outputfrequency`, `status`, `waterflow` |
| `secondaryChilledWaterPump` | `ikwtr`, `kva`, `kvah`, `kw`, `mode`, `outputfrequency`, `status`, `waterflow` |
| `coolingTower` | `approach`, `bldloss`, `bldreq`, `coc`, `driftloss`, `efficiency`, `inwatertemp`, `evaloss`, `makupquan`, `makupquanreq`, `outwatertemp`, `range`, `tds`, `wbt`, `wetbulb` |

#### Measurement: `device`
- **Purpose:** Energy meter readings
- **Tags:** `siteId`, `deviceId`
- **Fields:** `ebkwh`, `kw`

### Flux Query Pattern

```flux
from(bucket: "device_component")
  |> range(start: 2026-03-31T00:00:00Z, stop: 2026-04-07T00:00:00Z)
  |> filter(fn: (r) => r._measurement == "components")
  |> filter(fn: (r) => r.siteId == "amh-cal")
  |> filter(fn: (r) => r.componentId == "amh-cal_1")
  |> filter(fn: (r) => r._field == "kw" or r._field == "tr")
  |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
  |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")
```

**Rules:**
- Tags are `siteId` and `componentId` (camelCase) — not `site_id` or `component_id`
- Always filter `_measurement` explicitly
- Use RFC3339 UTC for absolute times: `2026-03-31T00:00:00Z`
- Use relative for convenience: `-7d`, `-24h`
- `aggregateWindow` + `pivot` is the standard pattern
- Use `createEmpty: false` to skip null windows

### Full Working Example

```python
import json, ssl, base64, urllib.request, urllib.parse, http.cookiejar
import csv, io

with open("/Users/satviksinghal/.claude/secrets/influxdb.json") as f:
    creds = json.load(f)["tsdb"]

base = f"https://{creds['host']}:{creds['port']}"
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

cookie_jar = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(
    urllib.request.HTTPSHandler(context=ctx),
    urllib.request.HTTPCookieProcessor(cookie_jar)
)

# Signin
signin_req = urllib.request.Request(f"{base}/api/v2/signin", data=b"", method="POST")
signin_req.add_header("Authorization", f"Basic {base64.b64encode(f\"{creds['username']}:{creds['password']}\".encode()).decode()}")
opener.open(signin_req, timeout=15)

# Query
flux = '''
from(bucket: "device_component")
  |> range(start: -7d)
  |> filter(fn: (r) => r._measurement == "components")
  |> filter(fn: (r) => r.siteId == "amh-cal")
  |> filter(fn: (r) => r.componentId == "amh-cal_1")
  |> filter(fn: (r) => r._field == "kw")
  |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
  |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")
'''

url = f"{base}/api/v2/query?org={urllib.parse.quote(creds['org'])}"
req = urllib.request.Request(url, data=json.dumps({"query": flux, "type": "flux"}).encode(), method="POST")
req.add_header("Content-Type", "application/json")
req.add_header("Accept", "application/csv")

resp = opener.open(req, timeout=60)
csv_data = resp.read().decode("utf-8")

# Parse CSV into list of dicts
reader = csv.DictReader(io.StringIO(csv_data))
rows = [row for row in reader if row.get("_time")]
print(f"Rows returned: {len(rows)}")
for row in rows[:5]:
    print(row.get("_time"), row.get("kw"))
```

### Large Date Range — Chunk by Week

```python
from datetime import datetime, timedelta, timezone

start = datetime(2026, 1, 1, tzinfo=timezone.utc)
end = datetime(2026, 4, 1, tzinfo=timezone.utc)

current = start
while current < end:
    chunk_end = min(current + timedelta(days=7), end)
    start_str = current.strftime("%Y-%m-%dT%H:%M:%SZ")
    end_str = chunk_end.strftime("%Y-%m-%dT%H:%M:%SZ")
    # build flux with |> range(start: {start_str}, stop: {end_str})
    current = chunk_end
```

---

## IoT InfluxDB

### Auth — Token

```python
import json, urllib.request, urllib.parse

with open("/Users/satviksinghal/.claude/secrets/influxdb.json") as f:
    creds = json.load(f)["iot_influx"]

base = f"https://{creds['host']}"

def run_flux_iot(flux: str, bucket_org: str = None) -> str:
    org = bucket_org or creds["org"]
    url = f"{base}/api/v2/query?org={urllib.parse.quote(org)}"
    data = json.dumps({"query": flux, "type": "flux"}).encode()
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Authorization", f"Token {creds['token']}")
    req.add_header("Content-Type", "application/json")
    req.add_header("Accept", "application/csv")
    resp = urllib.request.urlopen(req, timeout=60)
    return resp.read().decode("utf-8")
```

### Schema

- **Bucket:** Depends on use case — ask user or confirm before querying (never hardcode)
- **Measurement:** Depends on use case — ask user or confirm before querying
- **Query Language:** Flux (same patterns as TSDB)

### General Flux Pattern

```flux
from(bucket: "{bucket_name}")
  |> range(start: {start_time}, stop: {end_time})
  |> filter(fn: (r) => r._measurement == "{measurement}")
  |> filter(fn: (r) => r.{tag_key} == "{tag_value}")
  |> filter(fn: (r) => r._field == "{field}")
  |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
  |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")
```

---

## General Notes

- All timestamps stored in UTC; convert to IST (`Asia/Kolkata`, UTC+5:30) for display
- After pivot, drop meta columns: `result`, `table`, `_start`, `_stop`, `_measurement`
- No external libraries needed for TSDB queries — uses Python stdlib only (`urllib`, `ssl`, `http.cookiejar`)
- For IoT InfluxDB, no SSL context needed (cert is valid)
