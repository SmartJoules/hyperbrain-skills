---
name: dejoule-knowledge-base
description: Organizational knowledge base for DeJoule and Smart Joules. Use when you need company-wide architecture, product, or convention context for AI-assisted development across DeJoule projects.
---

# DeJoule Knowledge Base

**Author:** Atif Salafi <atif8486@gmail.com>
**Organization:** DeJoule / Smart Joules
**Purpose:** Complete organizational knowledge for AI-assisted development
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🏢 Organization Overview

### About DeJoule / Smart Joules

**DeJoule** (operating under **Smart Joules**) is an IoT-enabled HVAC optimization company that:
- Provides real-time monitoring and optimization of HVAC systems
- Uses machine learning (CPC models) for predictive control
- Delivers energy savings through automated chiller plant optimization
- Serves commercial buildings, data centers, and industrial facilities

### Core Products
1. **JouleTRACK** - Web-based dashboard for monitoring and control
2. **jt-api-v2** - Backend API serving frontend and mobile apps
3. **Chiller Plant Automation (CPA)** - Automated optimization engine
4. **IoT Platform** - Device telemetry and command infrastructure

### Value Proposition
- **Energy Savings:** 20-40% reduction in HVAC energy consumption
- **Predictive Maintenance:** Early fault detection via ML models
- **Real-Time Control:** Automated setpoint optimization
- **Visibility:** Dashboards for operators and facility managers

---

## 🏗️ Technical Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     DeJoule Ecosystem                        │
└─────────────────────────────────────────────────────────────┘

                    ┌──────────────────┐
                    │   JouleTRACK     │
                    │   (Angular 15)   │
                    └────────┬─────────┘
                             │ HTTPS
                    ┌────────▼─────────┐
                    │    jt-api-v2     │
                    │   (Express.js)   │
                    └────────┬─────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼────────┐  ┌───────▼────────┐  ┌───────▼────────┐
│  PostgreSQL   │  │   InfluxDB     │  │  Redis        │
│  (Metadata)   │  │ (Time-Series)  │  │  (Cache)      │
└───────────────┘  └───────┬────────┘  └───────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
┌───────▼────────┐  ┌───▼──────────┐  ┌─▼─────────────┐
│  MQTT Broker  │  │  IoT App     │  │  CPA Service  │
└───────┬────────┘  └──────────────┘  └───────────────┘
        │
┌───────▼────────┐
│  Edge Devices  │
│  (Controllers) │
└────────────────┘
```

### Technology Stack

#### Frontend
- **Framework:** Angular 15.2.0
- **Language:** TypeScript 5.1 (strict mode)
- **UI Library:** PrimeNG (primary), Angular Material (secondary)
- **Charts:** Apache ECharts 5.x
- **State:** NgRx (store), RxJS 7.5.5
- **Styling:** SCSS with CSS Grid/Flexbox

#### Backend
- **Runtime:** Node.js 18.x, 20.x
- **Framework:** Express.js 4.x
- **Language:** TypeScript 5.x
- **API:** REST (JSON)
- **Authentication:** JWT (Redis-backed sessions)

#### Databases
- **PostgreSQL:** Metadata (sites, devices, users, recipes)
- **InfluxDB 2.x:** Time-series telemetry (sensor readings, optimizations)
- **Redis:** Caching, sessions, rate limiting
- **MongoDB:** Audit logs, alerts (legacy)

#### IoT
- **Protocol:** MQTT 3.1.1/5.0
- **Brokers:** Mosquitto, VerneMQ
- **Edge:** Embedded Linux controllers
- **BMS Protocols:** BACnet, Modbus

#### Infrastructure
- **Containerization:** Docker
- **Orchestration:** Kubernetes (production)
- **Process Management:** Systemd (on-premise)
- **Monitoring:** Prometheus, Grafana

---

## 📊 Data Models

### Core Entities

#### Site
```typescript
interface Site {
  id: string;              // UUID
  name: string;            // "IAH-Del", "Mumbai-Factory"
  location: {
    lat: number;
    lng: number;
    address: string;
  };
  timezone: string;        // "Asia/Kolkata"
  created_at: Date;
  updated_at: Date;
}
```

#### Device / Component
```typescript
interface Component {
  id: string;              // UUID
  site_id: string;         // Foreign key
  name: string;            // "Chiller-1", "AHU-2"
  type: string;            // "chiller", "ahu", "pump", "ct"
  controller_id: string;   // Associated controller
  properties: {
    capacity: number;      // Tons, kW, etc.
    make: string;
    model: string;
  };
  parent_id?: string;      // For hierarchical components
  created_at: Date;
}
```

#### Telemetry (InfluxDB)
```flux
// Measurement: asset_state
tags: site_id, id, asset_name, controllerid
fields: present_value (number)

// Measurement: asset_optimize
tags: site_id, id, param_name, asset_name, controllerid
fields: obs_before_state, obs_after_state, setpoint, action_name
```

---

## 🔌 API Endpoints

### Authentication
```
POST   /api/auth/login          # Login, return JWT
POST   /api/auth/logout         # Invalidate session
GET    /api/auth/validate       # Validate token
```

### Dashboard
```
GET    /api/dashboard/:siteId/consumption     # Energy consumption data
GET    /api/dashboard/:siteId/efficiency      # Plant efficiency metrics
GET    /api/dashboard/:siteId/alarms          # Active alarms
GET    /api/dashboard/:siteId/trends          # Historical trends
```

### Devices
```
GET    /api/sites/:siteId/devices             # List all devices
GET    /api/devices/:deviceId                 # Device details
POST   /api/devices/:deviceId/command         # Send command
GET    /api/devices/:deviceId/telemetry       # Real-time data
```

### Recipes
```
GET    /api/sites/:siteId/recipes             # List optimization recipes
POST   /api/recipes/:recipeId/execute          # Trigger recipe
GET    /api/recipes/:recipeId/status           # Execution status
```

---

## 🎨 Frontend Patterns

### Component Architecture

```typescript
/**
 * Container Component (Smart)
 * - Fetches data via Facade
 * - Handles business logic
 * - Passes data to Presenter
 */
@Component({
  selector: 'app-energy-container',
  template: '<app-energy-presenter [data]="vm$ | async"></app-energy-presenter>',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class EnergyContainerComponent {
  vm$ = this.energyFacade.getViewModel();
  constructor(private energyFacade: EnergyFacade) {}
}

/**
 * Presenter Component (Dumb)
 * - Pure display logic
 * - No side effects
 * - Receives @Input(), emits @Output()
 */
@Component({
  selector: 'app-energy-presenter',
  template: '<div *ngIf="data">{{data.value}}</div>',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class EnergyPresenterComponent {
  @Input() data: EnergyViewModel | null = null;
}
```

### Data Pipeline

```typescript
/**
 * DTO → Domain → ViewModel transformation
 */
@Injectable({ providedIn: 'root' })
export class EnergyFacade {
  constructor(
    private api: EnergyApiService,
    private transformer: EnergyTransformer
  ) {}

  getData(siteId: string): Observable<EnergyViewModel> {
    return this.api.fetchEnergy(siteId).pipe(
      // 1. Transform DTO to Domain
      map(dto => this.transformer.toDomain(dto)),
      // 2. Transform Domain to ViewModel
      map(domain => this.transformer.toViewModel(domain)),
      // 3. Cache for multiple subscribers
      shareReplay(1)
    );
  }
}
```

---

## 📈 Chart Patterns

### ECharts Builder

```typescript
@Injectable({ providedIn: 'root' })
export class EnergyChartBuilder {
  build(data: EnergyData): EChartOption {
    return {
      title: { text: 'Energy Consumption' },
      tooltip: { trigger: 'axis' },
      legend: { data: ['Energy', 'Power'] },
      xAxis: {
        type: 'category',
        data: data.timestamps,
      },
      yAxis: [
        { type: 'value', name: 'Energy (kWh)' },
        { type: 'value', name: 'Power (kW)' }
      ],
      series: [
        {
          name: 'Energy',
          type: 'line',
          data: data.energyValues,
          smooth: true,
          areaStyle: {}
        },
        {
          name: 'Power',
          type: 'line',
          data: data.powerValues,
          smooth: true
        }
      ]
    };
  }
}
```

---

## 🔄 RxJS Patterns

### Common Observable Chains

```typescript
/**
 * Fetch data with site context
 */
this.configService.currentSite$.pipe(
  // Get siteId
  switchMap(siteId => 
    // Fetch data
    this.api.getData(siteId).pipe(
      // Transform
      map(dto => this.transformer.toDomain(dto)),
      map(domain => this.transformer.toViewModel(domain)),
      // Handle errors
      catchError(err => this.handleError(err))
    )
  ),
  // Prevent memory leaks
  takeUntil(this.destroy$)
).subscribe();

/**
 * Combine multiple observables
 */
combineLatest([
  this.configService.currentSite$,
  this.configService.currentTimeRange$
]).pipe(
  switchMap(([siteId, timeRange]) =>
    this.api.getData(siteId, timeRange)
  ),
  takeUntil(this.destroy$)
).subscribe();
```

---

## 🧪 Testing Patterns

### Service Test

```typescript
describe('EnergyFacade', () => {
  let facade: EnergyFacade;
  let apiMock: jasmine.SpyObj<EnergyApiService>;
  let transformerMock: jasmine.SpyObj<EnergyTransformer>;

  beforeEach(() => {
    apiMock = jasmine.createSpyObj('EnergyApiService', ['fetchEnergy']);
    transformerMock = jasmine.createSpyObj('EnergyTransformer', ['toDomain', 'toViewModel']);

    facade = new EnergyFacade(apiMock, transformerMock);
  });

  it('should return transformed view model', () => {
    const mockDto = { /* ... */ };
    const mockDomain = { /* ... */ };
    const mockViewModel = { /* ... */ };

    apiMock.fetchEnergy.and.returnValue(of(mockDto));
    transformerMock.toDomain.and.returnValue(mockDomain);
    transformerMock.toViewModel.and.returnValue(mockViewModel);

    facade.getData('site-1').subscribe(result => {
      expect(result).toEqual(mockViewModel);
    });

    expect(apiMock.fetchEnergy).toHaveBeenCalledWith('site-1');
    expect(transformerMock.toDomain).toHaveBeenCalledWith(mockDto);
    expect(transformerMock.toViewModel).toHaveBeenCalledWith(mockDomain);
  });
});
```

---

## 🚀 Deployment Architecture

### Production Stack

```
┌──────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                   │
├──────────────────────────────────────────────────────┤
│  JouleTRACK (Frontend)                              │
│  - Pod: 3 replicas                                   │
│  - Service: LoadBalancer                             │
│  - Ingress: TLS termination                         │
├──────────────────────────────────────────────────────┤
│  jt-api-v2 (Backend)                                │
│  - Pod: 3 replicas                                   │
│  - Service: ClusterIP                                │
│  - HPA: CPU-based autoscaling                        │
├──────────────────────────────────────────────────────┤
│  PostgreSQL (StatefulSet)                            │
│  - Primary + 2 replicas                               │
│  - PVC: Persistent storage                           │
├──────────────────────────────────────────────────────┤
│  InfluxDB (StatefulSet)                              │
│  - Data node: 3 replicas                              │
│  - Meta node: 3 replicas                              │
├──────────────────────────────────────────────────────┤
│  MQTT Broker (Deployment)                            │
│  - Mosquitto: 2 replicas                              │
│  - Service: LoadBalancer                             │
└──────────────────────────────────────────────────────┘
```

### On-Premise Deployment

```
Edge Site (Customer Location)
├── Docker Compose stack
│   ├── JouleTRACK (Nginx container)
│   ├── jt-api-v2 (Node container)
│   ├── PostgreSQL (Volume mount)
│   ├── InfluxDB (Volume mount)
│   └── MQTT Broker (Container)
└── Network: Isolated VLAN
```

---

## 🔐 Security Architecture

### Authentication Flow

```
1. User enters credentials
   ↓
2. POST /api/auth/login
   ↓
3. Backend validates against PostgreSQL
   ↓
4. Generate JWT (signed with secret)
   ↓
5. Store in Redis (key: session_<token>)
   ↓
6. Return JWT to frontend
   ↓
7. Frontend stores in localStorage
   ↓
8. Subsequent requests include: Authorization: Bearer <token>
   ↓
9. Backend validates:
   - JWT signature
   - Redis session exists
   - Token not expired
   ↓
10. Allow/deny request
```

### Role-Based Access Control

```typescript
enum Role {
  ADMIN = 'admin',           // Full access
  OPERATOR = 'operator',     // View + control devices
  VIEWER = 'viewer',         // Read-only
  SERVICE = 'service'        // Machine-to-machine
}

interface User {
  id: string;
  email: string;
  role: Role;
  site_access: string[];     // Allowed site IDs
}
```

---

## 📊 Key Metrics & KPIs

### Energy Metrics
- **SEC:** Specific Energy Consumption (kWh/TR)
- **COP:** Coefficient of Performance
- **Peak Demand:** Maximum kW draw
- **Energy Consumption:** Total kWh used

### Operational Metrics
- **Uptime:** % time system is operational
- **Data Freshness:** Lag between sensor reading and dashboard
- **Command Success Rate:** % of commands executed successfully
- **Alert Response Time:** Time from alert to acknowledgment

---

## 🎯 Business Logic

### Chiller Plant Optimization (CPA)

**Objective:** Minimize energy consumption while maintaining comfort

**Inputs:**
- Current plant state (InfluxDB: asset_state)
- Weather forecast (external API)
- Building occupancy schedule (PostgreSQL)
- CPC model predictions (ML models)

**Optimization Cycle:**
1. Read current sensor values
2. Predict next period using CPC models
3. Run optimization algorithm (linear programming)
4. Generate optimal setpoints
5. Publish commands via MQTT
6. Monitor feedback (InfluxDB: command_feedback)
7. Adjust if needed

**Outputs:**
- Optimal chilled water temperature
- Optimal condenser water temperature
- Optimal flow rates
- Chiller staging (on/off decisions)

---

## 🚨 Alerting System

### Alert Types

```typescript
enum AlertSeverity {
  CRITICAL = 'critical',   // Immediate action required
  WARNING = 'warning',     // Action needed soon
  INFO = 'info',           // Informational
}

enum AlertCategory {
  DEVICE_OFFLINE = 'device_offline',
  HIGH_TEMPERATURE = 'high_temp',
  LOW_EFFICIENCY = 'low_efficiency',
  COMMAND_FAILED = 'command_failed',
  PREDICTIVE_FAILURE = 'predictive_failure',
}
```

### Alert Flow

``1. Condition detected (CPA / iot-application / rule-engine)
   ↓
2. Alert published to MQTT topic: alerts/{siteId}
   ↓
3. jt-api-v2 receives alert
   ↓
4. Stored in MongoDB (alerts collection)
   ↓
5. Pushed to frontend via WebSocket
   ↓
6. JouleTRACK displays notification
   ↓
7. User acknowledges
   ↓
8. Alert status updated in MongoDB
```

---

## 📚 Module References

### JouleTRACK (Frontend)
- **Location:** `/JouleTRACK`
- **Framework:** Angular 15
- **Key Files:** 596 TypeScript files
- **Key Classes:** 645 classes
- **Key Features:**
  - Dashboard V2 (real-time monitoring)
  - Energy performance charts
  - Device management
  - Recipe configuration
  - Alert management

### jt-api-v2 (Backend)
- **Location:** `/jt-api-v2`
- **Framework:** Express.js / Node.js
- **Key Files:** 250 TypeScript files
- **Key Classes:** 79 classes
- **Endpoints:** 50+ REST endpoints
- **Databases:**
  - PostgreSQL (users, sites, devices)
  - InfluxDB (telemetry)
  - Redis (cache, sessions)
  - MongoDB (alerts, audit logs)

### iot-application
- **Location:** `/iot-application`
- **Purpose:** MQTT → InfluxDB bridge
- **Key Functions:**
  - Subscribe to MQTT topics
  - Validate and transform data
  - Write to InfluxDB
  - Publish commands

### chiller-plant-automation
- **Location:** `/chiller-plant-automation`
- **Purpose:** Automated optimization
- **Key Functions:**
  - Read plant state from InfluxDB
  - Query CPC ML models
  - Run optimization algorithm
  - Publish setpoints via MQTT
  - Log optimization decisions

---

## 🔗 Quick Reference

### Common Tasks

**Add a new chart to dashboard:**
1. Create chart builder: `MyChartBuilder`
2. Add to presenter component
3. Fetch data via facade
4. Build EChartOption
5. Handle resize in ngOnDestroy

**Create a new API endpoint:**
1. Define route in jt-api-v2
2. Create controller method
3. Implement business logic in service
4. Query PostgreSQL/InfluxDB
5. Return typed JSON response

**Add a new device type:**
1. Define component type in PostgreSQL schema
2. Add telemetry fields to InfluxDB measurement
3. Update device management UI
4. Add parsing logic to iot-application

---

**This knowledge base provides complete context for AI-assisted development across the entire DeJoule ecosystem.**
