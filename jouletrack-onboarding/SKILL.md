# JouleTRACK Team Onboarding

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Complete team onboarding for JouleTRACK development
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## 🎯 When to Use This Skill

**MANDATORY for all new team members** - Use this skill when:
- Joining the JouleTRACK development team
- Starting work on any JouleTRACK project
- Need to understand the complete system architecture
- Setting up development environment

---

## 🏗️ JouleTRACK System Overview

### What is JouleTRACK?

JouleTRACK is an **IoT-based HVAC energy management platform** that:
- Monitors real-time energy consumption across buildings
- Controls HVAC equipment (chillers, AHUs, pumps, cooling towers)
- Provides analytics and efficiency insights
- Enables predictive maintenance and optimization

### Technology Stack

**Frontend:**
- Angular 15 + TypeScript (strict mode)
- PrimeNG UI components
- Apache ECharts for visualization
- NgRx for state management
- RxJS for reactive programming

**Backend:**
- jt-api-v2: Node.js + Express
- PostgreSQL: Metadata and configuration
- InfluxDB: Time-series sensor data
- Redis: Caching and sessions
- Kafka: Event streaming

**IoT Layer:**
- MQTT brokers for device communication
- iot-application for data ingestion
- Kafka for data streaming
- InfluxDB for time-series storage

**Infrastructure:**
- Docker for containerization
- Kubernetes for orchestration
- Systemd for service management

---

## 📊 Data Flow Architecture

### Sensor Data Flow (IoT → UI)
```
Physical Equipment (Chillers, AHUs, Sensors)
    ↓ (BACnet/Modbus)
Controllers (Read sensors → MQTT payload)
    ↓ (MQTT publish)
MQTT Broker (jouletrack-mqtt)
    ↓ (subscribe)
iot-application (Process & validate)
    ↓ (Kafka produce)
Kafka Broker (iot-ingestion topic)
    ↓ (consume & write)
InfluxDB (Time-series data storage)
    ↓ (query)
jt-api-v2 (API layer)
    ↓ (HTTP/WebSocket)
JouleTRACK UI (Real-time dashboards)
```

### Control Command Flow (UI → IoT)
```
JouleTRACK UI (User action)
    ↓ (HTTP POST)
jt-api-v2 (Validate & authorize)
    ↓ (MQTT publish)
MQTT Broker
    ↓ (subscribe)
hostServices (Edge device)
    ↓ (BACnet/Modbus write)
Physical Equipment (Execute command)
    ↓ (acknowledge)
iot-feedback-handler (Process feedback)
    ↓ (write)
InfluxDB (command_feedback measurement)
    ↓ (WebSocket notify)
JouleTRACK UI (Update status)
```

---

## 🔧 Development Environment Setup

### Prerequisites
```bash
# Node.js 18+
node --version

# Docker & Docker Compose
docker --version
docker-compose --version

# kubectl (for K8s deployments)
kubectl version

# Git
git --version
```

### Project Structure
```
JouleTRACK/
├── frontend/                    # Angular UI
│   ├── src/
│   │   ├── app/
│   │   │   ├── core/           # Singleton services
│   │   │   ├── shared/         # Reusable components
│   │   │   └── features/       # Feature modules
│   │   ├── assets/
│   │   └── environments/
│   └── angular.json
├── jt-api-v2/                   # Backend API
│   ├── src/
│   │   ├── routes/            # API routes
│   │   ├── services/          # Business logic
│   │   ├── models/            # Data models
│   │   └── middleware/        # Express middleware
│   └── package.json
├── iot-application/            # IoT data ingestion
│   ├── src/
│   │   ├── kafka/            # Kafka producers/consumers
│   │   ├── mqtt/             # MQTT handlers
│   │   └── influxdb/         # InfluxDB writers
│   └── package.json
└── docs/                       # Documentation
    ├── api/                   # API documentation
    └── ai/                    # AI assistant context
```

### Local Development Setup

```bash
# 1. Clone repositories
git clone <JouleTRACK-frontend-url>
git clone <jt-api-v2-url>
git clone <iot-application-url>

# 2. Install dependencies
cd JouleTRACK && npm install
cd ../jt-api-v2 && npm install
cd ../iot-application && npm install

# 3. Start local services
# Start PostgreSQL, InfluxDB, Redis, Kafka
docker-compose up -d

# 4. Configure environment variables
cp .env.example .env
# Edit .env with your local configuration

# 5. Run database migrations
npm run migrate:postgres

# 6. Start development servers
# Terminal 1: Frontend
cd JouleTRACK && npm start

# Terminal 2: Backend
cd jt-api-v2 && npm run dev

# Terminal 3: IoT application
cd iot-application && npm run dev
```

---

## 🎓 Key Concepts

### 1. Sites & Equipment
- **Site**: A building/facility (e.g., iah-del = Indraprastha Apollo Delhi)
- **Component**: Individual equipment (chiller, AHU, pump, cooling tower)
- **Device**: Controller/sensor (BACnet/Modbus device)
- **Parameter**: Measurement point (temperature, kW, flow, pressure)

### 2. Data Model
- **PostgreSQL**: Site metadata, equipment hierarchy, user permissions
- **InfluxDB**: Time-series measurements (sensor readings, commands)
- **Redis**: Session cache, real-time state

### 3. Communication Protocols
- **MQTT**: Device ↔ Edge communication
- **Kafka**: Service ↔ Service messaging
- **HTTP/WebSocket**: UI ↔ Backend communication
- **BACnet/Modbus**: Controller ↔ Physical equipment

### 4. Security Model
- **JWT Authentication**: Token-based auth
- **Role-Based Access Control**: Admin, Operator, Viewer roles
- **Site-Level Permissions**: Users access only assigned sites
- **Audit Trail**: All commands logged

---

## 📋 Development Workflow

### 1. Feature Development
```
1. Create feature branch
2. Write tests FIRST (TDD)
3. Implement feature
4. Run tests (80%+ coverage required)
5. Code review (mandatory)
6. Security review (if applicable)
7. Deploy to staging
8. E2E testing
9. Deploy to production
```

### 2. Code Review Process
- **Always** assign itsatif as reviewer
- **Always** assign requesting user as assignee
- **Always** assign AbhilashSri as peer reviewer
- **Must** pass all automated checks
- **Must** have test coverage >= 80%
- **Must** follow coding standards

### 3. Testing Requirements
- **Unit Tests**: All services, components, utilities
- **Integration Tests**: API endpoints, database operations
- **E2E Tests**: Critical user flows
- **Minimum Coverage**: 80%

---

## 🚨 Critical Rules

### Frontend Development
- ✅ **ALWAYS** use `ChangeDetectionStrategy.OnPush`
- ✅ **ALWAYS** unsubscribe from observables (`takeUntil` or `async` pipe)
- ✅ **ALWAYS** handle errors (`catchError`)
- ✅ **NEVER** use `any` type
- ✅ **ALWAYS** use Container/Presenter pattern
- ✅ **ALWAYS** subscribe to site changes in main components

### Backend Development
- ✅ **ALWAYS** validate input (type, required, ranges)
- ✅ **ALWAYS** handle errors explicitly
- ✅ **ALWAYS** use typed DTOs
- ✅ **NEVER** trust client input
- ✅ **ALWAYS** log security events
- ✅ **ALWAYS** use parameterized queries

### IoT Development
- ✅ **ALWAYS** validate sensor data ranges
- ✅ **ALWAYS** handle device disconnection gracefully
- ✅ **ALWAYS** use Kafka for async processing
- ✅ **NEVER** block on device communication
- ✅ **ALWAYS** implement retry logic with backoff
- ✅ **ALWAYS** monitor message queue depth

---

## 🔍 Common Tasks

### Adding a New Dashboard Page
```bash
# Use Angular CLI
ng generate component features/my-dashboard --module features

# Follow Container/Presenter pattern
# my-dashboard.component.ts (container)
# my-dashboard-presenter.component.ts (presenter)
# my-dashboard.service.ts (data layer)
```

### Creating a New API Endpoint
```bash
# Create route file in jt-api-v2/src/routes/
# Create service in jt-api-v2/src/services/
# Add validation schemas
# Write integration tests
# Update API documentation
```

### Adding IoT Data Processing
```bash
# Create Kafka consumer in iot-application/src/kafka/
# Add data validation
# Write to InfluxDB
# Add error handling and retry logic
# Write unit tests
```

---

## 📚 Learning Resources

### Internal Documentation
- `AI_CONTEXT.md` - Complete system context
- `kiro_steering.md` - AI assistant rules
- `docs/ai/` - AI context for different modules

### External Documentation
- Angular: https://angular.dev
- RxJS: https://rxjs.dev
- PrimeNG: https://primeng.org
- InfluxDB: https://docs.influxdata.com/
- Kafka: https://kafka.apache.org/documentation/

---

## 🆘 Getting Help

### Team Communication
- **Technical Issues**: Contact itsatif
- **Code Review**: Assign AbhilashSri + itsatif
- **Architecture Questions**: Schedule architecture review
- **Deployment Issues**: Contact DevOps team

### Troubleshooting
1. Check logs: `docker-compose logs -f [service]`
2. Check database connectivity
3. Verify MQTT/Kafka connections
4. Review error messages in InfluxDB
5. Check browser console for frontend errors

---

## ✅ Onboarding Checklist

### Week 1: Setup & Learning
- [ ] Development environment setup complete
- [ ] All repositories cloned and building
- [ ] Local services running (Postgres, InfluxDB, Redis, Kafka)
- [ ] Read `AI_CONTEXT.md`
- [ ] Read `kiro_steering.md`
- [ ] Complete frontend learning path
- [ ] Complete backend learning path

### Week 2: Practice
- [ ] Create a sample Angular component
- [ ] Create a sample API endpoint
- [ ] Write unit tests for both
- [ ] Get code review approved
- [ ] Deploy to staging environment

### Week 3: Real Work
- [ ] Pick up a actual JIRA ticket
- [ ] Implement feature following TDD
- [ ] Pass code review
- [ ] Deploy to production
- [ ] Monitor and fix any issues

---

**Welcome to the team!** This skill ensures you follow all JouleTRACK patterns and conventions from day one.

**Next Steps:** After completing onboarding, use `/jouletrack-angular` or `/jouletrack-backend` to start your specific role.
