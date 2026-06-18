---
name: figma-file-map
type: guideline
role: design
tags: [design, figma, mcp, source-of-truth]
related:
  - ../README.md
status: draft
owner: design-team
updated: 2026-04-24
source: TBD-Figma-team-library-url
---

# Figma File Map

## Purpose

Map Figma files, pages, libraries, and reusable component sources so AI design workflows can target the correct canvas and reuse approved assets instead of inventing new UI.

## Hybrid source-of-truth rule

- Figma owns visual component implementation, variants, assets, and current canvas state.
- Repo KG owns design usage rules, product semantics, accessibility expectations, pattern guidance, and cross-functional traceability.
- If Figma and KG conflict, stop and ask whether to update Figma, update KG, or create a KG candidate.

## Figma files

| Purpose | Figma URL | Owner | Notes |
|---|---|---|---|
| Product design workspace | TBD | design-team | Main active product screens. |
| Design system / component library | TBD | design-system | Approved components and variants. |
| Exploration / drafts | TBD | design-team | Non-source-of-truth work area. |

## Pages

| File | Page | Use when | Notes |
|---|---|---|---|
| Product design workspace | TBD | Building or revising product screens | Replace TBD with exact page names. |
| Design system / component library | TBD | Inspecting reusable components | Prefer components from this page/library. |

## Component lookup

| KG node | Figma component or set | Required behavior |
|---|---|---|
| `knowledge-graph/design/design-library/apache-echarts-data-visualization.md` | TBD | Reuse approved chart patterns before custom chart design. |
| `knowledge-graph/design/icons/boxicons-icon-library.md` | TBD | Use approved icon library and sizing rules. |
| `knowledge-graph/design/tokens/aura-design-tokens.md` | TBD | Apply approved Aura tokens. |

## Naming conventions

Use stable frame names so agent runs are idempotent:

```txt
<Requirement or Feature> / <Screen> / <State>
```

Examples:

```txt
BL-123 Dashboard / Empty State / Desktop
BL-123 Dashboard / Loaded / Desktop
BL-123 Dashboard / Error / Desktop
```

## Agent guidance

Before editing Figma, the agent should:

1. Read this file.
2. Query KG for matching components, tokens, patterns, personas, and PRD acceptance criteria.
3. Locate the target Figma file/page/frame.
4. Reuse approved components first.
5. Create a KG candidate when an approved pattern or component rule is missing.

## Open questions / known gaps

- Replace TBD Figma URLs and page names.
- Confirm design-system owner.
- Confirm whether tokens are exported from Figma, code, or a separate token pipeline.
