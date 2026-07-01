---
name: llm-wiki
description: Use when creating, maintaining, or querying an LLM-maintained markdown wiki or compounding knowledge base from raw sources, inspired by Karpathy's LLM Wiki pattern. Applies to personal, research, product, engineering, DeJoule KB, repo onboarding, postmortem, design-doc, and source-ingestion workflows where knowledge should be integrated into durable interlinked pages instead of rediscovered from raw files each time.
---

# LLM Wiki

Use this skill to turn raw sources and conversations into a persistent, interlinked markdown wiki that compounds over time.

Source inspiration: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f

## Core Pattern

Maintain three layers:

1. `raw/`: immutable source material. Do not edit raw sources.
2. `wiki/`: LLM-maintained markdown pages: summaries, entity pages, topic pages, decisions, comparisons, synthesis, and runbooks.
3. `AGENTS.md` or schema doc: rules for page format, naming, frontmatter, links, ingestion, querying, and linting.

The wiki is not only retrieval. It is a compiled knowledge artifact. When new material arrives, integrate it into existing pages, update links, record contradictions, and keep a chronological log.

## Directory Template

```text
kb/
  AGENTS.md
  raw/
  wiki/
    index.md
    log.md
    entities/
    concepts/
    sources/
    decisions/
    runbooks/
```

Adapt the taxonomy to the domain. For DeJoule engineering KBs, prefer pages such as `repos/`, `services/`, `stores/`, `apis/`, `workflows/`, `incidents/`, and `patterns/`.

## Ingest Workflow

For every new source:

1. Identify source type, owner, date, reliability, and scope.
2. Read the source once with a clear extraction goal.
3. Create or update a source summary page.
4. Update relevant entity, concept, repo, service, decision, and runbook pages.
5. Add cross-links between related pages.
6. Flag contradictions, stale claims, missing evidence, and open questions.
7. Update `wiki/index.md`.
8. Append an entry to `wiki/log.md`.
9. Ask before saving sensitive, customer, credential, or personal information.

## Query Workflow

When answering questions:

1. Read `wiki/index.md` first.
2. Search targeted wiki pages before raw sources.
3. Read raw sources only when the wiki is missing, stale, contradictory, or needs citation verification.
4. Answer with links to wiki pages and source pages.
5. If the answer creates reusable synthesis, ask whether to save it as a new or updated wiki page.

## Lint Workflow

Periodically audit the wiki:

- orphan pages
- missing inbound links
- duplicate pages
- stale claims
- contradictions
- missing source summaries
- concepts mentioned often but lacking a page
- pages without owner/date/source metadata
- raw sources that were never ingested
- decisions without rationale or rollback notes

Write fixes directly only when the user has approved the KB update policy. Otherwise propose a patch plan first.

## Page Conventions

Use short markdown pages with stable links.

Recommended frontmatter:

```yaml
---
type: concept | entity | source | decision | runbook | incident | repo | service
status: draft | reviewed | stale
updated: YYYY-MM-DD
sources:
  - raw/path-or-url
---
```

Each page should include:

- One-sentence summary
- Key facts
- Links to related pages
- Source references
- Open questions
- Last-updated note

## Safety

- Never store secrets, API keys, private credentials, or customer-identifying data in the wiki.
- Use redaction for logs, incident notes, tickets, and screenshots.
- Keep raw source provenance so claims can be checked later.
- For repo KBs, prefer facts that survive across sessions: architecture, contracts, invariants, workflows, and learned fix patterns.

## Good Prompt

```text
Use llm-wiki, local-kb, self-learning, and long-term-memory.

Create or update a markdown wiki for this repo/source set.

Raw sources:
<paths or links>

Goals:
- integrate sources into durable wiki pages
- update index and log
- cross-link repos, services, stores, APIs, incidents, and decisions
- flag contradictions and missing evidence
- ask before saving sensitive or uncertain learnings
```
