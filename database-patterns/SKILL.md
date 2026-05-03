# Database Design Patterns

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** Database patterns and conventions for DeJoule backend development
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL database design** in DeJoule products:
- Designing database schemas
- Writing queries and migrations
- Choosing between SQL and NoSQL
- Optimizing database performance
- Data modeling for time-series IoT data

---

## 🗄️ Database Selection Guide

### When to Use What

```
Is your data structured and relational?
├── Yes → Use SQL (PostgreSQL, MySQL)
└── No → Is it time-series IoT data?
    ├── Yes → Use InfluxDB (time-series)
    └── No → Is it document-based?
        ├── Yes → Use MongoDB (document store)
        └── No → Use Redis (cache/key-value)
```

### Database Types at DeJoule

| Database | Use Case | Examples |
|----------|----------|----------|
| **PostgreSQL** | Relational data, users, sites | User accounts, site metadata |
| **InfluxDB** | Time-series IoT data | Energy readings, temperature |
| **MongoDB** | Document data, flexible schemas | Device configurations |
| **Redis** | Caching, pub/sub, sessions | API cache, session store |

---

## 📊 PostgreSQL Patterns

### Table Design Pattern

```sql
-- Sites table (master data)
CREATE TABLE sites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(name)
);

-- Devices table (hierarchical data)
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'chiller', 'pump', etc.
    metadata JSONB, -- Flexible metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(site_id, name)
);

-- Energy readings table (time-series data)
CREATE TABLE energy_readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    value_kwh NUMERIC(10, 2) NOT NULL,
    value_kw NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(device_id, timestamp)
);

-- Indexes for performance
CREATE INDEX idx_devices_site_id ON devices(site_id);
CREATE INDEX idx_energy_readings_device_id ON energy_readings(device_id);
CREATE INDEX idx_energy_readings_timestamp ON energy_readings(timestamp DESC);
CREATE INDEX idx_energy_readings_device_timestamp
    ON energy_readings(device_id, timestamp DESC);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_sites_updated_at
    BEFORE UPDATE ON sites
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_devices_updated_at
    BEFORE UPDATE ON devices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

### Query Patterns

```sql
-- Time-series aggregation (daily energy consumption)
SELECT
    device_id,
    date_trunc('day', timestamp) AS day,
    SUM(value_kwh) AS total_kwh,
    AVG(value_kw) AS avg_kw,
    MAX(value_kw) AS peak_kw
FROM energy_readings
WHERE device_id = 'device-uuid'
    AND timestamp BETWEEN '2026-01-01' AND '2026-01-31'
GROUP BY device_id, date_trunc('day', timestamp)
ORDER BY day;

-- Hierarchical query (site → devices → readings)
WITH site_devices AS (
    SELECT
        d.id,
        d.name,
        d.type
    FROM devices d
    WHERE d.site_id = 'site-uuid'
)
SELECT
    sd.name AS device_name,
    sd.type,
    COUNT(r.id) AS reading_count,
    SUM(r.value_kwh) AS total_kwh
FROM site_devices sd
LEFT JOIN energy_readings r ON r.device_id = sd.id
    AND r.timestamp >= NOW() - INTERVAL '1 day'
GROUP BY sd.id, sd.name, sd.type
ORDER BY total_kwh DESC;

-- Latest reading per device (window function)
SELECT DISTINCT ON (device_id)
    device_id,
    timestamp,
    value_kw,
    value_kwh
FROM energy_readings
WHERE device_id IN ('device-1', 'device-2', 'device-3')
ORDER BY device_id, timestamp DESC;
```

### Migration Pattern

```sql
-- Migration: 001_create_sites_table.up.sql
BEGIN;

CREATE TABLE sites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMIT;

-- Migration: 001_create_sites_table.down.sql
BEGIN;

DROP TABLE IF EXISTS sites CASCADE;

COMMIT;
```

---

## ⏱️ InfluxDB Patterns

### Bucket Organization

```bash
# Bucket naming convention
<org>_<environment>_<data_type>

# Examples:
- dejoule_production_energy_readings
- dejoule_staging_temperature_readings
- dejoule_development_device_metrics
```

### Data Model (Line Protocol)

```
# Measurement
energy_consumption

# Tags (indexed)
site=iah-del
device=chiller-1
type=chiller

# Fields (not indexed)
value_kwh=125.5
value_kw=45.2
efficiency=0.65

# Timestamp
1635724800000000000

# Full line protocol example
energy_consumption,site=iah-del,device=chiller-1,type=chiller value_kwh=125.5,value_kw=45.2,efficiency=0.65 1635724800000000000
```

### Flux Query Patterns

```flux
// Basic query: Last 24 hours of data
from(bucket: "dejoule_production_energy_readings")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r.site == "iah-del")
  |> filter(fn: (r) => r._field == "value_kwh")
  |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
  |> yield(name: "hourly_energy")

// Aggregation: Daily totals by device
from(bucket: "dejoule_production_energy_readings")
  |> range(start: -30d)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r._field == "value_kwh")
  |> group(columns: ["device"])
  |> aggregateWindow(every: 1d, fn: sum, createEmpty: false)
  |> map(fn: (r) => ({
      r with
      _time: date.truncate(t: 1d, time: r._time)
    }))
  |> yield(name: "daily_totals")

// Pivot: Wide format for charts
from(bucket: "dejoule_production_energy_readings")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r.site == "iah-del")
  |> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
  |> yield(name: "wide_format")

// Join: Compare multiple devices
data_chiller1 = from(bucket: "dejoule_production_energy_readings")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r.device == "chiller-1")
  |> filter(fn: (r) => r._field == "value_kwh")

data_chiller2 = from(bucket: "dejoule_production_energy_readings")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r.device == "chiller-2")
  |> filter(fn: (r) => r._field == "value_kwh")

join(tables: {chiller1: data_chiller1, chiller2: data_chiller2}, on: ["_time"])
  |> yield(name: "comparison")
```

### Downsampling and Retention

```flux
// Task: Downsample raw data to hourly
option task = {
  name: "downsample_energy_hourly",
  every: 1h,
  offset: 10m,
}

from(bucket: "dejoule_production_energy_readings")
  |> range(start: -2h)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r._field == "value_kwh")
  |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
  |> to(bucket: "dejoule_production_energy_hourly", org: "dejoule")

// Task: Downsample to daily for long-term storage
option task = {
  name: "downsample_energy_daily",
  every: 1d,
  offset: 10m,
}

from(bucket: "dejoule_production_energy_hourly")
  |> range(start: -2d)
  |> filter(fn: (r) => r._measurement == "energy_consumption")
  |> filter(fn: (r) => r._field == "value_kwh")
  |> aggregateWindow(every: 1d, fn: sum, createEmpty: false)
  |> to(bucket: "dejoule_production_energy_daily", org: "dejoule")
```

---

## 📄 MongoDB Patterns

### Document Design Pattern

```javascript
// Sites collection
{
  "_id": ObjectId("site-uuid"),
  "name": "IAH-Del",
  "location": {
    "type": "Point",
    "coordinates": [-95.3698, 29.7604]
  },
  "address": {
    "street": "123 Main St",
    "city": "Houston",
    "state": "TX",
    "zip": "77001"
  },
  "metadata": {
    "capacity": 500,
    "buildingType": "Office",
    "timezone": "America/Chicago"
  },
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "updatedAt": ISODate("2026-01-01T00:00:00Z")
}

// Devices collection (with nested telemetry config)
{
  "_id": ObjectId("device-uuid"),
  "siteId": ObjectId("site-uuid"),
  "name": "Chiller-1",
  "type": "chiller",
  "telemetry": {
    "enabled": true,
    "intervalSeconds": 60,
    "metrics": [
      {"name": "energy_kwh", "unit": "kWh", "dataType": "float"},
      {"name": "power_kw", "unit": "kW", "dataType": "float"},
      {"name": "temperature", "unit": "°C", "dataType": "float"}
    ]
  },
  "status": {
    "state": "operational",
    "lastSeen": ISODate("2026-05-02T10:30:00Z")
  },
  "createdAt": ISODate("2026-01-01T00:00:00Z"),
  "updatedAt": ISODate("2026-05-02T10:30:00Z")
}
```

### Aggregation Patterns

```javascript
// Pipeline: Total energy by device type
db.devices.aggregate([
  {
    $lookup: {
      from: "energy_readings",
      localField: "_id",
      foreignField: "deviceId",
      as: "readings"
    }
  },
  {
    $unwind: "$readings"
  },
  {
    $group: {
      _id: "$type",
      totalEnergy: { $sum: "$readings.value_kwh" },
      avgPower: { $avg: "$readings.value_kw" },
      deviceCount: { $sum: 1 }
    }
  },
  {
    $sort: { totalEnergy: -1 }
  }
]);

// Pipeline: Time-series aggregation (daily totals)
db.energy_readings.aggregate([
  {
    $match: {
      timestamp: {
        $gte: ISODate("2026-01-01T00:00:00Z"),
        $lte: ISODate("2026-01-31T23:59:59Z")
      }
    }
  },
  {
    $group: {
      _id: {
        device: "$deviceId",
        date: {
          $dateToString: {
            format: "%Y-%m-%d",
            date: "$timestamp"
          }
        }
      },
      totalEnergy: { $sum: "$value_kwh" },
      avgPower: { $avg: "$value_kw" },
      maxPower: { $max: "$value_kw" },
      readingCount: { $sum: 1 }
    }
  },
  {
    $sort: { "_id.date": 1 }
  }
]);
```

---

## 🔴 Redis Patterns

### Caching Pattern

```go
// Cache key format
site:<site_id>:devices          → Set of device IDs
device:<device_id>:data         → Hash of device data
device:<device_id>:readings:1h  → List of recent readings
energy:daily:<site_id>:<date>   → String (JSON) of daily totals

// Example: Cache site devices
SETEX site:iah-del:devices 3600 '["device-1", "device-2", "device-3"]'

// Example: Cache device data
HSET device:chiller-1:data \
  name "Chiller-1" \
  type "chiller" \
  siteId "iah-del" \
  status "operational"

EXPIRE device:chiller-1:data 300

// Example: Cache recent readings (stream)
XADD energy_readings * \
  site iah-del \
  device chiller-1 \
  value_kwh 125.5 \
  value_kw 45.2 \
  timestamp 1635724800
```

---

## 🚨 Mandatory Rules

### Schema Design Rules
- ✅ **ALWAYS** normalize data in SQL (3NF typically)
- ✅ **ALWAYS** use appropriate indexes for query patterns
- ✅ **ALWAYS** use transactions for multi-step operations
- ✅ **NEVER** store time-series in SQL (use InfluxDB)
- ✅ **NEVER** store structured relational data in MongoDB

### Query Rules
- ✅ **ALWAYS** use parameterized queries
- ✅ **ALWAYS** limit result sets (pagination)
- ✅ **ALWAYS** filter by indexed columns
- ✅ **NEVER** use SELECT * in production
- ✅ **NEVER** query without a time range on time-series data

### Performance Rules
- ✅ **ALWAYS** benchmark queries with EXPLAIN
- ✅ **ALWAYS** use connection pooling
- ✅ **ALWAYS** monitor slow queries
- ✅ **NEVER** query unindexed columns
- ✅ **NEVER** fetch more data than needed

---

## 📝 Naming Conventions

### Tables/Collections
- `snake_case` for table names: `energy_readings`
- `snake_case` for column names: `device_id`
- Plural for tables: `sites`, `devices`

### Indexes
- `idx_<table>_<column>`: `idx_devices_site_id`
- `idx_<table>_<column1>_<column2>`: `idx_energy_readings_device_timestamp`

---

## 🔍 Troubleshooting

### Common Issues

**Issue: Slow queries**
- **Solution:** Check indexes, use EXPLAIN, add missing indexes

**Issue: High memory usage**
- **Solution:** Limit result sets, use pagination, optimize joins

**Issue: Time-series performance degradation**
- **Solution:** Downsample old data, use retention policies

---

## ✅ Quality Checklist

Before marking database code complete:
- [ ] Schema normalized (SQL) or appropriate (NoSQL)
- [ ] Indexes created for query patterns
- [ ] Transactions used where needed
- [ ] Queries use parameterized values
- [ ] Time-series data in InfluxDB
- [ ] Migration scripts created
- [ ] Performance tested with realistic data

---

**Remember:** Choose the right database for the job - PostgreSQL for relational, InfluxDB for time-series, MongoDB for flexible schemas, Redis for cache!
