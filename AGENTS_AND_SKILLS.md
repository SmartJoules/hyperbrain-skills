# HyperBrain Agents & Skills

> Auto-generated from each skill's `SKILL.md` frontmatter by `scripts/gen-agents-doc.js`.
> Do not hand-edit — re-run the generator after adding/removing a skill.
> Total: **86** skills (24 agents/workers · 7 knowledge bases · 55 reference/pattern skills).

## How to call them

A skill = a directory with `SKILL.md` (`name` + `description`). Skills load **automatically** when your task matches the description; you can also invoke explicitly:

- **Claude Code** — name the skill in your ask ("use the *code-reviewer* skill on this diff") or via the Skill tool. Skills install under `~/.claude/skills/` (`./install.sh`).
- **Pi (pi.dev)** — `/skill:<name>` (e.g. `/skill:design-doc-review-agent <doc>`); args after the command are passed to the skill. Install via `./install.sh --assistant pi` → `~/.pi/agent/skills/`.
- **Codex / Cursor / Copilot** — no native registry; `./install.sh --assistant codex` generates an `AGENTS.md` index they read, then open `skills/<name>/SKILL.md` for the task.
- **CLI agents (tokensmax)** — the `tokensmax` skill ships a `tokensmax` CLI to dispatch work across Claude/Codex/GLM seats (`/tokensmax <task>`).
- **CI** — `design-doc-reviewer` ships a deterministic gate + `anthropics/claude-code-action` workflow that runs the review agent on PRs.

Agents compose: a planner → implementer → reviewer chain is normal. See `USAGE_GUIDE.md` for "which skill when" and how they combine.

## Agents & workers (callable — they DO work)

| Skill | What it does (when to use it) |
|-------|-------------------------------|
| **agent-context-manager** | Use when preparing, compressing, routing, refreshing, or auditing context for multiple AI agents: creating minimal context packets, managing token budgets, preventing context leakage, sharing repo ins |
| **agent-delegation-contracts** | Use when writing high-quality delegation prompts for AI agents or subagents: creating task briefs, acceptance criteria, role prompts, ownership boundaries, allowed tools, write permissions, stop condi |
| **agent-fleet-runner** | Use when running multiple AI agents at once: dispatching parallel workers, choosing solo vs fleet execution, assigning model tiers, using tokensmax or subagents, isolating write agents, tracking statu |
| **agent-integration-reviewer** | Use after multiple AI agents have produced plans, research, code changes, reviews, tests, or PR feedback and their outputs must be merged, reconciled, conflict-checked, verified, summarized, or prepar |
| **agent-orchestration** | Use when planning, creating, allocating, delegating to, coordinating, or reviewing multiple AI agents or subagents: agent allocation, agent creation, planning agents, specialist agents, context manage |
| **agent-planning-harness** | Use when an AI agent must create an effective execution plan before coding, researching, reviewing, debugging, deploying, or delegating. |
| **agent-tool-design** | Design LLM agents and their tools. |
| **agentic-engineering** | Operating model for large, multi-step development with low token consumption. |
| **algorithm-picker** | Choose the right algorithm or data structure for a problem before implementing it. |
| **api-service-generator** | Use when generating or planning CRUD APIs, authentication APIs, report APIs, service modules, entities, DTOs, repositories, services, controllers, validation, Swagger/OpenAPI, tests, error handling, l |
| **architecture-reviewer** | Review and audit an EXISTING system's architecture (not line-level code, not greenfield design). |
| **backend-implementation-planner** | Use when planning backend implementation for a module, service, API, CRUD flow, report scheduler, worker, cron job, queue, email flow, or data workflow. |
| **code-reviewer** | Use when reviewing pull requests, commits, diffs, files, repositories, or generated code for architecture, code quality, security, performance, memory, concurrency, thread safety, naming, SOLID, desig |
| **database-query-optimizer** | Senior Database Performance Engineer for PostgreSQL, DynamoDB, MongoDB, InfluxDB (Flux/InfluxQL), and Redis. |
| **design-doc-harness** | End-to-end design-doc process used by top product companies (Google/Amazon/Meta-style). |
| **design-doc-review-agent** | A callable reviewer agent (Pi-style, also works in Claude Code) that reviews a software design doc for correctness against FAANG-style standards and adds repo-grounded feedback. |
| **design-doc-reviewer** | Review a design document (HLD/LLD, RFC, tech spec, ADR, *-design.md) against required structure, engineering constraints, and the hyperbrain skill standards — then APPROVE or REJECT with concrete, act |
| **devops-deployment-planner** | Use when planning or generating deployment assets and operational rollout for Docker, Docker Compose, Kubernetes, Helm, Terraform, GitHub Actions, GitLab CI, AWS deployment, blue/green deploys, canary |
| **engineering-ai-assistant** | Internal engineering assistant that acts as a senior backend engineer, solution architect, and code reviewer. |
| **engineering-planner** | Use when turning architecture, PRDs, business requirements, or feature ideas into engineering execution plans: epics, features, stories, tasks, subtasks, sprint plans, Jira/GitHub/Linear issue drafts, |
| **prompt-harness** | Repo-aware autonomous engineering harness. |
| **root-cause-analyzer** | Use when investigating incidents, bugs, outages, regressions, logs, stack traces, database errors, CloudWatch/Loki/Kubernetes/PM2/Redis/Nginx/AWS/Node/Java/Go failures, performance spikes, or producti |
| **software-architecture-planner** | Use when converting business requirements, product ideas, PRDs, prototypes, or stakeholder requests into scalable software architecture, implementation plans, engineering tasks, technical documentatio |
| **tokensmax** | Orchestrates the user's coding-agent subscriptions (Claude, Codex, OpenCode, GLM, Cursor, Antigravity) as a fleet via the `tokensmax` CLI — briefs what's available, proposes routing options across sea |

## Knowledge bases (repo/domain context)

| Skill | What it does (when to use it) |
|-------|-------------------------------|
| **backend-knowledge-base** | Knowledge base for the JouleTRACK jt-api-v2 backend. |
| **dejoule-knowledge-base** | Organizational knowledge base for DeJoule and Smart Joules. |
| **iot-feedback-handler-knowledge-base** | Knowledge base for the iot-feedback-handler service — an enterprise event-driven TypeScript microservice that consumes IoT device-feedback from Kafka (mode change, recipe, relinquish-control, bulk-ass |
| **iot-knowledge-base** | Knowledge base for the DeJoule IoT platform. |
| **lumen-knowledge-base** | Knowledge base for the Lumen feature — the AI chat assistant for buildings/HVAC in JouleTRACK (Angular frontend) and jt-api-v2 (Sails backend, AWS Bedrock agent + Neptune graph + InfluxDB). |
| **ontology-service-knowledge-base** | Knowledge base for SmartJoules/ontology-service. |
| **sj-k8s-knowledge-base** | SmartJoules/sj-k8s Kubernetes deployment knowledge base. |

## Reference & pattern skills (standards / how-to)

| Skill | What it does (when to use it) |
|-------|-------------------------------|
| **advanced-ai-workflow** | HyperBrain's default high-efficiency AI engineering workflow. |
| **dejoule-coding** | Use when writing, reviewing, planning, or refactoring code that should match DeJoule/SmartJoules engineering style in JouleTRACK and jt-api-v2: small production bug fixes, PR feedback cleanups, |
| **brick** | Use when answering any Brick Schema or ontology-modeling question: whether a class/predicate is valid, what points belong on equipment, how to model a relationship, or how to validate RDF. |
| **bug-postmortem-learning** | Use after a bug, regression, outage, incident, flaky test, production issue, PR fix, hotfix, or debugging session is solved or substantially understood. |
| **cpa-health** | Holistic health audit of CPA (Chiller Plant Automation) and the full IoT stack — sensors, PostgreSQL, CPA runtime, InfluxDB, commands, BMS. |
| **cpa-rca** | Investigate CPA (Chiller Plant Automation) issues at any SmartJoules site. |
| **data-modeling-algorithm** | Use when designing or reviewing database models, entities, tables, collections, DynamoDB keys, GSIs/LSIs, MongoDB schemas, PostgreSQL/MySQL schemas, indexes, relationships, constraints, migrations, te |
| **database-patterns** | Database design patterns and conventions for DeJoule backend development. |
| **dejoule-authentication** | DeJoule/JouleTRACK authentication best-practice guide. |
| **dejoule-geofencing-alerts** | Geofencing and spatial-context alerting guide for DeJoule/SmartJoules. |
| **dejoule-onpremise** | Use when working on SmartJoules/DeJoule on-premise, hybrid cloud-on-prem sync, office-space on-prem repositories, SQS FIFO sync routing, cloud-to-onprem config sync, onprem-to-cloud bridge, MSK-to-IoT |
| **dejoule-rbac** | DeJoule/JouleTRACK RBAC knowledge base and implementation guide. |
| **engineering-standards** | Mandatory engineering standards for writing ANY code. |
| **expert-personas** | Adopt the right expert persona for the task at hand (PM, design engineer, backend/frontend engineer, IoT architect, SRE, QA, technical writer). |
| **go-patterns** | Go backend patterns and conventions for DeJoule services. |
| **graphify-integration** | Transform a codebase into a queryable knowledge graph using AST-based extraction and semantic analysis. |
| **inference-engineering** | Use when designing, building, reviewing, or optimizing production inference systems for LLMs, ML models, RAG, agents, Bedrock/OpenAI/Claude/Qwen providers, streaming chat, structured output, tool call |
| **influxdb-patterns** | InfluxDB time-series patterns and conventions for DeJoule IoT data storage. |
| **iot-architecture** | IoT system architecture patterns for DeJoule products. |
| **iot-health** | Deep IoT infrastructure health diagnosis — controllers, network, firmware, data pipeline, services. |
| **jouletrack-angular** | Angular development patterns and conventions for the JouleTRACK frontend. |
| **jouletrack-library** | Comprehensive development skill library index for the JouleTRACK team. |
| **jouletrack-onboarding** | Team onboarding guide for JouleTRACK development. |
| **kafka-patterns** | Kafka stream-processing patterns and conventions for DeJoule IoT data pipelines. |
| **llm-eval-guardrails** | Evaluate and guard production LLM/AI features. |
| **local-kb** | Generate a local knowledge base for any repository using Graphify to reduce token consumption and provide instant context. |
| **long-term-memory** | Use when deciding what engineering knowledge should persist beyond the current chat or task: durable user preferences, repo conventions, architecture decisions, bug-fix learnings, deployment patterns, |
| **mcp-installer** | One-command installation of all MCP servers from the HyperBrain repository. |
| **mcp-on-demand** | On-demand activation of specialized MCP servers. |
| **mcp-setup** | Set up and configure MCP (Model Context Protocol) servers for AI assistants. |
| **model-selection-runtime** | Use when selecting AI model tiers for Pi.dev, Codex, Claude, tokensmax, custom coding agents, SDK/RPC workflows, or multi-agent fleets. |
| **mqtt-patterns** | MQTT messaging patterns and conventions for DeJoule IoT development. |
| **neptune-graph** | Use when writing, reviewing, fetching, or updating SmartJoules Amazon Neptune RDF/SPARQL graph data for ontology-service: site graphs, equipment, devices, points, controllers, locations, telemetry ref |
| **nextjs-patterns** | Next.js development patterns and conventions for DeJoule web applications. |
| **nodejs-patterns** | Node.js backend patterns and conventions for DeJoule development. |
| **pi-coding-agent** | Use when working with Pi.dev or Pi terminal coding agents: setting up Pi, designing Pi skills, extensions, packages, prompt templates, custom agents, AGENTS.md context loading, compaction, print/JSON/ |
| **playwright-patterns** | End-to-end testing patterns with Playwright for DeJoule applications. |
| **prd-to-html-prototype** | Turn a PRD (product requirements doc, feature spec, or written requirements) into a standalone, self-contained HTML/CSS prototype that follows the JouleTRACK / DeJoule design theme — the dark teal hea |
| **production-safety-guards** | Use before any production, staging, database, graph, Neptune, PostgreSQL, MongoDB, InfluxDB, Redis, Kubernetes, deployment, migration, customer-data, destructive, delete, drop, truncate, update, inser |
| **prompt-engineering** | Systematic prompt engineering for production LLM features. |
| **proto-to-dejoule** | > |
| **python-patterns** | Python backend patterns and conventions for DeJoule development. |
| **qa-automation** | QA automation knowledge base for automated testing. |
| **rag-retrieval** | Production Retrieval-Augmented Generation patterns. |
| **react-patterns** | React development patterns and conventions for DeJoule frontend development. |
| **self-learning** | Continuously capture user preferences, coding style, successful interaction patterns, bug-fix patterns, review feedback, and reusable project knowledge to improve future AI responses. |
| **self-verification** | Use before finalizing any implementation, code review, plan, KB update, architecture decision, deployment manifest, data query, UI change, agent output, or bug fix. |
| **sj-ui-design-system** | > |
| **skill-loading-runtime** | Use when designing or implementing Pi-like skill loading for Codex, Pi.dev, custom coding agents, CLIs, SDK/RPC agents, or orchestration systems. |
| **smartjoules-influxdb** | How to query SmartJoules InfluxDB databases — TSDB (AWS Timestream, raw sensor data) and IoT InfluxDB (processed data). |
| **state-management** | State management patterns for React, Vue, and Angular (Redux, Zustand, Pinia, NgRx). |
| **superpowers-brainstorm** | Advanced brainstorming and planning framework for AI agents. |
| **tdd-workflow** | Use this skill when writing new features, fixing bugs, or refactoring code. |
| **ui-ux-design** | UI/UX design rules and patterns for Angular applications. |
| **vue-patterns** | Vue.js development patterns and conventions for DeJoule frontend development. |
