---
name: mqtt-patterns
description: MQTT messaging patterns and conventions for DeJoule IoT development. Use when designing MQTT topics, payloads, QoS levels, or device-to-cloud messaging.
---

# MQTT Message Patterns

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** MQTT patterns and conventions for DeJoule IoT development
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**Use for ALL MQTT development** in DeJoule products:
- Connecting IoT devices to backend
- Implementing device communication
- Handling real-time telemetry data
- Device command and control
- IoT data pipeline architecture

---

## 🏗️ Topic Architecture

### Topic Hierarchy (DeJoule Standard)

```
dejoule/{site_id}/{device_type}/{device_id}/{message_type}
```

### Topic Examples

```
# Energy readings
dejoule/iah-del/chiller/chiller-1/telemetry
dejoule/iah-del/pump/pump-1/telemetry

# Device status
dejoule/iah-del/chiller/chiller-1/status
dejoule/iah-del/pump/pump-1/status

# Commands (downlink)
dejoule/iah-del/chiller/chiller-1/command
dejoule/iah-del/pump/pump-1/command

# Configuration
dejoule/iah-del/chiller/chiller-1/config
dejoule/iah-del/pump/pump-1/config

# Errors/Alerts
dejoule/iah-del/chiller/chiller-1/alert
dejoule/iah-del/pump/pump-1/alert
```

---

## 📨 Message Patterns

### Telemetry Message Pattern

**Topic:** `dejoule/{site_id}/{device_type}/{device_id}/telemetry`

**Payload:**
```json
{
  "timestamp": "2026-05-02T10:30:00Z",
  "readings": {
    "energy_kwh": 125.5,
    "power_kw": 45.2,
    "temperature_c": 7.5,
    "pressure_psi": 85.3
  },
  "metadata": {
    "sequence": 12345,
    "firmware": "1.2.3",
    "battery": 85
  }
}
```

### Status Message Pattern

**Topic:** `dejoule/{site_id}/{device_type}/{device_id}/status`

**Payload:**
```json
{
  "timestamp": "2026-05-02T10:30:00Z",
  "state": "operational",
  "health": "good",
  "uptime_seconds": 86400,
  "last_reboot": "2026-05-01T10:30:00Z"
}
```

### Alert Message Pattern

**Topic:** `dejoule/{site_id}/{device_type}/{device_id}/alert`

**Payload:**
```json
{
  "timestamp": "2026-05-02T10:30:00Z",
  "severity": "warning",
  "code": "HIGH_TEMPERATURE",
  "message": "Chiller temperature exceeds threshold",
  "value": 12.5,
  "threshold": 10.0,
  "unit": "°C"
}
```

---

## 🔌 MQTT Client Implementation (Node.js)

### Publisher Pattern

```typescript
import { Client, connect, Packet } from 'mqtt';
import { logger } from '../utils/logger';

/**
 * @description MQTT publisher for device telemetry
 */
export class DevicePublisher {
  private client: Client;
  private isConnected: boolean = false;

  /**
   * @description Creates an instance of DevicePublisher.
   * @param {string} brokerUrl - MQTT broker URL.
   * @param {string} siteId - Site ID for topic prefix.
   */
  constructor(private brokerUrl: string, private siteId: string) {
    this.client = connect(this.brokerUrl);
    this.setupEventHandlers();
  }

  /**
   * @description Setup MQTT event handlers
   */
  private setupEventHandlers(): void {
    this.client.on('connect', () => {
      this.isConnected = true;
      logger.info('MQTT client connected');
    });

    this.client.on('error', (error) => {
      logger.error('MQTT error:', error);
    });

    this.client.on('close', () => {
      this.isConnected = false;
      logger.warn('MQTT connection closed');
    });
  }

  /**
   * @description Publish telemetry data
   * @param {string} deviceType - Device type (chiller, pump, etc.)
   * @param {string} deviceId - Device ID
   * @param {TelemetryData} data - Telemetry data
   */
  publishTelemetry(
    deviceType: string,
    deviceId: string,
    data: TelemetryData
  ): void {
    if (!this.isConnected) {
      throw new Error('MQTT client not connected');
    }

    const topic = `dejoule/${this.siteId}/${deviceType}/${deviceId}/telemetry`;
    const payload = JSON.stringify(data);

    this.client.publish(topic, payload, { qos: 1 }, (error) => {
      if (error) {
        logger.error('Failed to publish telemetry:', error);
      } else {
        logger.debug(`Telemetry published to ${topic}`);
      }
    });
  }

  /**
   * @description Publish status update
   * @param {string} deviceType - Device type
   * @param {string} deviceId - Device ID
   * @param {StatusData} data - Status data
   */
  publishStatus(
    deviceType: string,
    deviceId: string,
    data: StatusData
  ): void {
    if (!this.isConnected) {
      throw new Error('MQTT client not connected');
    }

    const topic = `dejoule/${this.siteId}/${deviceType}/${deviceId}/status`;
    const payload = JSON.stringify(data);

    this.client.publish(topic, payload, { qos: 1 }, (error) => {
      if (error) {
        logger.error('Failed to publish status:', error);
      }
    });
  }

  /**
   * @description Publish alert
   * @param {string} deviceType - Device type
   * @param {string} deviceId - Device ID
   * @param {AlertData} alert - Alert data
   */
  publishAlert(
    deviceType: string,
    deviceId: string,
    alert: AlertData
  ): void {
    if (!this.isConnected) {
      throw new Error('MQTT client not connected');
    }

    const topic = `dejoule/${this.siteId}/${deviceType}/${deviceId}/alert`;
    const payload = JSON.stringify(alert);

    this.client.publish(topic, payload, { qos: 2 }, (error) => {
      if (error) {
        logger.error('Failed to publish alert:', error);
      }
    });
  }

  /**
   * @description Disconnect from broker
   */
  disconnect(): void {
    this.client.end();
    this.isConnected = false;
  }
}
```

### Subscriber Pattern

```typescript
import { Client, connect } from 'mqtt';
import { logger } from '../utils/logger';

/**
 * @description MQTT subscriber for device data
 */
export class DeviceSubscriber {
  private client: Client;

  /**
   * @description Creates an instance of DeviceSubscriber.
   * @param {string} brokerUrl - MQTT broker URL.
   * @param {string} siteId - Site ID for topic subscription.
   * @param {MessageHandler} messageHandler - Message handler callback.
   */
  constructor(
    private brokerUrl: string,
    private siteId: string,
    private messageHandler: MessageHandler
  ) {
    this.client = connect(this.brokerUrl);
    this.setupEventHandlers();
  }

  /**
   * @description Setup MQTT event handlers
   */
  private setupEventHandlers(): void {
    this.client.on('connect', () => {
      logger.info('MQTT subscriber connected');
      this.subscribeToTopics();
    });

    this.client.on('message', (topic, payload) => {
      this.handleMessage(topic, payload);
    });

    this.client.on('error', (error) => {
      logger.error('MQTT error:', error);
    });
  }

  /**
   * @description Subscribe to site topics
   */
  private subscribeToTopics(): void {
    const topics = [
      `dejoule/${this.siteId}/+/+/telemetry`,
      `dejoule/${this.siteId}/+/+/status`,
      `dejoule/${this.siteId}/+/+/alert`,
    ];

    topics.forEach((topic) => {
      this.client.subscribe(topic, { qos: 1 }, (error) => {
        if (error) {
          logger.error(`Failed to subscribe to ${topic}:`, error);
        } else {
          logger.info(`Subscribed to ${topic}`);
        }
      });
    });
  }

  /**
   * @description Handle incoming message
   * @param {string} topic - Message topic
   * @param {Buffer} payload - Message payload
   */
  private handleMessage(topic: string, payload: Buffer): void {
    try {
      // Parse topic
      const topicParts = topic.split('/');
      const [, siteId, deviceType, deviceId, messageType] = topicParts;

      // Parse payload
      const data = JSON.parse(payload.toString());

      // Route to handler
      this.messageHandler.handle({
        siteId,
        deviceType,
        deviceId,
        messageType,
        data,
        timestamp: new Date(),
      });
    } catch (error) {
      logger.error('Failed to handle message:', error);
    }
  }

  /**
   * @description Disconnect from broker
   */
  disconnect(): void {
    this.client.end();
  }
}

/**
 * @description Message handler interface
 */
interface MessageHandler {
  handle(message: DeviceMessage): void;
}

/**
 * @description Device message interface
 */
interface DeviceMessage {
  siteId: string;
  deviceType: string;
  deviceId: string;
  messageType: string;
  data: any;
  timestamp: Date;
}
```

---

## 🔄 QoS Levels

### QoS Guidelines

```
QoS 0 (Fire and Forget)
- Use for: Frequent, non-critical data
- Examples: Real-time telemetry (latest reading is sufficient)

QoS 1 (At Least Once)
- Use for: Important data that must be delivered
- Examples: Device status, configuration updates

QoS 2 (Exactly Once)
- Use for: Critical data where duplicates are unacceptable
- Examples: Commands, billing data, alerts
```

---

## 🔐 Security Patterns

### Authentication

```typescript
import { connect, IClientOptions } from 'mqtt';

/**
 * @description Create authenticated MQTT client
 */
export function createAuthenticatedClient(
  brokerUrl: string,
  username: string,
  password: string
): Client {
  const options: IClientOptions = {
    username,
    password,
    reconnectPeriod: 5000,
    connectTimeout: 30000,
    clean: true,
  };

  return connect(brokerUrl, options);
}
```

### TLS/SSL

```typescript
import { connect, IClientOptions } from 'mqtt';
import { readFileSync } from 'fs';

/**
 * @description Create secure MQTT client with TLS
 */
export function createSecureClient(
  brokerUrl: string,
  caCertPath: string,
  clientCertPath: string,
  clientKeyPath: string
): Client {
  const options: IClientOptions = {
    ca: readFileSync(caCertPath),
    cert: readFileSync(clientCertPath),
    key: readFileSync(clientKeyPath),
    rejectUnauthorized: true,
    reconnectPeriod: 5000,
  };

  return connect(brokerUrl, options);
}
```

---

## 🧪 Testing Patterns

### Unit Test Template

```typescript
import { DevicePublisher } from './device-publisher';
import { connect } from 'mqtt';

jest.mock('mqtt');

describe('DevicePublisher', () => {
  let publisher: DevicePublisher;
  let mockClient: any;

  beforeEach(() => {
    mockClient = {
      on: jest.fn(),
      publish: jest.fn(),
      end: jest.fn(),
    };

    (connect as jest.Mock).mockReturnValue(mockClient);
    publisher = new DevicePublisher('mqtt://localhost', 'test-site');
  });

  describe('publishTelemetry', () => {
    it('should publish telemetry data', () => {
      const data = {
        timestamp: '2026-05-02T10:30:00Z',
        readings: { energy_kwh: 125.5 },
      };

      publisher.publishTelemetry('chiller', 'chiller-1', data);

      expect(mockClient.publish).toHaveBeenCalledWith(
        'dejoule/test-site/chiller/chiller-1/telemetry',
        JSON.stringify(data),
        { qos: 1 },
        expect.any(Function)
      );
    });
  });
});
```

---

## 🚨 Mandatory Rules

### Topic Rules
- ✅ **ALWAYS** use hierarchical topics
- ✅ **ALWAYS** include site ID in topic
- ✅ **ALWAYS** use message type suffix
- ✅ **NEVER** use wildcard subscriptions in production
- ✅ **NEVER** publish to root topics

### Message Rules
- ✅ **ALWAYS** use JSON for payload format
- ✅ **ALWAYS** include timestamp in messages
- ✅ **ALWAYS** validate message structure
- ✅ **NEVER** send binary data without documentation
- ✅ **NEVER** send messages larger than 256MB

### Security Rules
- ✅ **ALWAYS** use authentication in production
- ✅ **ALWAYS** use TLS for secure communication
- ✅ **ALWAYS** validate message source
- ✅ **NEVER** send credentials in messages
- ✅ **NEVER** use QoS 0 for critical data

---

## 📝 Naming Conventions

- Topics: `kebab-case` with `/` separator
- Message fields: `snake_case`
- Device IDs: `kebab-case` with type suffix

---

## ✅ Quality Checklist

Before marking code complete:
- [ ] Topic hierarchy followed
- [ ] Message format validated
- [ ] Appropriate QoS level used
- [ ] Error handling implemented
- [ ] Security measures in place
- [ ] Tests written (80%+ coverage)
- [ ] Code review completed

---

**Remember:** MQTT is lightweight but critical - design your topic hierarchy and message formats carefully!
