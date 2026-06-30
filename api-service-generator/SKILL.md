---
name: api-service-generator
description: Use when generating or planning CRUD APIs, authentication APIs, report APIs, service modules, entities, DTOs, repositories, services, controllers, validation, Swagger/OpenAPI, tests, error handling, logging, and backend API contracts. Supports Spring Boot, Node.js, Go, and .NET. Acts as backend API and service generator.
---

# API And Service Generator

Act as a backend developer generating production-ready API/service modules that fit the existing repository.

Use this skill for concrete API/service generation. For higher-level module planning, use `backend-implementation-planner` first. For actual code edits, inspect repo patterns before writing.

---

## Generation Workflow

1. Detect framework, language, routing style, ORM/data access, validation, tests, and OpenAPI conventions.
2. Inspect nearby existing endpoints and mirror their style.
3. Define API contract before implementation.
4. Generate entities/models, DTOs, validation, repository/model access, service logic, controller/handler, tests, and docs.
5. Include error handling, logging, metrics hooks, authorization checks, and pagination/filtering/sorting when relevant.
6. Review generated code against `engineering-standards`.

Do not invent a new framework structure inside an existing repo.

---

## CRUD Output Checklist

For CRUD APIs, include:

- entity/model
- create/update/read/list/delete DTOs
- validation schema or annotations
- repository/model query functions
- service methods
- controller/handler routes
- authorization policy hooks
- pagination and filtering for list endpoints
- consistent error response envelope
- OpenAPI/Swagger docs
- unit tests
- integration tests
- migration if schema changes

Use soft delete only when product/audit requirements justify it.

---

## Authentication/API Security

For auth APIs, include:

- login/logout/refresh flow
- password hashing or external identity provider integration
- MFA/OTP when required
- token/session revocation
- rate limiting and abuse detection
- audit logging
- generic error messages for auth failures
- secure cookie or bearer-token handling per platform

Never log passwords, OTPs, tokens, private keys, or secrets.

---

## API Contract Template

```markdown
## Endpoint
<METHOD> /path

## Purpose

## Auth

## Request

## Response

## Validation

## Errors

## Pagination/Filtering/Sorting

## Side Effects

## Tests
```

---

## Error Response Baseline

Use the existing repo convention. If none exists:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request",
    "details": []
  },
  "requestId": "..."
}
```

---

## Quality Rules

- Keep controllers thin and services testable.
- Validate and authorize before writes.
- Use parameterized queries or ORM-safe APIs.
- Make create/update idempotent where retries are possible.
- Add pagination to list endpoints.
- Add audit fields when the domain needs traceability.
- Add tests for success, validation failure, auth failure, not found, conflict, and server error paths.
