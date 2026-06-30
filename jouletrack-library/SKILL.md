---
name: jouletrack-library
description: Comprehensive development skill library index for the JouleTRACK team. Use as the entry point to discover which JouleTRACK skill applies to a given frontend, backend, IoT, or QA task.
---

# JouleTRACK Development Skill Library

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Comprehensive skill library for JouleTRACK development team
**Version:** 1.0.0
**Last Updated:** 2026-05-03

---

## Overview

This skill library contains all the patterns, conventions, and best practices for JouleTRACK development. When team members use Claude Code with these skills, they'll automatically follow our design philosophy, coding styles, and architectural patterns.

---

## 🎯 How to Use This Library

### For New Team Members
1. Start with `/onboarding-jouletrack` - Complete setup and orientation
2. Use `/jouletrack-angular` for frontend development
3. Use `/jouletrack-backend` for API development
4. Use `/jouletrack-iot` for IoT/data pipeline work

### For Daily Development
- **Frontend work:** `/angular-component`, `/angular-service`, `/angular-facade`
- **Backend work:** `/api-endpoint`, `/api-validation`, `/database-schema`
- **IoT work:** `/iot-kafka`, `/iot-ingestion`, `/influxdb-query`
- **Testing:** `/tdd-workflow`, `/test-angular`, `/test-backend`
- **Code Review:** `/code-review`, `/security-review`
- **Documentation:** `/api-docs`, `/component-docs`

---

## 📁 Skill Categories

### 1. **Foundation Skills** (Must Read First)
- `/onboarding-jouletrack` - Team setup and project overview
- `/jouletrack-architecture` - System architecture and data flows
- `/development-workflow` - Complete development process
- `/coding-standards` - Coding style and conventions

### 2. **Frontend Development**
- `/jouletrack-angular` - Angular patterns and conventions
- `/angular-component` - Component development patterns
- `/angular-service` - Service and data layer patterns
- `/angular-facade` - Facade pattern for state management
- `/angular-charts` - Apache ECharts integration
- `/angular-routing` - Routing and navigation patterns
- `/angular-testing` - Testing Angular code

### 3. **Backend Development**
- `/jouletrack-backend` - Backend architecture and patterns
- `/api-endpoint` - API endpoint development
- `/api-validation` - Input validation standards
- `/api-auth` - Authentication and authorization
- `/database-postgres` - PostgreSQL patterns
- `/database-influx` - InfluxDB query patterns
- `/backend-testing` - Backend testing strategies

### 4. **IoT & Data Pipeline**
- `/jouletrack-iot` - IoT architecture overview
- `/iot-kafka` - Kafka messaging patterns
- `/iot-ingestion` - Data ingestion pipelines
- `/iot-mqtt` - MQTT messaging patterns
- `/influxdb-schema` - Time-series database schema
- `/data-validation` - Data quality validation

### 5. **Development Practices**
- `/tdd-workflow` - Test-driven development
- `/code-review` - Code review process
- `/security-review` - Security review checklist
- `/performance-optimization` - Performance best practices
- `/error-handling` - Error handling patterns
- `/logging-standards` - Logging and monitoring

### 6. **DevOps & Infrastructure**
- `/docker-patterns` - Docker containerization
- `/kubernetes-patterns` - K8s deployment patterns
- `/ci-cd` - CI/CD pipeline patterns
- `/monitoring` - Application monitoring
- `/alerting` - Alerting and incident response

### 7. **Quality & Testing**
- `/test-strategy` - Overall testing strategy
- `/unit-testing` - Unit testing patterns
- `/integration-testing` - Integration testing
- `/e2e-testing` - End-to-end testing
- `/performance-testing` - Performance testing

### 8. **Documentation Standards**
- `/api-documentation` - API documentation standards
- `/code-documentation` - Code documentation patterns
- `/architecture-docs` - Architecture documentation
- `/changelog-standards` - Changelog and release notes

---

## 🎓 Learning Paths

### Path 1: Frontend Developer (1 week)
1. Day 1-2: `/onboarding-jouletrack` + `/jouletrack-architecture`
2. Day 3-4: `/jouletrack-angular` + `/angular-component`
3. Day 5: `/angular-service` + `/angular-facade`
4. Day 6: `/angular-charts` + `/angular-testing`
5. Day 7: `/tdd-workflow` + Practice project

### Path 2: Backend Developer (1 week)
1. Day 1-2: `/onboarding-jouletrack` + `/jouletrack-architecture`
2. Day 3-4: `/jouletrack-backend` + `/api-endpoint`
3. Day 5: `/api-validation` + `/database-influx`
4. Day 6: `/backend-testing` + `/api-auth`
5. Day 7: `/tdd-workflow` + Practice project

### Path 3: IoT Developer (1 week)
1. Day 1-2: `/onboarding-jouletrack` + `/jouletrack-iot`
2. Day 3-4: `/iot-kafka` + `/iot-ingestion`
3. Day 5: `/influxdb-schema` + `/data-validation`
4. Day 6: `/iot-mqtt` + Error handling patterns
5. Day 7: Integration testing + Practice project

### Path 4: Full Stack (2 weeks)
- Combine Frontend + Backend paths
- Add `/code-review`, `/security-review`
- Include `/ci-cd` and `/monitoring`

---

## 🔧 Quick Reference

### Most Used Skills (Top 10)
1. `/jouletrack-angular` - Frontend development
2. `/jouletrack-backend` - Backend development
3. `/api-endpoint` - Create API endpoints
4. `/angular-component` - Create components
5. `/tdd-workflow` - Test-driven development
6. `/code-review` - Review code
7. `/api-validation` - Validate inputs
8. `/angular-facade` - State management
9. `/influxdb-query` - Query time-series data
10. `/error-handling` - Handle errors properly

### For Specific Tasks
- **New feature:** `/tdd-workflow` → `/feature-development`
- **Bug fix:** `/debug-workflow` → `/error-handling`
- **Code review:** `/code-review` → `/security-review`
- **Performance:** `/performance-optimization` → `/performance-testing`
- **Deployment:** `/ci-cd` → `/kubernetes-patterns`

---

## 🚀 Getting Started

### Step 1: Install Skills
```bash
# Clone or copy this skill library to your Claude skills directory
cp -r jouletrack-library ~/.claude/skills/
```

### Step 2: Start Learning
```bash
# In Claude Code, run:
/onboarding-jouletrack
```

### Step 3: Start Coding
```bash
# For frontend work:
/jouletrack-angular

# For backend work:
/jouletrack-backend

# For IoT work:
/jouletrack-iot
```

---

## 📊 Skill Coverage Matrix

| Skill Category | Frontend | Backend | IoT | DevOps |
|----------------|----------|---------|-----|---------|
| Foundation | ✅ | ✅ | ✅ | ✅ |
| Component Dev | ✅ | ❌ | ❌ | ❌ |
| API Dev | ❌ | ✅ | ❌ | ❌ |
| Data Pipeline | ❌ | ✅ | ✅ | ❌ |
| Testing | ✅ | ✅ | ✅ | ❌ |
| Deployment | ❌ | ❌ | ❌ | ✅ |
| Documentation | ✅ | ✅ | ✅ | ✅ |

---

## 🎯 Design Philosophy

### Core Principles
1. **Consistency Over Cleverness** - Follow established patterns
2. **Test-Driven Development** - Write tests first, always
3. **Type Safety** - Explicit types, no `any`
4. **Memory Safety** - Proper cleanup, no leaks
5. **Error Handling** - Explicit error handling at all levels
6. **Documentation** - Document patterns and decisions
7. **Security First** - Validate inputs, sanitize outputs

### Architectural Patterns
- **Frontend:** Container/Presenter, OnPush Change Detection, RxJS
- **Backend:** Port/Adapter, Repository, Service Layer
- **IoT:** Event-Driven, Message Queues, Time-Series Data
- **DevOps:** Containerization, Infrastructure as Code

---

## 🔄 Continuous Improvement

This skill library is continuously updated based on:
- Team feedback and experiences
- New patterns and best practices
- Technology stack updates
- Performance optimizations
- Security improvements

### Contributing
Team members can suggest improvements by:
1. Using patterns and noting gaps
2. Documenting new patterns discovered
3. Sharing successful workflows
4. Reporting issues with existing skills

---

## 📞 Support

For questions or issues:
- Check `/troubleshooting` skill
- Review specific skill documentation
- Consult team leads
- Check AI_CONTEXT.md for project context

---

**Remember:** This library ensures consistency across the team. When in doubt, use the appropriate skill rather than inventing new patterns.
