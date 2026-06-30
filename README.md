# HyperBrain Skills Library

[![Install](https://github.com/SmartJoules/hyperbrain-skills/actions/workflows/install.yml/badge.svg)](https://github.com/SmartJoules/hyperbrain-skills/blob/main/INSTALL.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/SmartJoules/hyperbrain-skills/blob/main/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/SmartJoules/hyperbrain-skills?style=social)](https://github.com/SmartJoules/hyperbrain-skills)

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Complete AI-powered skill library for full-stack software development
**Version:** 2.0.0
**Last Updated:** 2026-05-03

---

## 🚀 Quick Install

```bash
# One-command installation
curl -sSL https://raw.githubusercontent.com/SmartJoules/hyperbrain-skills/main/install.sh | bash

# Or clone and install
git clone https://github.com/SmartJoules/hyperbrain-skills.git /tmp/hyperbrain-skills
cd /tmp/hyperbrain-skills && ./install.sh

# Skills are now active! Restart your AI assistant.
```

**For detailed installation instructions, see [INSTALL.md](INSTALL.md)**

---

## 🎯 Overview

This is a **comprehensive AI-SDLC skill library** for complete software development, covering:
- **Frontend (FE)** - Angular, React, Vue, Next.js, web applications
- **Backend (BE)** - Node.js, Python, Go, APIs, databases
- **IoT** - MQTT, Kafka, InfluxDB, data pipelines, device management
- **Design** - Figma integration, design systems, UI/UX patterns
- **Product** - PRD development, requirements gathering, feature specs
- **DevOps** - CI/CD, Docker, Kubernetes, infrastructure

This library enables **complete AI-SDLC workflows** - from initial product requirements to production deployment.

---

## 📚 Current Skills

### 🧠 Superpowers (Mandatory First Step)
1. **AI Superpowers - Brainstorming & Planning** - **ACTIVATES AUTOMATICALLY** for all user requests
   - Comprehensive question generation before any planning
   - Structured planning framework with 7 phases
   - Interactive brainstorming with multiple techniques
   - Mandatory execution protocol for all tasks
   - **This is the entry point for all AI-assisted work**

### Core Development Skills
2. **Engineering Standards** - Mandatory OOP+SOLID, design patterns (strategy/factory/builder/observer/decorator), DRY/KISS, minimal diffs, resilience (no leaks/unhandled promises, error/loading/empty/partial states), query optimization, caching with eviction, and Kafka/Redis connection standards (heartbeat, offset, lag, singleton, retry)
3. **TDD Workflow** - Test-driven development with Red-Green-Refactor cycle
3. **Angular Patterns** - Enterprise Angular development patterns
4. **React Patterns** - Modern React with hooks, React Query, TypeScript
5. **Vue Patterns** - Vue 3 Composition API, Pinia, Vue Query
6. **Next.js Patterns** - Full-stack React with SSR/SSG
7. **State Management** - Redux, Zustand, Pinia, NgRx patterns

### Backend Skills
8. **Node.js Patterns** - Express/Node.js APIs with TypeScript
9. **Python Patterns** - FastAPI with async/await and Pydantic
10. **Go Patterns** - High-performance Go with Gin/GORM
11. **Database Patterns** - PostgreSQL, InfluxDB, MongoDB, Redis

### IoT Skills
12. **MQTT Patterns** - IoT device communication and messaging
13. **Kafka Patterns** - Stream processing and event-driven architecture
14. **InfluxDB Patterns** - Time-series data storage and Flux queries
15. **IoT Architecture** - Complete IoT system design patterns

### QA & Testing Skills
16. **Playwright Patterns** - E2E testing with Page Object Model
17. **QA Automation** - AI-powered test generation from knowledge bases

### MCP Integration Skills
18. **MCP Setup** - Configure MCP servers (Notion, Figma, GitHub, Slack, databases)

### Knowledge Bases
- **DeJoule Organizational KB** (18,773 words) - Complete ecosystem knowledge
- **Backend KB - jt-api-v2** (12,456 words) - API microservice architecture
- **IoT Platform KB** (15,234 words) - MQTT, InfluxDB, device integration
- **QA Automation KB** (2,340 words) - Test generation and automation

### BuildLoop Reference
This library is inspired by **BuildLoop's AI-SDLC approach** and extends it for comprehensive software development across all technology domains.

---

## 🚀 How It Works - The AI-SDLC Workflow

### Step 1: 🧠 Activate Superpowers (Automatic)
When you ask any question or request any feature:
1. AI automatically activates brainstorming skill
2. Asks clarifying questions to understand requirements
3. Generates multiple approaches for your consideration
4. You select the best approach
5. Creates detailed implementation plan

### Step 2: 🛠️ Select Appropriate Skills
AI selects relevant technical skills based on:
- Tech stack (Angular, React, Node.js, Python, Go, etc.)
- Domain (Frontend, Backend, IoT, Database)
- Requirements from brainstorming phase

### Step 3: 📋 Follow Best Practices
Selected skill ensures:
- Consistent code patterns
- Proper documentation
- Error handling
- Testing (TDD)
- Security considerations

### Step 4: ✅ Quality Assurance
Before completion, AI verifies:
- All requirements met
- Code follows patterns
- Tests written (80%+ coverage)
- Documentation complete
- Best practices followed

### Example Workflow

```bash
You: "Add user authentication to my Angular app"

AI: "Let me understand your authentication needs:
      1. What authentication methods? (Email/password, OAuth, SAML?)
      2. Any social logins needed? (Google, GitHub?)
      3. Role-based permissions required?
      4. Any compliance requirements? (GDPR, HIPAA?)
      5. Session management preferences?"

You: "Email/password with JWT, role-based access, needs to work with our existing Node.js API"

AI: "Perfect! I see 3 approaches:
      Option 1: Angular + JWT interceptors (Simple, fast)
      Option 2: Angular + Auth0 library (Feature-rich, managed)
      Option 3: Custom auth service (Maximum control, more work)

      Which approach interests you?"

You: "Option 1 - keep it simple and fast"

AI: "Great! Here's the implementation plan:
      Phase 1: Auth Service (login, logout, token refresh)
      Phase 2: Route Guards (protected routes)
      Phase 3: JWT Interceptor (attach tokens to API calls)
      Phase 4: Role-based directives (UI access control)

      Ready to start with Phase 1?"
```

## 🚀 AI-SDLC Workflow

### 1. Product Discovery Phase
```
User Requirement → PRD Development → Technical Specification → Architecture Design
```
Skills: product-definition, requirements-gathering, prd-development, technical-specs

### 2. Design Phase
```
Technical Specs → Figma Design → Design Review → Design Tokens → Component Library
```
Skills: figma-integration, design-systems, ui-patterns, component-library

### 3. Frontend Development
```
Design → Component Development → State Management → API Integration → Testing
```
Skills: angular-patterns, react-patterns, vue-patterns, state-management

### 4. Backend Development
```
API Design → Database Schema → Service Implementation → Testing → Documentation
```
Skills: api-design, nodejs-patterns, python-patterns, database-schema, api-documentation

### 5. IoT Development
```
Device Integration → Data Pipeline → MQTT/Kafka → Time-Series Database → Monitoring
```
Skills: mqtt-patterns, kafka-integration, influxdb-patterns, iot-architecture

### 6. DevOps & Deployment
```
CI/CD Pipeline → Docker Containers → Kubernetes Deployment → Monitoring → Alerting
```
Skills: cicd-patterns, docker-patterns, kubernetes-patterns, monitoring, alerting

### 7. Quality & Testing
```
Unit Tests → Integration Tests → E2E Tests → Performance Tests → Security Review
```
Skills: tdd-workflow, testing-strategies, e2e-testing, performance-testing, security-review

---

## 🔮 Coming Soon

### Frontend Skills
- React Development Patterns
- Vue.js Development Patterns
- Next.js Patterns
- State Management (Redux, Vuex, Pinia)
- Component Library Development

### Backend Skills
- Node.js/Express Patterns
- Python/FastAPI Patterns
- Go/Gin Patterns
- GraphQL Development
- REST API Design

### IoT Skills
- MQTT Message Patterns
- Kafka Stream Processing
- InfluxDB Query Patterns
- Device Management
- Data Pipeline Architecture

### Design Skills
- Figma Integration (MCP-powered)
- Design System Development
- Component Library
- Design Tokens
- Prototyping

### Product Skills
- PRD Development
- Requirements Engineering
- Feature Specification
- User Story Mapping
- Agile Planning

### DevOps Skills
- CI/CD Pipeline Design
- Docker Containerization
- Kubernetes Orchestration
- Infrastructure as Code
- Monitoring & Observability

---

## 📋 Installation

### Quick Install (Recommended)

The installer copies each skill into its own folder under `~/.claude/skills/`,
which is exactly what Claude Code expects.

```bash
git clone https://github.com/SmartJoules/hyperbrain-skills.git /tmp/hyperbrain-skills
cd /tmp/hyperbrain-skills
./install.sh

# Restart Claude Code — skills are immediately available
```

### Manual Setup

Each skill is a directory with a `SKILL.md` inside. Claude Code registers a skill
by the `name` in its frontmatter and requires one folder per skill. Do **not**
clone the repo straight into `~/.claude/skills` and do **not** `cp -r repo/* ...`
(that copies top-level docs and `.git` as junk). Copy each skill directory:

```bash
# 1. Clone the repository to a temp location
git clone https://github.com/SmartJoules/hyperbrain-skills.git /tmp/hyperbrain-skills

# 2. Copy every skill (each dir containing a SKILL.md) into ~/.claude/skills/
mkdir -p ~/.claude/skills
find /tmp/hyperbrain-skills -name SKILL.md -not -path '*/.git/*' | while read -r f; do
  d="$(dirname "$f")"
  cp -r "$d" ~/.claude/skills/"$(basename "$d")"
done

# 3. Restart Claude Code — skills are now active
```

---

## 🎯 Usage Examples

### Product Development Workflow
```bash
# 1. Start with PRD
"Create a PRD for a new IoT monitoring dashboard"

# 2. Move to design
"Design the IoT dashboard using Figma"

# 3. Implement frontend
"Build the dashboard frontend using Angular"

# 4. Implement backend
"Create the backend API for IoT data"

# 5. Add IoT integration
"Implement MQTT integration for device data"

# 6. Deploy
"Set up CI/CD pipeline for the dashboard"
```

### AI-SDLC Complete Workflow
```bash
# Complete feature from PRD to deployment
"I need to build a complete IoT monitoring feature:

1. Product: An IoT dashboard for monitoring chiller efficiency across multiple sites
2. Design: Use Figma design from [link]
3. Frontend: Angular with real-time charts
4. Backend: Node.js API with InfluxDB
5. IoT: MQTT integration for device data
6. Testing: Full test coverage with TDD
7. Deployment: Docker + Kubernetes

Follow complete AI-SDLC workflow."
```

---

## 🏗️ Architecture

### Skill Organization
```
hyperbrain-skills/
├── README.md                      # This file
├── 00-core/                       # Core skills (always loaded)
│   ├── product-development/
│   ├── ai-sdlc-workflow/
│   └── quality-standards/
├── 01-frontend/                   # Frontend skills
│   ├── angular/
│   │   └── angular-patterns/      # Angular development patterns
│   ├── react/                     # Coming soon
│   ├── vue/                       # Coming soon
│   └── nextjs/                    # Coming soon
├── 02-backend/                   # Backend skills
│   ├── nodejs/                    # Coming soon
│   ├── python/                    # Coming soon
│   └── go/                        # Coming soon
├── 03-iot/                       # IoT skills
│   ├── mqtt/                      # Coming soon
│   ├── kafka/                     # Coming soon
│   └── influxdb/                  # Coming soon
├── 04-design/                    # Design skills
│   ├── figma/                     # Coming soon
│   ├── design-systems/            # Coming soon
│   └── component-library/         # Coming soon
├── 05-product/                   # Product skills
│   ├── prd/                       # Coming soon
│   ├── requirements/              # Coming soon
│   └── agile/                     # Coming soon
└── 06-devops/                    # DevOps skills
    ├── cicd/                      # Coming soon
    ├── docker/                    # Coming soon
    ├── kubernetes/               # Coming soon
    └── monitoring/                # Coming soon
```

---

## 🔌 MCP Server Setup

Enable AI assistants to access external services (Notion, Figma, GitHub, Slack, databases):

```bash
# Navigate to MCP setup directory
cd hyperbrain-skills/mcp-setup

# Run automated setup
./setup-mcp.sh

# This will:
# - Create ~/.claude/.env for secure token storage
# - Prompt you for API tokens
# - Install MCP servers globally
# - Update Claude settings with MCP configurations
# - Set proper file permissions (600)
```

**Supported MCP Servers:**
- 📝 **Notion** - Document management, PRDs, wikis
- 🎨 **Figma** - Design system collaboration
- 🐙 **GitHub** - Repository management, PRs, issues
- 💬 **Slack** - Team communication, notifications
- 🗄️ **PostgreSQL** - Relational database queries
- 🍃 **MongoDB** - NoSQL document operations
- ⚡ **Redis** - Key-value cache operations

**For detailed MCP setup instructions, see [mcp-setup/README.md](mcp-setup/README.md)**

---

## 🎓 Learning Paths

### Product Manager
1. **Product Development** - PRD creation, requirements, user stories
2. **Design Integration** - Figma MCP, design systems
3. **Agile Planning** - Sprint planning, backlog management

### Frontend Developer
1. **JouleTRACK Onboarding** - System architecture
2. **Angular Patterns** - Component development, state management
3. **TDD Workflow** - Test-driven development
4. **React/Vue** - Additional frameworks (coming soon)

### Backend Developer
1. **JouleTRACK Onboarding** - System architecture
2. **API Design** - REST/GraphQL APIs (coming soon)
3. **Database Patterns** - SQL/NoSQL (coming soon)
4. **TDD Workflow** - Test-driven development

### IoT Developer
1. **JouleTRACK Onboarding** - System architecture
2. **IoT Architecture** - MQTT, Kafka, InfluxDB (coming soon)
3. **Data Pipelines** - Stream processing (coming soon)
4. **TDD Workflow** - Test-driven development

### DevOps Engineer
1. **JouleTRACK Onboarding** - System architecture
2. **CI/CD Patterns** - Pipeline design (coming soon)
3. **Docker & K8s** - Containerization (coming soon)
4. **Monitoring** - Observability (coming soon)

---

## 📊 Roadmap

### Phase 1: Foundation (Current) ✅
- ✅ Core skill library structure
- ✅ JouleTRACK-specific skills
- ✅ TDD workflow
- ✅ Initial AI-SDLC patterns

### Phase 2: Frontend Expansion (Q2 2026)
- [ ] React development skills
- [ ] Vue.js development skills
- [ ] Next.js patterns
- [ ] State management patterns

### Phase 3: Backend Expansion (Q2 2026)
- [ ] Node.js/Express patterns
- [ ] Python/FastAPI patterns
- [ ] Go/Gin patterns
- [ ] Database design skills

### Phase 4: IoT Integration (Q3 2026)
- [ ] MQTT message patterns
- [ ] Kafka stream processing
- [ ] InfluxDB query patterns
- [ ] Device management

### Phase 5: Design System (Q3 2026)
- [ ] Figma MCP integration
- [ ] Design system development
- [ ] Component library
- [ ] Design tokens

### Phase 6: Product & DevOps (Q4 2026)
- [ ] PRD development skills
- [ ] CI/CD pipeline patterns
- [ ] Kubernetes deployment
- [ ] Monitoring & observability

---

## 🤝 Contributing

### For DeJoule Team Members
1. Identify skill gaps in your domain
2. Document patterns from your codebase
3. Create skill following template
4. Submit pull request
5. Get review from team leads

### Skill Creation Template
```markdown
---
name: domain-skill-name
description: Skill description
origin: DeJoule
---

# Skill Title

## When to Use This Skill
[Describe when to activate]

## Core Principles
[List key principles]

## Implementation Patterns
[Show code examples]

## Quality Checklist
[What to check before completing]

## Examples
[Real examples from DeJoule codebase]
```

---

## 🔗 Links

- **Repository:** [GitHub Repository](https://github.com/SmartJoules/hyperbrain-skills)
- **Installation:** [Installation Guide](INSTALL.md)
- **Documentation:** [Full Documentation](https://github.com/SmartJoules/hyperbrain-skills/blob/main/README.md)
- **Issues:** [Report Issues](https://github.com/SmartJoules/hyperbrain-skills/issues)

---

## 📜 License

MIT License - See LICENSE file for details.

Free to use and modify for any purpose.

---

**Remember:** This skill library enables complete AI-SDLC workflows for full-stack software development, ensuring consistency, quality, and speed across your entire engineering organization!

**Next:** Check the individual skill directories to start using specific patterns for your domain.
