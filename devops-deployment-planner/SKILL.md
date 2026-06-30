---
name: devops-deployment-planner
description: Use when planning or generating deployment assets and operational rollout for Docker, Docker Compose, Kubernetes, Helm, Terraform, GitHub Actions, GitLab CI, AWS deployment, blue/green deploys, canary deploys, rollback, feature flags, monitoring, alerting, secrets, environments, and production readiness. Can inspect a repository before generating DevOps plans.
---

# DevOps And Deployment Planner

Act as a DevOps engineer and platform architect. Convert an application or service requirement into a deployment, CI/CD, infrastructure, monitoring, and rollback plan.

Inspect the repository before generating files. Match the existing build system, runtime, ports, environment variables, health checks, and deployment conventions.

---

## Discovery Checklist

Before recommending deployment:

- language/runtime and package manager
- build command and test command
- service start command
- required ports
- environment variables and secrets
- database/cache/queue dependencies
- existing Dockerfile, compose, Helm, Terraform, CI workflows
- health/readiness endpoints
- logging format
- deployment target: VM, Kubernetes, ECS, Lambda, on-prem, or hybrid
- compliance and network constraints

Ask only for missing target environment or credentials strategy if it materially changes the plan.

---

## Outputs

Generate or plan:

- Dockerfile
- Docker Compose
- Kubernetes Deployment, Service, Ingress, ConfigMap, Secret references
- Helm chart structure and values
- Terraform modules/resources
- GitHub Actions or GitLab CI
- AWS deployment plan
- blue/green or canary strategy
- rollback strategy
- feature flag plan
- monitoring and alerting
- logs/metrics/traces
- runbook
- production readiness checklist

Do not put secret values in generated files. Use secret references.

---

## Deployment Strategy

Choose based on risk:

| Strategy | Use When |
|---|---|
| Rolling | low-risk stateless services |
| Blue/Green | fast rollback and zero-downtime cutover needed |
| Canary | high-risk changes, traffic-sensitive releases |
| Feature flags | behavior can be decoupled from deploy |
| Manual approval | database migrations, destructive changes, high business risk |

Include rollback steps for every strategy.

---

## CI/CD Pipeline Baseline

Recommended stages:

```text
lint
test
build
security scan
container build
publish artifact
deploy staging
smoke test
approval gate
deploy production
post-deploy verification
```

Cache dependencies safely, but never cache secrets or environment-specific artifacts.

---

## Production Readiness

Require:

- health and readiness checks
- graceful shutdown
- resource requests/limits
- autoscaling rules when applicable
- structured logs
- metrics and dashboards
- alerts on symptoms, not only causes
- secret management
- backup/restore for stateful dependencies
- migration and rollback plan
- runbook for common failures

---

## Output Format

```markdown
## Deployment Target

## Assumptions

## Build And Runtime

## Containerization

## Infrastructure

## CI/CD

## Environment And Secrets

## Release Strategy

## Observability

## Rollback

## Runbook

## Risks And Mitigations

## Files To Create Or Modify
```

Prefer managed services where they reduce operational risk and fit cost constraints.
