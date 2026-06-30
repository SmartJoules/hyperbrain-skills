---
name: agent-planning-harness
description: Use when an AI agent must create an effective execution plan before coding, researching, reviewing, debugging, deploying, or delegating. Provides a reusable planning harness for agents: clarify the goal, retrieve repo/KB context, choose relevant skills, define scope/non-scope, produce workstreams, attach prompt-harness or domain harnesses, create acceptance criteria, allocate agents, define verification gates, risks, stop conditions, and a plan-to-execution handoff.
---

# Agent Planning Harness

**Purpose:** Make every planning agent produce a plan that is executable, grounded, scoped, and verifiable.

Use this before `prompt-harness`, `agent-orchestration`, `engineering-planner`, `software-architecture-planner`, or any implementation agent. The harness is lightweight enough for a single agent and structured enough to hand off to a fleet.

## Planning Loop

1. Restate the user's goal in one sentence.
2. Identify the outcome: code change, research answer, architecture plan, deployment, bug fix, review, KB update, or agent workflow.
3. Retrieve context before planning: `AGENTS.md`, README, package/build metadata, relevant skills, repo KB, graph/local context, targeted `rg`.
4. Select the right harness and skills:
   - Code generation/API/service: `prompt-harness`
   - Large multi-file task: `agentic-engineering`
   - Multi-agent execution: `agent-orchestration`, `agent-fleet-runner`, `agent-delegation-contracts`
   - Skill discovery/loading runtime: `skill-loading-runtime`, `agent-context-manager`
   - Model/tier selection: `model-selection-runtime`, `agent-fleet-runner`
   - Product/engineering plan: `engineering-planner`
   - Architecture/HLD/LLD: `software-architecture-planner`
   - Pi.dev coding-agent / CLI harness: `pi-coding-agent`, `prompt-engineering`, `agent-tool-design`
   - Deployment/K8s: `devops-deployment-planner`, `sj-k8s-knowledge-base`
   - UI/JouleTRACK: `jouletrack-angular`, `sj-ui-design-system`
   - Bug/RCA: `root-cause-analyzer`, `bug-postmortem-learning`
   - Code-signal routing: use the "Top Skills From Code Signals" table in `advanced-ai-workflow`
5. Define scope, non-scope, assumptions, unknowns, and dependencies.
6. Break the work into ordered workstreams with owners or agent roles.
7. Select model tiers per workstream with `model-selection-runtime`.
8. Define acceptance criteria and verification gates before any implementation.
9. Call out risks, stop conditions, and questions that truly block correctness.

## Effective Plan Shape

```markdown
## Goal

## Context Retrieved

## Harness / Skills To Use

## Scope

## Non-Scope

## Assumptions

## Workstreams

## Dependencies And Critical Path

## Agent Allocation

## Acceptance Criteria

## Verification Plan

## Risks And Stop Conditions

## Execution Handoff
```

## Context Packet For The Agent

Every plan should produce a compact execution packet:

```text
Mission:
Repo/root:
Relevant files:
Relevant skills:
Contracts:
Allowed changes:
Forbidden changes:
Verification commands:
Expected output:
Stop conditions:
```

This packet becomes the input for `prompt-harness`, an implementation agent, a review agent, or a fleet worker.

## Plan Quality Rules

- Ground the plan in real repo context. Do not plan from generic memory if files/KB can be inspected.
- Keep the plan actionable: every workstream should have an output and a verification step.
- Prefer contract-first sequencing: API/schema/event/RBAC/ontology/UI state contracts before parallel implementation.
- Separate discovery from implementation. If facts are unknown, add a research task instead of guessing.
- Do not over-plan small one-file changes; use a short checklist and execute.
- Ask the user only when the missing answer changes scope, risk, ownership, or acceptance criteria.
- Attach `self-verification` as the final gate for every plan.

## Agent Harness Rules

When embedding this harness into a planning agent:

- The planning agent owns the plan and the handoff packet, not the full implementation.
- The planning agent must name which specialized harness runs next.
- The planning agent must decide whether to run solo, staged, or fleet execution.
- The planning agent must include stop conditions for destructive actions, production writes, secrets, customer data, or unclear ownership.
- The planning agent must define the final integration/review owner for multi-agent work.

## Done Checklist

- [ ] Goal and outcome are clear
- [ ] Context sources are listed
- [ ] Relevant skills/harnesses are selected
- [ ] Workstreams are sequenced and parallelizable work is identified
- [ ] Acceptance criteria are testable
- [ ] Verification plan exists
- [ ] Risks and stop conditions are explicit
- [ ] Execution handoff packet is ready
