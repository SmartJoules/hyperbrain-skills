---
name: backend-implementation-planner
description: Use when planning backend implementation for a module, service, API, CRUD flow, report scheduler, worker, cron job, queue, email flow, or data workflow. Produces folder structure, controllers, services, repositories, DTOs, validation, entities/models, workers, cron, Redis/queue usage, Swagger/OpenAPI, tests, deployment notes, and framework-specific implementation steps for Spring Boot, Node.js, Go, and .NET. Acts as Staff Backend Engineer.
---

# Backend Implementation Planner

Act as a Staff Backend Engineer. Convert a backend requirement into a concrete implementation blueprint that fits the target repo and framework.

This skill plans implementation. If the user asks to actually edit code, use this plan to guide the edits and also apply `engineering-standards`, `prompt-harness`, and framework-specific skills.

---

## Discovery First

Before proposing structure:

1. Inspect the repo structure and framework.
2. Identify existing controller/service/repository/model patterns.
3. Inspect database schema or connector context when available.
4. Locate existing auth, validation, error handling, logging, tests, Swagger/OpenAPI, queues, cron, and worker conventions.
5. Reuse existing patterns instead of introducing textbook architecture.

Ask only when a business rule or contract cannot be inferred.

---

## Supported Stacks

| Stack | Generate plans using |
|---|---|
| Spring Boot | controller, service, repository, DTO, entity, mapper, validator, scheduled task, async worker, OpenAPI, JUnit |
| Node.js | route/controller, service, repository/model, DTO/schema, middleware, worker, cron, queue, OpenAPI, Jest/Mocha |
| Go | handler, service, repository, domain model, validator, worker, cron, OpenAPI, table tests |
| .NET | controller, service, repository, DTO, entity, hosted service, background job, Swagger, xUnit/NUnit |

For DeJoule `jt-api-v2`, use Sails/Waterline idioms: `api/controllers`, `api/services`, `api/models`, `config/routes.js`, `config/policies.js`; do not introduce a foreign ORM or unrelated framework pattern.

---

## Planning Checklist

For a module such as "report scheduling", produce:

- domain model and data ownership
- folder/file structure
- controller/API endpoints
- request and response DTOs
- validation rules
- service methods and business flow
- repository/model queries
- transactions and idempotency
- worker/cron/queue design
- Redis/cache needs with TTL/eviction
- email/notification integration
- error handling and retry strategy
- logging, metrics, tracing
- Swagger/OpenAPI contract
- unit, integration, contract, and e2e tests
- migration and deployment notes
- rollout and rollback plan

---

## Output Template

```markdown
## Requirement Understanding

## Existing Project Context

## Proposed Backend Design

## Folder Structure

## API Contract

## Data Model

## Service Flow

## Worker/Cron/Queue Design

## Validation And Error Handling

## Security And Authorization

## Observability

## Tests

## Deployment Notes

## Task Breakdown

## Risks And Mitigations
```

---

## Quality Rules

- Keep controllers thin.
- Put business rules in services.
- Keep data access behind existing model/repository conventions.
- Validate at API boundaries.
- Use transactions for multi-write consistency.
- Make background jobs idempotent.
- Bound retries and queues.
- Avoid unbounded Redis keys and caches.
- Include authorization checks in the backend, not only UI.
- Include tests for success, validation failure, auth failure, not found, conflict, and retry/error paths.
