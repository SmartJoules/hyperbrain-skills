---
name: long-term-memory
description: Use when deciding what engineering knowledge should persist beyond the current chat or task: durable user preferences, repo conventions, architecture decisions, bug-fix learnings, deployment patterns, API contracts, ontology/query recipes, review feedback, and recurring workflows. Guides what to save, where to save it, how to ask the user before storing sensitive or durable memory, and how to retrieve memory before planning future work.
---

# Long-Term Memory

**Purpose:** Keep HyperBrain useful across months, repos, and repeated work by saving durable knowledge without turning memory into a junk drawer.

Use with `self-learning` for automatic pattern capture, `bug-postmortem-learning` for solved bugs, `agent-context-manager` for context packets, and repo KB skills for durable project facts.

## What To Remember

Save only knowledge likely to help future work:

- User preferences: coding style, PR style, risk tolerance, preferred workflows, naming conventions.
- Repo conventions: folder structure, service patterns, UI component rules, deployment shape, test commands.
- Architecture decisions: ADRs, API contracts, DB schemas, event topics, ontology classes, RBAC policy patterns.
- Reusable fixes: root cause, fix recipe, detection signals, regression test, prevention checklist.
- Operational runbooks: deploy/rollback, debugging commands, monitoring dashboards, incident checks.
- Agent workflows: successful delegation patterns, context packets, verification gates, review checklists.

## What Not To Remember

Do not store:

- Secrets, tokens, passwords, private keys, API keys, webhook URLs, session cookies, or credentials.
- Raw customer data, PII, free-text user content, logs with sensitive identifiers, or copied production payloads.
- One-off guesses, unverified hypotheses, temporary stack traces, or stale workarounds.
- Personal information unless the user explicitly wants it remembered and it is useful for future work.

## Memory Destinations

Choose the smallest durable place:

- Repo-local KB: `ai-context/*.md`, `BUG_KB.md`, `GRAPH_REPORT.md`, or project docs when present.
- HyperBrain skill: when the rule is broadly reusable across SmartJoules/DeJoule projects.
- Domain KB skill: `sj-k8s-knowledge-base`, `ontology-service-knowledge-base`, `dejoule-rbac`, `jouletrack-angular`, `atif-coding-style`, etc.
- User memory: only for stable user/team preferences and with consent when sensitive.

## Save Protocol

1. Identify the durable fact or pattern.
2. Check if an existing KB/location already owns that knowledge.
3. Remove secrets, PII, raw logs, and noisy details.
4. Ask the user before saving anything durable that came from a private session, incident, or solved bug.
5. Save a concise entry with source, date, scope, confidence, and verification.
6. Link or mention the saved location in the final answer.

Ask like this:

```text
Should I save this as long-term memory?
Proposed location: <path or KB>
It will include: <durable facts>
It will not include: secrets, PII, raw logs, or credentials.
```

## Memory Entry Shape

```markdown
## <Pattern or Decision Title>

- **Date:** YYYY-MM-DD
- **Scope:** <repo/service/domain>
- **Source:** <PR/commit/session/incident/doc if available>
- **Decision / Pattern:** <durable rule>
- **Why it matters:** <future benefit>
- **How to apply:** <short recipe>
- **Verification:** <test/query/build/review evidence>
- **Do not do:** <anti-patterns>
```

## Retrieval Protocol

Before planning non-trivial work:

1. Read `AGENTS.md`, README, package/build metadata.
2. Search repo-local KB and relevant HyperBrain skills.
3. Look for prior bug patterns, deployment patterns, API contracts, RBAC rules, ontology recipes, and UI standards.
4. Prefer saved verified facts over memory from the model.
5. If memory conflicts with live repo state, trust the repo and update memory after verification.

## Quality Bar

Memory is useful only if it is accurate, concise, retrievable, and safe. If a fact cannot pass that bar, keep it in the final answer but do not persist it.
