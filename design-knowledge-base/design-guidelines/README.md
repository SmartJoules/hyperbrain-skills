# Design Knowledge Graph Instructions

Use this folder for reusable design knowledge that should be discoverable by PM, design, dev, and QA teams. Add only knowledge that is stable enough to be reused across requirements or product areas.

## Hybrid Figma + KG source-of-truth model

- **Figma owns** visual component implementation, variants, assets, and current canvas state.
- **Repo KG owns** usage rules, product meaning, design principles, accessibility expectations, pattern guidance, and cross-functional traceability.
- **Agents should reuse Figma components first**, then consult this KG for when/how/why to use them.
- If Figma and KG conflict, stop and ask whether Figma, KG, or both should be updated.
- New reusable findings should be written as KG candidates first, then promoted through review.

## Bare minimum required information

Every design knowledge entry must include:

1. **Name** — clear, searchable title for the design concept, pattern, token set, component, flow, or guideline.
2. **Type** — one of: `design-pattern`, `component`, `design-token`, `icon`, `flow`, `research-insight`, `guideline`, or `decision`.
3. **Owner** — accountable designer or team.
4. **Status** — `draft`, `active`, `deprecated`, or `superseded`.
5. **Last updated date** — use `YYYY-MM-DD`.
6. **Source artifact link** — Figma, FigJam, research doc, prototype, asset library, or decision record.
7. **Purpose** — what problem this knowledge solves and when to use it.
8. **Usage guidance** — basic do/don't rules, states, variants, accessibility expectations, and responsive behavior where relevant.
9. **Related work** — links to related requirements, PRDs, user flows, components, decisions, or other KG nodes.
10. **Open questions or known gaps** — anything not yet resolved that could affect implementation or QA.

## Recommended file format

Create one markdown file per reusable item:

```yaml
---
name: <clear-name>
type: <design-pattern|component|design-token|icon|flow|research-insight|guideline|decision>
role: design
tags: [design]
related: []
status: <draft|active|deprecated|superseded>
owner: <designer-or-team>
updated: <YYYY-MM-DD>
source: <figma-or-doc-url>
---
```

```md
# <Name>

## Purpose
<What this is and why it exists.>

## When to use
<Where this applies.>

## Usage guidance
- Do: <minimum rule>
- Don't: <minimum rule>
- Accessibility: <keyboard, contrast, labels, motion, etc.>
- Responsive behavior: <desktop/tablet/mobile expectations if applicable>

## Source artifacts
- <Figma/prototype/research/link>

## Related work
- <Requirement, PRD, component, or KG node link>

## Open questions / known gaps
- <Question or gap, or "None">
```

## Quality bar

A design KG entry is acceptable when another designer, developer, or QA engineer can answer:

- What is this?
- When should it be used?
- Where is the source of truth?
- Who owns it?
- What constraints matter for implementation and testing?
