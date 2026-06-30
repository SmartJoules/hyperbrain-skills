---
name: influxdb-patterns
description: InfluxDB time-series patterns and conventions for DeJoule IoT data storage. Use when writing Flux/InfluxQL queries, designing measurements and tags, or modeling time-series sensor data.
---

# InfluxDB Time-Series Patterns

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** InfluxDB patterns and conventions for DeJoule IoT data storage
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL InfluxDB development** in DeJoule products:
- Storing time-series IoT data
- Querying telemetry and sensor data
- Real-time analytics and aggregations
- Downsampling and data retention
- Time-series data visualization

---

## 🗄️ Bucket Organization

### Bucket Naming Convention

```
<org>_<environment>_<data_type>_<granularity>
```

### Bucket Examples

```
# Raw data (high frequency)
dejoule_production_iot_raw
dejoule_staging_iot_raw

# Aggregated data (hourly)
dejoule_production_iot_hourly

# Long-term storage (daily)
dejoule_production_iot_daily
```

---

## 📊 Data Model (Line Protocol)

### Measurement Naming

```
<domain>_<entity>_<metric_type>

Examples:
- energy_consumption
- temperature_readings
- pressure_readings
- device_status
```

### Tag Design (Indexed Fields)

```
# Site hierarchy
site = iah-del
building = main-floor
zone = hvac-zone-1

# Device metadata
device_id = chiller-1
device_type = chiller
manufacturer = carrier
model = 30XA

# Data source
source = mqtt
gateway = gw-iah-del-01
```

### Field Design (Non-Indexed Values)

```
# Energy metrics
energy_kwh = 125.5 (float)
power_kw = 45.2 (float)
demand_kw = 52.3 (float)

# Temperature metrics
temperature_c = 7.5 (float)
temperature_f = 45.5 (float)

# Status metrics
runtime_hours = 1234.5 (float)
cycle_count = 45 (integer)
is_running = true (boolean)
```

### Complete Line Protocol Examples

```
# Energy reading
energy_consumption,site=iah-del,device_id=chiller-1,device_type=chiller energy_kwh=125.5,power_kw=45.2,efficiency=0.65 1635724800000000000

# Temperature reading
temperature_readings,site=iah-del,device_id=chiller-1,device_type=chiller entering_water_temp_c=10.5,leaving_water_temp_c=7.5 1635724800000000000

# Device status
device_status,site=iah-del,device_id=chiller-1,device_type=chiller state="operational",runtime_hours=1234.5,alarm_count=0 1635724800000000000

# Alert event
device_alerts,site=iah-del,device_id=chiller-1,device_type=chiller severity="warning",code="HIGH_TEMP",message="Temperature exceeds threshold" 1635724800000000000
```

---

## 🔍 Query Patterns (Flux)

### Basic Time-Series Query

```flux
// Last 24 hours of energy readings for a device
from(bucket: "dejoule_production_iot_raw")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r.site == "iah-del")
  |> filter(fn: (r) => r.device_id == "chiller-1")
  |> filter(fn: (r) => r._field == "energy_kwh")
  |> yield(name: "last_24h")
```

### Aggregation Patterns

```flux
// Hourly energy totals by device
from(bucket: "dejoule_production_iot_raw")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r._field == "energy_kwh")
  |> aggregateWindow(every: 1h, fn: sum, createEmpty: false)
  |> yield(name: "hourly_totals")

// Daily energy totals by site
from(bucket: "dejoule_production_iot_raw")
  |> range(start: -30d)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r._field == "energy_kwh")
  |> group(columns: ["site"])
  |> aggregateWindow(every: 1d, fn: sum, createEmpty: false)
  |> map(fn: (r) => ({
      r with
      _time: date.truncate(t: 1d, time: r._time)
    }))
  |> yield(name: "daily_totals_by_site")

// Peak demand detection
from(bucket: "dejoule_production_iot_raw")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r._field == "power_kw")
  |> group(columns: ["device_id"])
  |> max(column: "_value")
  |> yield(name: "peak_demand")
```

### Pivot and Transform

```flux
// Pivot fields into columns (wide format)
from(bucket: "dejoule_production_iot_raw")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r.site == "iah-del")
  |> filter(fn: (r) => r.device_id == "chiller-1")
  |> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
  |> yield(name: "wide_format")

// Calculate derived metrics
from(bucket: "dejoule_production_iot_raw")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r.site == "iah-del")
  |> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
  |> map(fn: (r) => ({
      r with
      efficiency: r.energy_kwh / (r.power_kw * 1.0),
      cost_usd: r.energy_kwh * 0.12
    }))
  |> yield(name: "derived_metrics")
```

### Join and Compare

```flux
// Compare current vs previous period
current = from(bucket: "dejoule_production_iot_raw")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r._field == "energy_kwh")
  |> group(columns: ["device_id"])
  |> sum()

previous = from(bucket: "dejoule_production_iot_raw")
  |> range(start: -48h, stop: -24h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r._field == "energy_kwh")
  |> group(columns: ["device_id"])
  |> sum()

join(tables: {current: current, previous: previous}, on: ["device_id"])
  |> map(fn: (r) => ({
      device_id: r.device_id,
      current_kwh: r._value_current,
      previous_kwh: r._value_previous,
      change_percent: ((r._value_current - r._value_previous) / r._value_previous) * 100.0
    }))
  |> yield(name: "comparison")

// Compare multiple devices
chiller1 = from(bucket: "dejoule_production_iot_raw")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r.device_id == "chiller-1")
  |> filter(fn: (r) => r._field == "energy_kwh")

chiller2 = from(bucket: "dejoule_production_iot_raw")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r.device_id == "chiller-2")
  |> filter(fn: (r) => r._field == "energy_kwh")

join(tables: {chiller1: chiller1, chiller2: chiller2}, on: ["_time"])
  |> map(fn: (r) => ({
      _time: r._time,
      chiller1_kwh: r._value_chiller1,
      chiller2_kwh: r._value_chiller2,
      difference: r._value_chiller1 - r._value_chiller2
    }))
  |> yield(name: "device_comparison")
```

---

## 📉 Downsampling and Retention

### Task: Downsample to Hourly

```flux
option task = {
  name: "downsample_iot_hourly",
  every: 1h,
  offset: 10m,
}

from(bucket: "dejoule_production_iot_raw")
  |> range(start: -2h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> aggregateWindow(
    every: 1h,
    fn: (tables=<-, column="_value") =>
      tables
        |> sum(column: column)
        |> merge()
  )
  |> to(
    bucket: "dejoule_production_iot_hourly",
    org: "dejoule",
    timeColumn: "_time"
  )
```

### Task: Downsample to Daily

```flux
option task = {
  name: "downsample_iot_daily",
  every: 1d,
  offset: 10m,
}

from(bucket: "dejoule_production_iot_hourly")
  |> range(start: -2d)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> aggregateWindow(
    every: 1d,
    fn: (tables=<-, column="_value") =>
      tables
        |> sum(column: column)
        |> merge()
  )
  |> to(
    bucket: "dejoule_production_iot_daily",
    org: "dejoule",
    timeColumn: "_time"
  )
```

### Retention Policy

```bash
# Delete raw data older than 30 days
influx delete \
  --bucket dejoule_production_iot_raw \
  --org dejoule \
  --start 1970-01-01T00:00:00Z \
  --stop $(date -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ)

# Delete hourly data older than 1 year
influx delete \
  --bucket dejoule_production_iot_hourly \
  --org dejoule \
  --start 1970-01-01T00:00:00Z \
  --stop $(date -d '1 year ago' +%Y-%m-%dT%H:%M:%SZ)
```

---

## 🧪 Testing Patterns

### Unit Test Template

```javascript
import { InfluxDB } from '@influxdata/influxdb-client';
import { flux } from '@influxdata/influxdb-client';

describe('InfluxDB Queries', () => {
  let influxDB: InfluxDB;

  beforeAll(() => {
    influxDB = new InfluxDB({
      url: process.env.INFLUX_URL,
      token: process.env.INFLUX_TOKEN,
    });
  });

  describe('fetchEnergyReadings', () => {
    it('should fetch last 24 hours of energy data', async () => {
      const query = flux`
        from(bucket: "dejoule_production_iot_raw")
          |> range(start: -24h)
          |> filter(fn: (r) => r._measurement == "energy_consumption")
          |> filter(fn: (r) => r.site == "test-site")
          |> filter(fn: (r) => r._field == "energy_kwh")
      `;

      const result = await influxDB.queryRows(query);

      expect(result).toBeDefined();
      // Add assertions
    });
  });
});
```

---

## 🚨 Mandatory Rules

### Schema Design Rules
- ✅ **ALWAYS** use tags for indexed/filter fields
- ✅ **ALWAYS** use fields for values
- ✅ **ALWAYS** include timestamp in all data
- ✅ **NEVER** use high cardinality tags
- ✅ **NEVER** store non-time-series data

### Query Rules
- ✅ **ALWAYS** specify time range in queries
- ✅ **ALWAYS** filter by tags before fields
- ✅ **ALWAYS** use aggregateWindow for aggregations
- ✅ **NEVER** query without time bounds
- ✅ **NEVER** use unbounded range queries

### Performance Rules
- ✅ **ALWAYS** downsample old data
- ✅ **ALWAYS** use retention policies
- ✅ **ALWAYS** limit query results
- ✅ **NEVER** store raw data indefinitely
- ✅ **NEVER** query raw data for long-term trends

---

## 📝 Naming Conventions

- Buckets: `snake_case` with environment prefix
- Measurements: `snake_case` with domain prefix
- Tags: `snake_case`
- Fields: `snake_case` with unit suffix

---

## ✅ Quality Checklist

Before marking code complete:
- [ ] Tag/field separation correct
- [ ] Time ranges specified
- [ ] Queries optimized
- [ ] Downsampling configured
- [ ] Retention policies set
- [ ] Tests written (80%+ coverage)
- [ ] Code review completed

---

**Remember:** InfluxDB is for time-series - optimize tags for querying and fields for values!
