---
name: pi-coding-agent
description: Use when working with Pi.dev or Pi terminal coding agents: setting up Pi, designing Pi skills, extensions, packages, prompt templates, custom agents, AGENTS.md context loading, compaction, print/JSON/RPC/SDK automation modes, or embedding HyperBrain planning, memory, orchestration, verification, and repo-aware workflows into a Pi-based coding agent.
---

# Pi Coding Agent

**Source:** Pi.dev and Pi documentation, checked 2026-06-30.

Use Pi as a lean terminal-first coding-agent runtime. Treat HyperBrain as the opinionated workflow layer that gives Pi stronger planning, repo memory, delegation, verification, and domain-specific engineering behavior.

## Capability Map

- **Skills:** Store reusable instructions for repeated engineering workflows. Convert HyperBrain skills into Pi skills when they need to be portable in a Pi environment.
- **Extensions and packages:** Add capabilities around the agent instead of bloating prompts. Prefer packages for reusable tools and integrations.
- **Prompt templates:** Capture repeatable prompts for planning, debugging, review, migration, codegen, and verification.
- **Modes:** Use interactive mode for exploration, print mode for one-shot scripted work, JSON/RPC/SDK modes for automation, CI, internal tools, and multi-agent orchestration.
- **AGENTS.md context:** Load repository instructions first, then add the minimum relevant skill context.
- **Compaction:** Preserve decisions, constraints, changed files, verification status, blockers, and next actions.

For exact commands and flags, check the installed Pi version with `pi --help` or the current Pi docs before automating. Pi is intentionally extensible, so do not hardcode stale CLI assumptions.

## Default HyperBrain Stack For Pi

Start non-trivial Pi work with this stack:

1. `skill-loading-runtime` to scan skill metadata first, rank skills, and load only selected instructions/resources.
2. `agent-planning-harness` for goal, scope, workstreams, risks, and verification gates.
3. `advanced-ai-workflow` for the default execution loop.
4. `prompt-harness` for repo-aware code generation.
5. `self-verification` before final answers, commits, or deployments.
6. `long-term-memory` and `self-learning` when the work produces reusable knowledge.

Add these only when the task needs them:

- Multi-agent execution: `agent-orchestration`, `agent-fleet-runner`, `agent-context-manager`, `agent-delegation-contracts`.
- DeJoule frontend: `jouletrack-angular`, `sj-ui-design-system`, `frontend-telemetry`.
- Backend/API work: `api-design`, `backend-patterns`, `dejoule-rbac`, `authentication-best-practices`.
- Ontology/graph work: `ontology-service-knowledge-base`, `brick-ontology-neptune-jena`.
- Deployments: `sj-k8s-knowledge-base`, `deployment-patterns`.
- Bug learning: `bug-postmortem-learning`, `systematic-debugging`.

## Pi Planning Harness

When a user asks Pi to build, fix, review, or research:

1. Read `AGENTS.md`, repo README, package/build files, and the target files.
2. Use `skill-loading-runtime` to scan all skill frontmatter, rank matches, and load only the smallest useful HyperBrain skill set.
3. Classify the task with `advanced-ai-workflow`.
4. Produce an execution plan with acceptance criteria and verification gates.
5. Run the task through Pi, keeping tool calls and file edits tightly scoped.
6. Verify with tests, build checks, static checks, or targeted inspection.
7. Summarize changed files, verification, risks, and memory updates.

## Prompt Template Pattern

Use this shape for Pi prompt templates:

```text
You are running inside Pi for <repo or service>.

Goal:
- <user outcome>

Context to load:
- AGENTS.md
- README/package/build metadata
- Relevant HyperBrain skills: <skill names>
- Relevant repo KB: <kb names>

Plan requirements:
- Define scope and non-scope.
- Name workstreams, dependencies, and verification gates.
- Ask only when blocked by missing facts or risky assumptions.

Execution requirements:
- Follow repo style.
- Keep edits minimal and file-scoped.
- Preserve unrelated user changes.
- Verify before final response.

Final response:
- Changed files
- Tests/checks run
- Risks or follow-ups
```

## Automation Modes

- **Print mode:** Batch small fixes, documentation generation, or code review summaries.
- **JSON mode:** Integrate with dashboards, issue generators, CI checks, or evaluation harnesses.
- **RPC/SDK mode:** Build internal agent tools that allocate tasks, route context, and collect results.
- **Interactive mode:** Use for ambiguous tasks, deep debugging, architecture planning, or work that may need user judgment.

## Skill Porting Rules

When converting a HyperBrain skill into a Pi skill:

- Keep the trigger and workflow in the main skill file.
- Move long KB, schemas, examples, or tool references into separate reference files.
- Preserve exact repo conventions, commands, and verification steps.
- Include an output contract so Pi results can be consumed by humans or orchestrators.
- Avoid secrets, production credentials, and customer data in skill files or prompt templates.

## Done Checklist

- Pi-specific work uses current Pi docs or local `pi --help` for exact commands.
- The chosen HyperBrain stack is named explicitly.
- The plan includes scope, risks, verification, and stop conditions.
- Outputs are machine-readable when used by JSON/RPC/SDK integrations.
- Reusable bug fixes or domain discoveries are routed into `bug-postmortem-learning`, `long-term-memory`, or the relevant repo KB.
