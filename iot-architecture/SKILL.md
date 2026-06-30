---
name: iot-architecture
description: IoT system architecture patterns for DeJoule products. Use when designing or reviewing IoT systems, including device connectivity, data ingestion pipelines, edge processing, and cloud integration.
---

# IoT System Architecture

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** IoT architecture patterns for DeJoule products
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL IoT system design** in DeJoule products:
- Designing IoT data pipelines
- Architecting device communication
- Building real-time analytics
- Planning scalability and reliability
- IoT security and monitoring

---

## 🏗️ DeJoule IoT Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        IoT Devices                            │
│  (Chillers, Pumps, Sensors, Gateways, Controllers)           │
└─────────────────────┬───────────────────────────────────────┘
                      │ MQTT / TCP
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Edge Gateways                             │
│  (Data aggregation, preprocessing, buffering, routing)      │
└─────────────────────┬───────────────────────────────────────┘
                      │ MQTT / HTTPS
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                   MQTT Broker                                │
│  (Message routing, pub/sub, QoS, retention)                  │
└──────┬──────────────────────────────────────────┬───────────┘
       │                                          │
       ▼                                          ▼
┌──────────────────┐                    ┌──────────────────┐
│  InfluxDB        │                    │   Kafka          │
│  (Time-series)   │                    │   (Streaming)    │
└─────────┬────────┘                    └────────┬─────────┘
          │                                      │
          ▼                                      ▼
┌──────────────────┐                    ┌──────────────────┐
│  Real-time       │                    │  Stream          │
│  Analytics       │                    │  Processing      │
└─────────┬────────┘                    └────────┬─────────┘
          │                                      │
          └──────────────┬───────────────────────┘
                         ▼
                ┌──────────────────┐
                │  PostgreSQL      │
                │  (Metadata,      │
                │   Sites, Users)  │
                └──────────────────┘
```

---

## 📡 Device Communication Patterns

### Pattern 1: Direct MQTT (Recommended)

```
Device → MQTT Broker → Subscribers (InfluxDB, Kafka, Services)
```

**Use when:**
- Devices have network connectivity
- Low latency required
- Simple point-to-point communication

**Pros:** Real-time, low latency, simple
**Cons:** Requires network reliability

### Pattern 2: Gateway Aggregation

```
Devices → Edge Gateway → MQTT Broker → Subscribers
```

**Use when:**
- Multiple devices per site
- Limited connectivity
- Data preprocessing needed

**Pros:** Reliable, efficient, can buffer
**Cons:** Additional gateway complexity

### Pattern 3: Cloud Bridge

```
Devices → Cloud Gateway → MQTT Broker → Subscribers
```

**Use when:**
- Devices behind firewall
- No direct internet access
- Centralized management

**Pros:** Secure, managed, scalable
**Cons:** Higher latency, cloud dependency

---

## 🔄 Data Pipeline Architecture

### Pipeline Stages

```
1. Ingestion (MQTT/Kafka)
   ↓
2. Validation (Schema check, data quality)
   ↓
3. Transformation (Unit conversion, normalization)
   ↓
4. Enrichment (Add site/device metadata)
   ↓
5. Storage (InfluxDB for time-series, PostgreSQL for metadata)
   ↓
6. Processing (Real-time analytics, alerts)
   ↓
7. Visualization (Dashboards, reports)
```

### Implementation Example

```typescript
// IoT Data Pipeline Service
import { TelemetryConsumer } from './telemetry-consumer';
import { DataValidator } from './data-validator';
import { DataTransformer } from './data-transformer';
import { MetadataEnricher } from './metadata-enricher';
import { InfluxDBWriter } from './influxdb-writer';
import { AlertProcessor } from './alert-processor';

export class IoTDataPipeline {
  constructor(
    private consumer: TelemetryConsumer,
    private validator: DataValidator,
    private transformer: DataTransformer,
    private enricher: MetadataEnricher,
    private writer: InfluxDBWriter,
    private alertProcessor: AlertProcessor
  ) {}

  async start(): Promise<void> {
    await this.consumer.start();

    this.consumer.on('message', async (message) => {
      try {
        // 1. Validate
        const validated = await this.validator.validate(message);

        // 2. Transform
        const transformed = await this.transformer.transform(validated);

        // 3. Enrich
        const enriched = await this.enricher.enrich(transformed);

        // 4. Write to InfluxDB
        await this.writer.write(enriched);

        // 5. Process alerts
        await this.alertProcessor.process(enriched);
      } catch (error) {
        logger.error('Pipeline error:', error);
      }
    });
  }
}
```

---

## 📊 Real-Time Analytics

### Stream Processing Architecture

```
Kafka Topic: iot.production.telemetry.devices
         ↓
Stream Processor: Hourly Aggregation
         ↓
Kafka Topic: analytics.production.energy.hourly
         ↓
Stream Processor: Daily Aggregation
         ↓
Kafka Topic: analytics.production.energy.daily
         ↓
Batch Processor: Reporting & Billing
```

### Analytics Patterns

**Pattern 1: Windowed Aggregation**
```typescript
// Aggregate data in time windows (1min, 5min, 1hour, 1day)
// Useful for: Energy totals, averages, peak detection
```

**Pattern 2: Threshold Alerting**
```typescript
// Check if values exceed thresholds
// Useful for: Temperature alerts, efficiency warnings
```

**Pattern 3: Anomaly Detection**
```typescript
// Detect unusual patterns using ML or statistical methods
// Useful for: Predictive maintenance, fault detection
```

**Pattern 4: Comparative Analytics**
```typescript
// Compare devices, sites, time periods
// Useful for: Benchmarking, performance analysis
```

---

## 🔐 Security Architecture

### Security Layers

```
1. Device Authentication
   - X.509 certificates
   - API keys
   - JWT tokens

2. Transport Security
   - TLS/SSL for MQTT
   - HTTPS for REST
   - VPN for private networks

3. Authorization
   - Role-based access control
   - Device-level permissions
   - Site-level isolation

4. Data Security
   - Encryption at rest
   - Encryption in transit
   - Secure key management

5. Audit & Monitoring
   - Access logs
   - Device activity logs
   - Security event monitoring
```

---

## 📈 Scalability Patterns

### Horizontal Scaling

```
MQTT Broker Cluster (Kubernetes)
  ├── Broker Pod 1
  ├── Broker Pod 2
  └── Broker Pod 3

Kafka Cluster
  ├── Broker 1
  ├── Broker 2
  └── Broker 3

InfluxDB Cluster
  ├── Data Node 1
  ├── Data Node 2
  └── Data Node 3
```

### Load Balancing

```yaml
# Kubernetes Service for MQTT
apiVersion: v1
kind: Service
metadata:
  name: mqtt-broker
spec:
  selector:
    app: mqtt-broker
  ports:
  - port: 1883
    targetPort: 1883
  type: LoadBalancer
```

---

## 🚨 Reliability Patterns

### Message Reliability

```
1. QoS Levels (MQTT)
   - QoS 0: Fire and forget
   - QoS 1: At least once
   - QoS 2: Exactly once

2. Acknowledgment
   - Publisher confirms
   - Subscriber acknowledges
   - Retry on failure

3. Persistence
   - Message queue buffering
   - Disk-based persistence
   - Replay capability

4. Dead Letter Queue
   - Failed message handling
   - Error analysis
   - Manual retry
```

### High Availability

```
1. Redundancy
   - Multiple broker instances
   - Database replication
   - Load balancing

2. Failover
   - Automatic failover
   - Health checks
   - Circuit breakers

3. Backup & Recovery
   - Regular backups
   - Disaster recovery plan
   - Data replication across regions
```

---

## 🧪 Testing Strategy

### Unit Testing
- Test individual components
- Mock external dependencies
- Validate data transformation

### Integration Testing
- Test end-to-end pipelines
- Test with real MQTT/Kafka
- Test database writes

### Load Testing
- Simulate high device count
- Test message throughput
- Test system limits

### Chaos Testing
- Test failure scenarios
- Test network partitions
- Test broker failures

---

## 🚨 Mandatory Rules

### Architecture Rules
- ✅ **ALWAYS** use message queues for IoT data
- ✅ **ALWAYS** separate ingestion from processing
- ✅ **ALWAYS** implement buffering and retries
- ✅ **NEVER** block pipeline on failures
- ✅ **NEVER** lose critical data

### Security Rules
- ✅ **ALWAYS** authenticate devices
- ✅ **ALWAYS** encrypt data in transit
- ✅ **ALWAYS** isolate site data
- ✅ **NEVER** store credentials in code
- ✅ **NEVER** expose databases publicly

### Reliability Rules
- ✅ **ALWAYS** use appropriate QoS levels
- ✅ **ALWAYS** implement dead letter queues
- ✅ **ALWAYS** monitor system health
- ✅ **NEVER** ignore failed messages
- ✅ **NEVER** skip error handling

---

## ✅ Quality Checklist

Before marking architecture complete:
- [ ] Security measures implemented
- [ ] Scalability planned
- [ ] Reliability ensured
- [ ] Monitoring configured
- [ ] Documentation complete
- [ ] Disaster recovery planned
- [ ] Code review completed

---

**Remember:** IoT systems must be reliable, secure, and scalable - design for failure and plan for growth!
