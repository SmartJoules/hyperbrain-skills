---
name: iot-knowledge-base
description: Knowledge base for the DeJoule IoT platform. Use when working on IoT ingestion, device management, or telemetry features and you need platform architecture and convention context.
---

# IoT Knowledge Base

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** Complete IoT platform knowledge for AI-assisted development
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🏗️ IoT Platform Overview

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   DeJoule IoT Platform                        │
└─────────────────────────────────────────────────────────────┘

                    ┌──────────────────┐
                    │  IoT Devices     │
                    │  (Controllers,   │
                    │   Sensors,       │
                    │   HVAC Equip)     │
                    └────────┬─────────┘
                             │ BACnet/Modbus
                    ┌────────▼─────────┐
                    │  Edge Gateway   │
                    │  (hostServices)  │
                    └────────┬─────────┘
                             │ MQTT
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼────────┐  ┌───────▼────────┐  ┌───────▼────────┐
│  MQTT Broker  │  │  IoT Feedback  │  │  IoT Apps      │
│  (Mosquitto)   │  │  Handler       │  │  (iot-app)     │
└───────┬────────┘  └───────┬────────┘  └───────┬────────┘
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
                    ┌────────▼─────────┐
                    │  InfluxDB        │
                    │  (Time-Series DB) │
                    └──────────────────┘
```

---

## 🔌 MQTT Architecture

### Topic Hierarchy

```
dejoule/{site_id}/{service}/{entity_type}/{entity_id}/{message_type}

Examples:
- dejoule/iah-del/telemetry/chiller/chiller-1/readings
- dejoule/iah-del/command/chiller/chiller-1/setpoint
- dejoule/iah-del/feedback/chiller/chiller-1/status
- dejoule/iah-del/alert/chiller/chiller-1/high_temp
```

### Message Patterns

#### Telemetry Message
```json
{
  "timestamp": "2026-05-03T10:30:00Z",
  "site_id": "iah-del",
  "device_id": "chiller-1",
  "device_type": "chiller",
  "readings": {
    "energy_kwh": 125.5,
    "power_kw": 45.2,
    "entering_water_temp_c": 10.5,
    "leaving_water_temp_c": 7.5
  },
  "metadata": {
    "sequence": 12345,
    "firmware": "1.2.3"
  }
}
```

#### Command Message
```json
{
  "timestamp": "2026-05-03T10:30:00Z",
  "request_id": "req-123",
  "site_id": "iah-del",
  "device_id": "chiller-1",
  "command": "set_setpoint",
  "parameters": {
    "setpoint_type": "leaving_water_temperature",
    "value": 7.0,
    "unit": "celsius"
  }
}
```

#### Feedback Message
```json
{
  "timestamp": "2026-05-03T10:30:05Z",
  "request_id": "req-123",
  "site_id": "iah-del",
  "device_id": "chiller-1",
  "status": "success",
  "message": "Setpoint updated successfully",
  "actual_value": 7.0
}
```

---

## 📡 IoT Components

### 1. iot-application
**Purpose:** MQTT → InfluxDB data bridge

**Key Responsibilities:**
- Subscribe to telemetry topics
- Validate and transform data
- Write to InfluxDB
- Publish command acknowledgments

**Data Flow:**
```javascript
MQTT Subscribe (data/#)
  ↓
Validate payload schema
  ↓
Transform to InfluxDB line protocol
  ↓
Write to InfluxDB (device_component/autogen)
  ↓
Publish acknowledgment (if required)
```

### 2. iot-feedback-handler
**Purpose:** Command execution feedback

**Key Responsibilities:**
- Subscribe to command_feedback topics
- Update command status in InfluxDB
- Notify frontend via WebSocket
- Log command failures

**Feedback Flow:**
```javascript
Command sent (via jt-api-v2 → MQTT)
  ↓
Controller receives command
  ↓
Controller executes on hardware
  ↓
Controller publishes feedback (command_feedback)
  ↓
iot-feedback-handler receives
  ↓
Write to InfluxDB (command_feedback measurement)
  ↓
Notify jt-api-v2 (WebSocket/Kafka)
  ↓
Frontend updates UI
```

### 3. hostServices
**Purpose:** Edge device management

**Key Responsibilities:**
- Device health monitoring
- Firmware status tracking
- NAS synchronization
- Connection management
- Local data buffering

**Health Checks:**
```javascript
{
  "service": "hostServices",
  "site_id": "iah-del",
  "status": "healthy",
  "last_seen": "2026-05-03T10:30:00Z",
  "uptime_seconds": 86400,
  "connected_controllers": 5,
  "buffer_size": 1024,
  "firmware_version": "2.1.0"
}
```

---

## 🔄 Data Flows

### Telemetry Ingestion Flow

```
1. HVAC Sensor reads value
   ↓
2. Controller firmware reads via BACnet/Modbus
   ↓
3. Controller packages into MQTT payload
   ↓
4. Controller publishes to MQTT Broker
   Topic: data/{siteId}/{controllerId}/{componentId}
   ↓
5. iot-application receives message
   ↓
6. Validate schema (Joi validation)
   ↓
7. Transform to InfluxDB point
   measurement: components
   tags: siteId, componentId, controllerid
   fields: { dynamic sensor values }
   ↓
8. Write to InfluxDB
   bucket: device_component/autogen
   ↓
9. Publish acknowledgment (if QoS > 0)
```

### Command Flow

```
1. User clicks "Set Setpoint" in JouleTRACK
   ↓
2. Frontend sends POST to jt-api-v2
   Body: { deviceId, setpointType, value }
   ↓
3. jt-api-v2 validates request
   ↓
4. jt-api-v2 publishes to MQTT
   Topic: command/{siteId}/{controllerId}/{componentId}
   Payload: { command, parameters, requestId }
   ↓
5. Controller (hostServices) receives message
   ↓
6. Controller validates against safety limits
   ↓
7. Controller writes to hardware via BACnet/Modbus
   ↓
8. Hardware acknowledges execution
   ↓
9. Controller publishes feedback
   Topic: command_feedback/{siteId}/{controllerId}/{componentId}
   Payload: { requestId, status, actualValue }
   ↓
10. iot-feedback-handler receives feedback
   ↓
11. Write to InfluxDB (command_feedback measurement)
   ↓
12. Notify jt-api-v2 (WebSocket)
   ↓
13. Frontend receives update and shows confirmation
```

---

## 📊 InfluxDB Schema

### Buckets

```javascript
// Raw telemetry
bucket: "device_component/autogen"
retention: 30 days

// Optimization logs
bucket: "cpa_logs_30_days"
retention: 30 days

// Application metrics
bucket: "iot-metrics"
retention: 7 days
```

### Measurements

#### components (Raw Telemetry)
```flux
measurement: components
tags:
  - siteId (string)
  - componentId (string)
  - controllerid (string)
fields: (dynamic, based on component type)
  - For chiller: energy_kwh, power_kw, entering_water_temp_c, leaving_water_temp_c
  - For AHU: supply_air_temp_c, return_air_temp_c, damper_position
  - For pump: flow_gpm, head_ft, motor_speed_rpm
```

#### asset_state (Current Readings)
```flux
measurement: asset_state
tags:
  - site_id (string)
  - id (string)
  - asset_name (string)
  - controllerid (string)
fields:
  - present_value (number)
```

#### command_feedback (Command Results)
```flux
measurement: command_feedback
tags:
  - site_id (string)
  - id (string)
  - param_name (string)
  - asset_name (string)
fields:
  - action_value (number)
  - action_status (string) // "success", "failed", "timeout"
```

---

## 🔌 MQTT Services

### Connection Management

```javascript
const mqtt = require('mqtt');

/**
 * MQTT client configuration
 */
const mqttOptions = {
  clientId: `iot-app-${process.env.HOSTNAME}`,
  clean: true,
  connectTimeout: 30000,
  reconnectPeriod: 5000,
  qos: 1,
};

/**
 * Connect to MQTT broker
 */
const client = mqtt.connect(
  process.env.MQTT_BROKER_URL,
  mqttOptions
);

client.on('connect', () => {
  console.log('Connected to MQTT broker');
  subscribeToTopics();
});

client.on('message', (topic, message) => {
  handleIncomingMessage(topic, message);
});

client.on('error', (error) => {
  console.error('MQTT error:', error);
});
```

### Subscription Patterns

```javascript
/**
 * Subscribe to all telemetry topics
 */
function subscribeToTopics() {
  const topics = [
    'data/+/+/+/+',           // All telemetry
    'command_feedback/+/+/+',  // All feedback
    'state/+/+',               // All state updates
    'logs/+/+',                // All logs
  ];

  topics.forEach(topic => {
    client.subscribe(topic, { qos: 1 }, (error) => {
      if (error) {
        console.error(`Failed to subscribe to ${topic}:`, error);
      } else {
        console.log(`Subscribed to ${topic}`);
      }
    });
  });
}
```

---

## 🚨 Error Handling

### MQTT Connection Errors

```javascript
/**
 * Handle MQTT errors
 */
class MqttErrorHandler {
  handle(error) {
    if (error.message.includes('ECONNREFUSED')) {
      console.error('MQTT broker not reachable');
      // Implement reconnection logic
    } else if (error.message.includes('Not authorized')) {
      console.error('MQTT authentication failed');
      // Check credentials
    } else {
      console.error('Unknown MQTT error:', error);
    }
  }

  /**
   * Reconnection strategy
   */
  reconnect() {
    let retryCount = 0;
    const maxRetries = 10;

    const reconnectInterval = setInterval(() => {
      if (retryCount >= maxRetries) {
        clearInterval(reconnectInterval);
        console.error('Max reconnection attempts reached');
        return;
      }

      console.log(`Reconnection attempt ${retryCount + 1}/${maxRetries}`);
      client.connect();
      retryCount++;
    }, 5000);
  }
}
```

---

## 🧪 Testing IoT Services

### Unit Test (MQTT Handler)

```javascript
describe('MqttTelemetryHandler', () => {
  let handler;
  let mqttClientMock;
  let influxServiceMock;

  beforeEach(() => {
    mqttClientMock = {
      on: jest.fn(),
      subscribe: jest.fn(),
      publish: jest.fn(),
    };

    influxServiceMock = {
      writePoint: jest.fn(),
    };

    handler = new MqttTelemetryHandler(mqttClientMock, influxServiceMock);
  });

  describe('handleTelemetryMessage', () => {
    it('should parse and write to InfluxDB', async () => {
      // Arrange
      const topic = 'data/iah-del/controller1/chiller-1/readings';
      const message = JSON.stringify({
        timestamp: '2026-05-03T10:30:00Z',
        readings: { energy_kwh: 125.5 }
      });

      // Act
      await handler.handleMessage(topic, message);

      // Assert
      expect(influxServiceMock.writePoint).toHaveBeenCalledWith({
        measurement: 'components',
        tags: {
          siteId: 'iah-del',
          componentId: 'chiller-1',
          controllerid: 'controller1'
        },
        fields: { energy_kwh: 125.5 }
      });
    });
  });
});
```

---

## 📚 Key Services Reference

### iot-application
- **Location:** `/iot-application`
- **Language:** Node.js / TypeScript
- **Purpose:** MQTT to InfluxDB bridge
- **Key Files:**
  - `src/subscribers/telemetry.subscriber.ts`
  - `src/parsers/telemetry.parser.ts`
  - `src/writers/influxdb.writer.ts`
  - `src/validators/message.validator.ts`

### iot-feedback-handler
- **Location:** `/iot-communication/iot-feedback-handler`
- **Language:** Node.js / TypeScript
- **Purpose:** Command feedback processing
- **Key Files:**
  - `src/subscribers/feedback.subscriber.ts`
  - `src/handlers/feedback.handler.ts`
  - `src/writers/influxdb.writer.ts`

### hostServices
- **Location:** On edge devices
- **Language:** Python / Node.js
- **Purpose:** Edge device management
- **Key Functions:**
  - Device health monitoring
  - Local data buffering
  - Firmware updates
  - Connection management

---

## 🔧 Configuration

### MQTT Broker Configuration

```javascript
// Mosquitto configuration
mosquitto_conf = {
  listener: 1883,
  allow_anonymous: false,
  persistence: true,
  persistence_location: /var/lib/mosquitto/,
  max_queued_messages: 1000,
  max_connections: 500,
};

// Authentication
mosquitto_passwd = {
  username: "iot-user",
  password: "hashed-password",
};
```

### InfluxDB Configuration

```javascript
// InfluxDB client configuration
const InfluxDB = require('influxdb-client');

const influxDB = new InfluxDB.InfluxDB({
  url: process.env.INFLUX_URL,
  token: process.env.INFLUX_TOKEN,
  org: process.env.INFLUX_ORG,
});

const queryApi = influxDB.getQueryApi(org);
const writeApi = influxDB.getWriteApi(org, 'precision');
```

---

## 🚀 Deployment

### Docker Compose Stack

```yaml
version: '3.8'
services:
  mqtt-broker:
    image: eclipse-mosquitto:2.0
    ports:
      - "1883:1883"
    volumes:
      - mosquitto_data:/mosquitto/data
      - ./mosquitto.conf:/mosquitto/config/mosquitto.conf

  iot-application:
    build: ./iot-application
    depends_on:
      - mqtt-broker
      - influxdb
    environment:
      - MQTT_BROKER_URL=mqtt://mqtt-broker:1883
      - INFLUX_URL=http://influxdb:8086
      - INFLUX_TOKEN=${INFLUX_TOKEN}
      - INFLUX_ORG=jouletrack

  iot-feedback-handler:
    build: ./iot-feedback-handler
    depends_on:
      - mqtt-broker
      - influxdb
    environment:
      - MQTT_BROKER_URL=mqtt://mqtt-broker:1883
      - INFLUX_URL=http://influxdb:8086

  influxdb:
    image: influxdb:2.0
    ports:
      - "8086:8086"
    volumes:
      - influxdb_data:/var/lib/influxdb2
    environment:
      - DOCKER_INFLUXDB_INIT_MODE=setup
      - DOCKER_INFLUXDB_INIT_USERNAME=admin
      - DOCKER_INFLUXDB_INIT_PASSWORD=password
      - DOCKER_INFLUXDB_INIT_ORG=jouletrack
      - DOCKER_INFLUXDB_INIT_BUCKET=device_component
      - DOCKER_INFLUXDB_INIT_RETENTION=30d
```

---

## 📈 Monitoring

### IoT Metrics

```javascript
// Application metrics
const metrics = {
  messagesReceived: 0,
  messagesProcessed: 0,
  messagesFailed: 0,
  influxdbWriteErrors: 0,
  averageProcessingTime: 0,
};

// Publish metrics periodically
setInterval(() => {
  client.publish('iot-metrics/application', JSON.stringify(metrics));
}, 60000); // Every minute
```

### Health Checks

```javascript
/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    services: {
      mqtt: client.connected ? 'connected' : 'disconnected',
      influxdb: influxDB.health ? 'healthy' : 'unhealthy',
      redis: redisClient.isReady ? 'ready' : 'not ready',
    },
    metrics: {
      uptime: process.uptime(),
      memory: process.memoryUsage(),
    },
  };

  const httpStatus = health.services.mqtt === 'connected' ? 200 : 503;
  res.status(httpStatus).json(health);
});
```

---

**This knowledge base provides complete IoT platform context for AI-assisted development.**
