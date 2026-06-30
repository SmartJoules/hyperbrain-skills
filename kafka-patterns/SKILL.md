---
name: kafka-patterns
description: Kafka stream-processing patterns and conventions for DeJoule IoT data pipelines. Use when designing producers, consumers, topics, or stream-processing logic for IoT data flows.
---

# Kafka Stream Processing Patterns

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** Kafka patterns and conventions for DeJoule IoT data pipelines
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL Kafka development** in DeJoule products:
- Streaming IoT data processing
- Real-time analytics and aggregations
- Event-driven architectures
- Data pipeline integration
- Microservices communication

---

## 🏗️ Topic Architecture

### Topic Naming Convention

```
<domain>.<environment>.<data_type>.<entity>
```

### Topic Examples

```
# Raw IoT data
iot.production.telemetry.devices
iot.production.status.devices
iot.production.alerts.devices

# Processed data
analytics.production.energy.hourly
analytics.production.energy.daily
analytics.production.efficiency.sites

# Events
events.production.device.created
events.production.device.updated
events.production.device.deleted
```

---

## 📨 Message Patterns

### Telemetry Event Pattern

**Topic:** `iot.production.telemetry.devices`

**Key:** `iah-del.chiller-1`

**Value:**
```json
{
  "timestamp": "2026-05-02T10:30:00Z",
  "site_id": "iah-del",
  "device_id": "chiller-1",
  "device_type": "chiller",
  "readings": {
    "energy_kwh": 125.5,
    "power_kw": 45.2,
    "temperature_c": 7.5
  },
  "metadata": {
    "sequence": 12345,
    "firmware": "1.2.3"
  }
}
```

---

## 🔄 Producer Implementation (Node.js)

### Kafka Producer Pattern

```typescript
import { Kafka, Producer } from 'kafkajs';
import { logger } from '../utils/logger';

/**
 * @description Kafka producer for IoT telemetry
 */
export class TelemetryProducer {
  private producer: Producer;
  private isConnected: boolean = false;

  /**
   * @description Creates an instance of TelemetryProducer.
   * @param {string} brokers - Kafka broker URLs.
   * @param {string} topic - Topic name.
   */
  constructor(
    private kafka: Kafka,
    private topic: string
  ) {
    this.producer = this.kafka.producer();
    this.setupEventHandlers();
  }

  /**
   * @description Setup event handlers
   */
  private setupEventHandlers(): void {
    this.producer.on('producer.connect', () => {
      this.isConnected = true;
      logger.info('Kafka producer connected');
    });

    this.producer.on('producer.disconnect', () => {
      this.isConnected = false;
      logger.warn('Kafka producer disconnected');
    });

    this.producer.on('producer.network.request_timeout', (error) => {
      logger.error('Kafka producer timeout:', error);
    });
  }

  /**
   * @description Connect to Kafka
   */
  async connect(): Promise<void> {
    await this.producer.connect();
  }

  /**
   * @description Send telemetry message
   * @param {TelemetryMessage} message - Telemetry message
   */
  async sendTelemetry(message: TelemetryMessage): Promise<void> {
    if (!this.isConnected) {
      throw new Error('Kafka producer not connected');
    }

    try {
      // Create key for partitioning (site_id + device_id)
      const key = `${message.site_id}.${message.device_id}`;

      await this.producer.send({
        topic: this.topic,
        messages: [
          {
            key,
            value: JSON.stringify(message),
            timestamp: Date.now().toString(),
          },
        ],
      });

      logger.debug(`Telemetry sent for ${key}`);
    } catch (error) {
      logger.error('Failed to send telemetry:', error);
      throw error;
    }
  }

  /**
   * @description Send batch of telemetry messages
   * @param {TelemetryMessage[]} messages - Array of telemetry messages
   */
  async sendBatch(messages: TelemetryMessage[]): Promise<void> {
    if (!this.isConnected) {
      throw new Error('Kafka producer not connected');
    }

    try {
      const kafkaMessages = messages.map((message) => ({
        key: `${message.site_id}.${message.device_id}`,
        value: JSON.stringify(message),
        timestamp: Date.now().toString(),
      }));

      await this.producer.send({
        topic: this.topic,
        messages: kafkaMessages,
      });

      logger.debug(`Batch of ${messages.length} telemetry messages sent`);
    } catch (error) {
      logger.error('Failed to send telemetry batch:', error);
      throw error;
    }
  }

  /**
   * @description Disconnect from Kafka
   */
  async disconnect(): Promise<void> {
    await this.producer.disconnect();
    this.isConnected = false;
  }
}
```

---

## 📥 Consumer Implementation

### Kafka Consumer Pattern (Node.js)

```typescript
import { Kafka, Consumer, EachMessagePayload } from 'kafkajs';
import { logger } from '../utils/logger';

/**
 * @description Kafka consumer for IoT telemetry
 */
export class TelemetryConsumer {
  private consumer: Consumer;
  private isRunning: boolean = false;

  /**
   * @description Creates an instance of TelemetryConsumer.
   * @param {string} brokers - Kafka broker URLs.
   * @param {string} topic - Topic to consume.
   * @param {string} groupId - Consumer group ID.
   * @param {MessageHandler} handler - Message handler.
   */
  constructor(
    private kafka: Kafka,
    private topic: string,
    private groupId: string,
    private handler: MessageHandler
  ) {
    this.consumer = this.kafka.consumer({ groupId: this.groupId });
    this.setupEventHandlers();
  }

  /**
   * @description Setup event handlers
   */
  private setupEventHandlers(): void {
    this.consumer.on('consumer.connect', () => {
      logger.info('Kafka consumer connected');
    });

    this.consumer.on('consumer.group_join', (event) => {
      logger.info(`Consumer joined group: ${event.groupId}`);
    });

    this.consumer.on('consumer.disconnect', () => {
      logger.warn('Kafka consumer disconnected');
    });
  }

  /**
   * @description Start consuming messages
   */
  async start(): Promise<void> {
    await this.consumer.connect();
    await this.consumer.subscribe({ topic: this.topic, fromBeginning: false });

    this.isRunning = true;

    await this.consumer.run({
      eachMessage: async (payload: EachMessagePayload) => {
        await this.handleMessage(payload);
      },
    });
  }

  /**
   * @description Handle incoming message
   * @param {EachMessagePayload} payload - Message payload
   */
  private async handleMessage(payload: EachMessagePayload): Promise<void> {
    try {
      const { topic, partition, message } = payload;

      // Parse message
      const key = message.key?.toString() || '';
      const value = message.value?.toString() || '';
      const data = JSON.parse(value);

      // Create message context
      const context: MessageContext = {
        topic,
        partition,
        offset: message.offset,
        timestamp: message.timestamp,
        key,
      };

      // Route to handler
      await this.handler.handle(data, context);

      logger.debug(`Message processed from partition ${partition}`);
    } catch (error) {
      logger.error('Failed to handle message:', error);
      throw error; // Will trigger retry
    }
  }

  /**
   * @description Stop consuming messages
   */
  async stop(): Promise<void> {
    this.isRunning = false;
    await this.consumer.disconnect();
  }
}

/**
 * @description Message handler interface
 */
interface MessageHandler {
  handle(message: any, context: MessageContext): Promise<void>;
}

/**
 * @description Message context interface
 */
interface MessageContext {
  topic: string;
  partition: number;
  offset: string;
  timestamp: string;
  key: string;
}
```

---

## 🌊 Stream Processing (Kafka Streams)

### Stream Processing Pattern

```typescript
import { Kafka } from 'kafkajs';
import { logger } from '../utils/logger';

/**
 * @description Stream processor for energy aggregations
 */
export class EnergyStreamProcessor {
  /**
   * @description Process telemetry stream and aggregate hourly
   * @param {string} inputTopic - Input telemetry topic
   * @param {string} outputTopic - Output aggregated topic
   */
  async processHourlyAggregation(
    inputTopic: string,
    outputTopic: string
  ): Promise<void> {
    const consumer = this.kafka.consumer({ groupId: 'energy-aggregator' });
    const producer = this.kafka.producer();

    await consumer.connect();
    await producer.connect();
    await consumer.subscribe({ topic: inputTopic });

    // Window buffer for aggregation
    const windowBuffer = new Map<string, TelemetryMessage[]>();

    await consumer.run({
      eachMessage: async ({ message }) => {
        const data: TelemetryMessage = JSON.parse(message.value.toString());

        // Create window key (site + device + hour)
        const date = new Date(data.timestamp);
        const hourKey = `${date.getUTCFullYear()}-${date.getUTCMonth()}-${date.getUTCDate()}-${date.getUTCHours()}`;
        const windowKey = `${data.site_id}.${data.device_id}.${hourKey}`;

        // Add to buffer
        if (!windowBuffer.has(windowKey)) {
          windowBuffer.set(windowKey, []);
        }
        windowBuffer.get(windowKey)!.push(data);

        // Check if window is ready (1 hour passed)
        const now = new Date();
        const windowTime = new Date(date);
        windowTime.setUTCHours(date.getUTCHours() + 1);

        if (now >= windowTime) {
          // Aggregate and send
          const readings = windowBuffer.get(windowKey)!;
          const aggregated = this.aggregateHourly(readings);

          await producer.send({
            topic: outputTopic,
            messages: [
              {
                key: `${data.site_id}.${data.device_id}`,
                value: JSON.stringify(aggregated),
              },
            ],
          });

          // Clear buffer
          windowBuffer.delete(windowKey);

          logger.debug(`Hourly aggregation sent for ${windowKey}`);
        }
      },
    });
  }

  /**
   * @description Aggregate hourly telemetry data
   * @param {TelemetryMessage[]} readings - Array of readings
   * @returns {AggregatedData} Aggregated data
   */
  private aggregateHourly(readings: TelemetryMessage[]): AggregatedData {
    const firstReading = readings[0];
    const totalEnergy = readings.reduce(
      (sum, r) => sum + r.readings.energy_kwh,
      0
    );
    const avgPower = readings.reduce(
      (sum, r) => sum + r.readings.power_kw,
      0
    ) / readings.length;
    const maxPower = Math.max(...readings.map((r) => r.readings.power_kw));
    const minPower = Math.min(...readings.map((r) => r.readings.power_kw));

    return {
      timestamp: firstReading.timestamp,
      site_id: firstReading.site_id,
      device_id: firstReading.device_id,
      window_start: readings[0].timestamp,
      window_end: readings[readings.length - 1].timestamp,
      reading_count: readings.length,
      total_energy_kwh: totalEnergy,
      avg_power_kw: avgPower,
      max_power_kw: maxPower,
      min_power_kw: minPower,
    };
  }
}
```

---

## 🚨 Mandatory Rules

### Topic Rules
- ✅ **ALWAYS** use descriptive topic names
- ✅ **ALWAYS** include environment in topic name
- ✅ **ALWAYS** use keys for partitioning
- ✅ **NEVER** create too many topics
- ✅ **NEVER** use wildcards in production

### Producer Rules
- ✅ **ALWAYS** use batching for high throughput
- ✅ **ALWAYS** set appropriate compression type
- ✅ **ALWAYS** handle errors and retries
- ✅ **NEVER** send messages without keys (if partitioning needed)
- ✅ **NEVER** block on sends (use async)

### Consumer Rules
- ✅ **ALWAYS** use consumer groups for parallel processing
- ✅ **ALWAYS** commit offsets after processing
- ✅ **ALWAYS** handle deserialization errors
- ✅ **NEVER** auto-commit offsets (can cause data loss)
- ✅ **NEVER** block message processing

---

## 📝 Naming Conventions

- Topics: `.` separator, lowercase: `iot.production.telemetry.devices`
- Consumer groups: `kebab-case`: `telemetry-consumer-group-1`
- Keys: Compound identifiers: `site-id.device-id`

---

## ✅ Quality Checklist

Before marking code complete:
- [ ] Topic naming convention followed
- [ ] Message format validated
- [ ] Keys used for partitioning
- [ ] Error handling implemented
- [ ] Consumer groups configured
- [ ] Tests written (80%+ coverage)
- [ ] Code review completed

---

**Remember:** Kafka is for streaming - design your topics and consumer groups with scalability in mind!
