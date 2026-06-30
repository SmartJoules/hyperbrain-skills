---
name: agent-context-manager
description: Use when preparing, compressing, routing, refreshing, or auditing context for multiple AI agents: creating minimal context packets, managing token budgets, preventing context leakage, sharing repo instructions, splitting code/schema/log evidence, summarizing worker outputs, and maintaining orchestration state across multi-agent runs.
---

# Agent Context Manager

**Purpose:** Keep multi-agent work accurate and cheap by giving every agent enough context to succeed, and nothing extra.

## Context Packet

Every agent gets a compact packet:

```text
Goal:
Why this agent:
Repo/root:
Branch/worktree:
Relevant instructions:
Files/symbols to inspect:
Known contracts:
Evidence already collected:
Out of scope:
Allowed tools:
Return format:
```

## Retrieval Order

Use the cheapest reliable context first:

1. User request, latest decisions, and acceptance criteria
2. `AGENTS.md`, README, package/build metadata
3. Existing skills and KB: domain, repo, RBAC, ontology, frontend/backend
4. Graph/local context such as `graphify-out`, `ai-context`, docs, diagrams
5. Targeted `rg` searches and symbol windows
6. Full-file reads only for files the agent will likely change

## Context Budget Rules

- Keep each packet focused on one workstream.
- Prefer paths, symbols, contracts, and search terms over copied source.
- Include exact file snippets only when the agent cannot discover them safely.
- Remove old context when a phase ends; preserve only decisions and contracts.
- Share cross-agent decisions through the orchestrator, not by copying every transcript.

## Prevent Context Leakage

- Do not leak another agent's tentative answer into a cross-check agent unless the task is explicitly comparison.
- Do not include secrets, tokens, private customer data, or credentials in prompts.
- Do not pass production query results unless needed and safe to share.
- For security/review agents, pass the diff and requirements, not the intended approval.

## Orchestrator State

Maintain only:

```text
Goal:
Agent roster:
Contract decisions:
Assignment status:
Files owned:
Open risks:
Verification status:
Final handoff notes:
```

## Result Compression

After each agent returns, compress the result to:

- What changed or was learned
- Evidence references
- Contract decisions
- Files touched
- Verification run
- Risks and open questions

Discard raw logs and long file dumps after extracting the durable facts.

## Refresh Points

Refresh context after planning, after architecture, before write work, before review, and before final verification. If an agent is blocked, provide a narrower packet instead of adding more broad context.
