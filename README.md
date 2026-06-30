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

This is a **comprehensive AI-SDLC skill library** for complete software development. HyperBrain is now organized around an **advanced AI workflow** that targets at least **40% developer-efficiency improvement** on non-trivial work by combining retrieve-first context, multi-agent fleet orchestration, repo-aware implementation, verification gates, and persistent learning.

It covers:
- **Frontend (FE)** - Angular, React, Vue, Next.js, web applications
- **Backend (BE)** - Node.js, Python, Go, APIs, databases
- **IoT** - MQTT, Kafka, InfluxDB, data pipelines, device management
- **Design** - Figma integration, design systems, UI/UX patterns
- **Product** - PRD development, requirements gathering, feature specs
- **DevOps** - CI/CD, Docker, Kubernetes, infrastructure

This library enables **complete AI-SDLC workflows** - from initial product requirements to production deployment.

---

## 📚 Current Skills

Open the dark-mode visual guide at [`agent-skills-guide.html`](agent-skills-guide.html) to see how the agent orchestration skills work together and how to use them.

Use [`docs/AGENTIC_WORKFLOW_COMMANDS.md`](docs/AGENTIC_WORKFLOW_COMMANDS.md) for copy-paste commands and prompts for Pi-like skill loading, multi-agent execution, RBAC/auth, ontology/Neptune, K8s, JouleTRACK frontend, bug postmortems, and verification.

### 🧠 Superpowers (Mandatory First Step)
1. **AI Superpowers - Brainstorming & Planning** - **ACTIVATES AUTOMATICALLY** for all user requests
   - Comprehensive question generation before any planning
   - Structured planning framework with 7 phases
   - Interactive brainstorming with multiple techniques
   - Mandatory execution protocol for all tasks
   - **This is the entry point for all AI-assisted work**
2. **Advanced AI Workflow** - Default high-efficiency operating model for non-trivial engineering
   - Targets 40%+ efficiency via retrieve-first context, `tokensmax` fleet routing, repo-aware contracts, verification gates, and persistent learning
   - Classifies work into product/spec, multi-file engineering, AI/LLM/RAG, diagnostics, UI, review/debug, and performance lanes
   - Measures cycle time, context-loading steps, review iterations, test failures caught, token/cost spend, and reused knowledge artifacts
3. **Long-Term Memory** - Decides what durable engineering knowledge should be saved, where to store it, how to avoid secrets/PII/noise, and how to retrieve verified memory before future planning.
4. **Self Verification** - Mandatory final self-check before completion: latest request alignment, diff review, tests/builds/parsers, source evidence, security/privacy, conventions, and residual-risk reporting.
5. **Self Learning** - Captures user preferences, repo patterns, bug-fix learnings, review feedback, and successful workflows so future HyperBrain runs start with better context.

### Core Development Skills
6. **Engineering Standards** - Mandatory OOP+SOLID, design patterns (strategy/factory/builder/observer/decorator), DRY/KISS, minimal diffs, resilience (no leaks/unhandled promises, error/loading/empty/partial states), query optimization, caching with eviction, and Kafka/Redis connection standards (heartbeat, offset, lag, singleton, retry)
   - **PRD → HTML Prototype** - Turns a PRD/feature spec into a standalone HTML prototype in the JouleTRACK/DeJoule theme (dark teal header, side nav, light background, white cards, Work Sans, `--n-*` tokens)
   - **Agent Planning Harness** - Effective-plan harness for agents: retrieve context, select skills/harnesses, define scope/non-scope, workstreams, dependencies, agent allocation, acceptance criteria, verification gates, risks, stop conditions, and execution handoff packets.
   - **Agentic Engineering** - Operating model for large development at low token cost: progressive context retrieval (graphify/ai-context/local-kb instead of whole-file reads), context budgeting + compaction, and planner→scoped-sub-agent orchestration with a verification gate. Ties together graphify-integration, local-kb, mcp-on-demand, and self-learning.
   - **Agent Orchestration** - Plan and run multi-agent workflows: agent allocation, agent creation, context packets, planning agents, specialist roles, delegation contracts, handoffs, worktree-safe ownership, integration, cross-checks, and verification gates.
   - **Agent Fleet Runner** - Run multiple agents in parallel or staged pipelines, choose solo vs fleet execution, assign model tiers, track worker status, retry failed work, and control cost/time for research, build, review, QA, RCA, and architecture tasks.
   - **Agent Context Manager** - Build minimal context packets for each agent, manage token budgets, prevent leakage, summarize worker outputs, and keep orchestration state compact across multi-agent runs.
   - **Agent Delegation Contracts** - Write precise task briefs for planning, research, implementation, QA, review, and RCA agents with scope, permissions, acceptance criteria, evidence requirements, output schemas, and stop conditions.
   - **Agent Integration Reviewer** - Merge and verify multi-agent outputs: reconcile contracts, detect conflicting edits, review diffs, run final checks, and produce release-readiness handoffs.
   - **Pi Coding Agent** - Pi.dev workflow guide for building and using Pi terminal coding agents: skills, extensions, packages, prompt templates, AGENTS.md context, compaction, print/JSON/RPC/SDK modes, custom agent automation, and HyperBrain planning/verification integration.
   - **Skill Loading Runtime** - Pi-like progressive-disclosure loader for HyperBrain skills: scan `SKILL.md` frontmatter first, rank skills from user intent and repo signals, load selected skill bodies, then load references/scripts/assets only on demand with context-budget and verification rules.
   - **Prompt Harness** - Repo-aware autonomous engineering harness. Detects the repo (JouleTRACK / jt-api-v2 / IoT / generic), binds the generic DB-first + connector-first codegen workflow to that repo's real stack and conventions, gathers context from connectors + precomputed artifacts before writing code, and outputs production-ready, security-checked, tested code per engineering-standards.
   - **Algorithm Picker** - Choose the right algorithm/data structure before coding. General CS selection (sorting/search/graph/DP/hashing/heaps/tries/union-find, Big-O sanity checks) plus the JouleTRACK/IoT domain (time-series downsampling/LTTB, anomaly detection, scheduling/interval-merge, forecasting, Kafka windowing/dedup, Redis eviction).
   - **Engineering AI Assistant** - Senior backend engineer + architect + reviewer that understands the project, inspects connected DBs (schema discovery), confirms risky assumptions, then generates production-ready controllers/services/repositories/DTOs/validation/tests/OpenAPI docs in the project's own patterns. Connector-first, fewer questions.
   - **Database Query Optimizer** - Senior DB performance engineer for PostgreSQL, DynamoDB, MongoDB, InfluxDB (Flux/InfluxQL), and Redis. Analyzes/optimizes/rewrites queries, interprets EXPLAIN/explain() plans, recommends indexes + schema changes, detects anti-patterns, and scores performance — while preserving correctness.
   - **Engineering Planner** - Engineering Manager + TPM skill for epics, features, stories, tasks, sprint plans, critical path, dependencies, team allocation, issue drafts, and delivery milestones.
   - **Backend Implementation Planner** - Staff backend implementation blueprint for modules, services, workers, cron, queues, DTOs, validation, repositories/models, tests, OpenAPI, and deployment notes across Spring Boot, Node.js, Go, and .NET.
   - **Atif Coding Style** - Repo-grounded style guide for writing JouleTRACK and jt-api-v2 code like Atif/itsatif: narrow Sentry-driven fixes, PR feedback cleanup, Angular/NgRx and Sails/Waterline patterns, LLD/system design expectations, focused tests, and PR hygiene.
   - **Code Reviewer** - Senior Staff Engineer review skill for PRs, commits, diffs, files, and repos; reports major/minor issues, security, performance, testing gaps, suggestions, and score.
   - **Root Cause Analyzer** - Production incident RCA skill for logs, stack traces, database errors, CloudWatch/Loki/Kubernetes/PM2/Redis/Nginx/AWS/runtime failures; outputs timeline, root cause, fixes, verification, prevention, and runbook.
   - **Bug Postmortem Learning** - After a bug is solved, produce a blameless postmortem, extract the reusable fix pattern, ask the user whether to ingest it, and save concise KB/runbook/regression-test guidance only after approval.
   - **API & Service Generator** - Backend API/service generator for CRUD, auth, report APIs, entities, DTOs, repositories, services, controllers, validation, OpenAPI, tests, error handling, and logging.
   - **DevOps & Deployment Planner** - Deployment planner/generator for Docker, Compose, Kubernetes, Helm, Terraform, GitHub Actions/GitLab CI, AWS, blue/green, canary, rollback, monitoring, alerting, and runbooks.
   - **sj-k8s Knowledge Base** - SmartJoules Kubernetes/EKS deployment KB from `SmartJoules/sj-k8s`: shared deployments/jobs/networking/RBAC patterns, new-service onboarding, Service/HPA/PDB/Ingress templates, and production guardrails so services use the central K8s repo instead of separate deployment repos.
   - **Lumen Knowledge Base** - Real architecture of the Lumen AI chat assistant (JouleTRACK Angular frontend + jt-api-v2 Sails backend: AWS Bedrock agent, Neptune graph, InfluxDB, SSE chat, tool-registry, caching). Includes a single build prompt (`prompts/lumen-upgrade.md`) to develop the advanced-chat + cache-layer + JouleTRACK-aligned-UX upgrade across both repos in one go.
   - **tokensmax** ⭐ - The productivity engine. Orchestrate your Claude + Codex (+ OpenCode/GLM/Cursor/Antigravity) seats as a headless **fleet** from one session — parallel research/review/builds, right-sized model tiers discovered from `tokensmax status`, read-only by default, worktree-isolated writes, live-access rules, and an explicit confirm gate. Ships a `tokensmax` CLI + `/tokensmax` slash commands. General-purpose (no MCP needed).
   - **proto-to-dejoule** - Turn an Intelligence-team prototype/MVP (HTML, Flask/Streamlit, Figma, spec) into a stack-aligned implementation plan for JouleTRACK + jt-api-v2.
   - **sj-ui-design-system** - dejoule-v4 Angular frontend design system reference — components, design tokens, accessibility, Highcharts, NgRx, loading/error/empty states.
   - **rag-retrieval** - Production RAG patterns: chunking, embeddings (Bedrock Titan), vector + hybrid + graph-RAG, reranking, grounding/citations, freshness/invalidation, retrieval eval. Grounded in the DeJoule/Lumen stack.
   - **prompt-engineering** - Systematic prompting: structure, few-shot, structured/JSON output, chain-of-thought, prompt caching, model-tier-aware prompting, and prompt-injection defense (Bedrock Converse / Claude / Qwen).
   - **llm-eval-guardrails** - Evaluate LLM features (eval sets, LLM-as-judge, grounding/verify-gate, regression) and guard them (PII/secret redaction, injection defense, output validation, rate + cost limits, fallbacks).
   - **agent-tool-design** - Design agent tool-registries and loops: tool granularity + schemas, the tool-use loop (turn limits/parallelism/timeouts/truncation), cost-tiered model routing, grounding, and tracing. Generalizes Lumen's Bedrock agent.
   - **ontology-service-knowledge-base** - SmartJoules/ontology-service KB: Amazon Neptune RDF/SPARQL graph, Apache Jena/Fuseki on-prem setup + cloud sync, Brick Schema + `sj:` model, repo tools, Graph Explorer, ingestion/update safety, and query recipes for building semantics.
   - **brick** - Brick Schema lookup/modeling skill backed by ontology-service's vendored `brick-kb`; use for class, point, relationship, example, and SHACL validation questions.
   - **neptune-graph** - SmartJoules Neptune query/update skill: site-scoped SPARQL, safe `DELETE/INSERT/WHERE`, telemetry references, components/devices/controllers/locations, water loops, and graph guardrails.
   - **dejoule-rbac** - DeJoule/JouleTRACK RBAC implementation guide: jt-api-v2 policies, role policy catalog, site access, action permission mapping, legacy JouleTrack-API checks, and Angular route/menu/button guards.
   - **dejoule-authentication** - DeJoule/JouleTRACK authentication guide: login, JWT/session revocation, secure cookies, OTP/MFA, reCAPTCHA risk fallback, token refresh/logout, service tokens, frontend auth handling, and step-up auth.
   - **dejoule-geofencing-alerts** - Spatial and semantic geofencing for Smart Alerts: Haversine/polygon/grid algorithms, ontology-based floor/zone resolution, Neptune/Fuseki SPARQL recipes, alert routing/suppression/dedup/escalation, and UI/API integration guardrails.
   - **dejoule-onpremise** - Office-space on-premise KB for cloud-to-onprem FIFO sync, onprem-sync-fifo-router Lambda, local FIFO consumer, onprem-to-cloud bridge, MSK-to-IoT bridge, MQTT-to-Kafka bridge, site onboarding migration, ordering, retries, metrics, and troubleshooting.
   - **software-architecture-planner** - Staff/principal engineer + solution architect workflow that converts business requirements into scalable architecture, HLD/LLD, ADRs, Mermaid diagrams, API/database/security/deployment designs, risks, sprint plans, and team task breakdowns.

### Internal Engineering Platform Workflow
Business requirement → **Software Architecture Planner** → **Engineering Planner** → **Backend Implementation Planner** → **API & Service Generator** + **Database Query Optimizer** → **Code Reviewer** → **DevOps & Deployment Planner** → **Root Cause Analyzer** for production troubleshooting.

### DeJoule Operations & Diagnostics (need SmartJoules MCP: Sentinel, Morpheus)
   - **cpa-health** - Holistic health audit of CPA (Chiller Plant Automation) + the full IoT stack (sensors → PostgreSQL → runtime → InfluxDB → commands → BMS).
   - **cpa-rca** - Takes a site complaint and produces a structured root-cause report.
   - **iot-health** - Deep IoT infrastructure diagnosis — controllers, network, firmware, data pipeline, services.
   - **smartjoules-influxdb** - How to query the SmartJoules time-series stores: TSDB (AWS Timestream raw) + IoT InfluxDB (processed) — auth, schema, Flux patterns, Python examples.
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

### Step 0: Advanced AI Workflow (Default for Non-Trivial Work)
For features, reviews, debugging, product-to-code, LLM/RAG, or multi-file tasks:
1. Classify the lane and load the relevant skills
2. Retrieve context from graph/KB/`ai-context`/targeted search before reading files
3. Use `tokensmax` to route build/research/review to the right configured AI seat and model tier
4. Implement with repo-aware contracts and minimal diffs
5. Verify with tests, build, diff review, browser QA, or LLM evals as appropriate
6. Persist reusable decisions and patterns back into the local knowledge base

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

> 📖 **See [USAGE_GUIDE.md](USAGE_GUIDE.md)** for detailed install steps (Claude Code,
> Codex/Cursor/Copilot, manual, update, verify) and a full **"which skill when"**
> reference organized by scenario, plus how skills compose on real tasks.

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
