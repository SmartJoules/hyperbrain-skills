---
name: aura-design-tokens
type: design-token
role: design
tags: [design, tokens, aura, theme, ui]
related:
  - ../icons/boxicons-icon-library.md
  - ../design-library/apache-echarts-data-visualization.md
status: active
owner: design-team
updated: 2026-04-24
source: ./aura-tokens.json
---

# Aura Design Tokens

## Purpose
Canonical Aura token set for designing and updating BuildLoop UI. Use these tokens for color, radius, spacing, sizing, shadows, typography-related values, state styling, and component-level theming.

## When to use
- Creating new UI screens, components, dashboards, forms, overlays, navigation, or data displays.
- Updating existing UI so visual decisions stay aligned to the shared design system.
- Handing off design specs to dev and QA.

## Usage guidance
- Prefer semantic tokens over primitive color values in designs and implementation.
- Use primitive tokens only when defining or extending semantic/component tokens.
- Validate light and dark mode behavior before handoff.
- For focus, disabled, invalid, hover, active, selected, overlay, and navigation states, use the provided semantic/component tokens instead of ad-hoc values.
- Keep icons and charts aligned to these tokens for color, surface, emphasis, and state treatment.

## Token source
- Raw token file: [aura-tokens.json](./aura-tokens.json)
- Token sets: aura/primitive, aura/semantic, aura/semantic/light, aura/semantic/dark, aura/component, aura/component/light, aura/component/dark, app
- Themes available: 2
- Total tokens: 3390
- Alias/reference tokens: 2082

## Top-level token groups
- `aura/primitive` — 23 top-level groups
- `aura/semantic` — 11 top-level groups
- `aura/semantic/light` — 10 top-level groups
- `aura/semantic/dark` — 10 top-level groups
- `aura/component` — 82 top-level groups
- `aura/component/light` — 27 top-level groups
- `aura/component/dark` — 28 top-level groups
- `app` — 1 top-level groups

## Token type counts
- `color`: 1824
- `border`: 386
- `spacing`: 360
- `sizing`: 165
- `boxShadow`: 163
- `borderRadius`: 158
- `borderWidth`: 143
- `other`: 107
- `fontSizes`: 42
- `fontWeights`: 34
- `lineHeights`: 4
- `number`: 3
- `opacity`: 1

## Related work
- [Boxicons Icon Library](../icons/boxicons-icon-library.md)
- [Apache ECharts Data Visualization](../design-library/apache-echarts-data-visualization.md)

## Open questions / known gaps
- Source Figma token library link should be added when available.
- Governance for changing primitive vs semantic vs component tokens should be documented.
