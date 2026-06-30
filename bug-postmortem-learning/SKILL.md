---
name: bug-postmortem-learning
description: Use after a bug, regression, outage, incident, flaky test, production issue, PR fix, hotfix, or debugging session is solved or substantially understood. Produces a blameless bug postmortem, extracts reusable fix patterns, asks the user whether to ingest the learning into the appropriate repo/project knowledge base, and creates concise KB entries, runbook updates, regression-test ideas, and future debugging playbooks.
---

# Bug Postmortem Learning

**Purpose:** Convert every solved bug into future speed: a clear postmortem, a verified prevention plan, and an optional KB entry that helps the next agent solve the same class of issue faster.

Use with `root-cause-analyzer` for investigation, `code-reviewer` for fix quality, `tdd-workflow` for regression tests, `self-learning` for persistent user/team preferences, and repo KB skills for storage.

## Trigger Moments

Run this skill when:

- The user says the bug is fixed, solved, patched, hotfixed, or understood.
- A debugging session ends with a root cause or workaround.
- A PR fixes a regression, flaky test, production alert, UI bug, API failure, query issue, RBAC/auth bug, ontology bug, or integration issue.
- An RCA has enough evidence to produce reusable prevention.

Do not ingest anything automatically. Always ask the user before saving durable KB.

## Postmortem Workflow

1. Capture the bug summary: symptom, scope, environment, repo, service/module, timeline, and user impact.
2. Identify the root cause and contributing factors with evidence.
3. Record the fix: files changed, behavior changed, config/query/schema changed, and why it works.
4. Verify the fix: tests, build, logs, query checks, browser QA, metrics, or manual reproduction.
5. Define prevention: regression tests, monitoring, alerting, guardrails, code review checklist, runbook updates.
6. Extract reusable learning: bug pattern, detection signals, fix recipe, anti-pattern, and faster future debug path.
7. Ask the user whether to ingest the learning into KB.
8. If approved, write a concise KB entry in the right repo/project location and reference it in the final answer.

## Postmortem Output

```markdown
## Bug Postmortem

### Summary

### Impact

### Timeline

### Root Cause
Confidence:

### Contributing Factors

### Fix Implemented

### Verification

### Regression Test / Prevention

### Reusable Learning

### KB Ingestion Proposal
Recommended location:
Entry title:
Why this should be saved:
```

Keep it blameless. Focus on systems, assumptions, missing tests, missing observability, and unclear contracts.

## Ask Before Ingesting

Before writing to KB, ask a short confirmation:

```text
Should I save this bug learning into the repo KB?
Proposed entry: <title>
Location: <path or KB target>
It will include: root cause, fix recipe, detection signals, regression test idea, prevention checklist.
```

If the user says no, do not write. If the user says yes, create or update the narrowest relevant KB artifact.

## Where to Save

Choose the most local durable place:

- Repo `ai-context/BUG_PATTERNS.md` when present
- Repo `graphify-out` or local KB notes when that is the active project convention
- Existing skill/KB folder when the learning is broadly reusable across HyperBrain
- Domain KB for DeJoule patterns: `backend-knowledge-base`, `jouletrack-angular`, `dejoule-rbac`, `dejoule-authentication`, `neptune-graph`, `ontology-service-knowledge-base`, `dejoule-geofencing-alerts`, or `dejoule-onpremise`
- A new `BUG_KB.md` only when no project KB exists and the user approved durable storage

Prefer appending a short structured entry over creating many new files.

## KB Entry Shape

```markdown
## <Bug Pattern Title>

- **Date:** YYYY-MM-DD
- **Repo/Area:** <repo/module/service>
- **Symptom:** <what users/devs saw>
- **Root cause:** <direct cause>
- **Fix recipe:** <minimal reliable fix>
- **Detection signals:** <logs/tests/metrics/UI symptoms>
- **Regression guard:** <test/check/monitoring>
- **Prevention:** <review rule/design guardrail>
- **Related files:** <paths or symbols>
- **Source:** <PR/commit/session/incident if available>
```

## Learning Extraction Rules

Save only durable patterns:

- A repeated code smell, missing contract, or fragile integration point
- A query/schema/cache/auth/RBAC/ontology/API/UI pattern likely to recur
- A test fixture, reproduction path, or log signature that speeds diagnosis
- A review checklist item that would have caught the bug
- A runbook step that turns a future incident into a quick fix

Do not save one-off noise, secrets, customer data, temporary stack traces, or unverified guesses.

## Follow-Up Questions

Ask only what is needed to make the KB entry accurate:

- "What was the final root cause?"
- "Which commit or PR fixed it?"
- "How did you verify the fix?"
- "Should this become a regression test, runbook note, or code-review checklist item?"
- "May I save this learning to `<location>`?"

## Done Checklist

- [ ] Postmortem has root cause, evidence, fix, verification, and prevention
- [ ] Reusable learning is separated from incident noise
- [ ] User approved KB ingestion before any durable write
- [ ] KB entry is concise and stored in the most relevant place
- [ ] Final answer mentions the saved location or says the user declined ingestion
