---
name: mockup-to-requirements-anti-patterns
type: guideline
role: design
tags: [design, pm, dev, requirements, handoff]
related:
  - ../../../templates/prd-template/prd.md
  - ../../../templates/design/understanding.md
  - ../../../templates/design/verification.md
status: active
owner: design-dev-team
updated: 2026-04-24
source: design-and-dev-team-feedback
---

# Mockup-to-Requirements Anti-patterns

## Purpose

Prevent teams and agents from turning visual mockups into shallow or over-prescriptive requirements. Mockups are evidence of product intent, not the requirement itself.

Use this guideline whenever a PM, designer, developer, or agent converts a design, Figma frame, screenshot, prototype, or UI idea into a PRD, design brief, dev handoff, or QA plan.

## Anti-patterns to avoid

### 1. Describing pixels, not intent

Do not narrate UI elements literally, such as “there is a blue button.” Extract the product purpose instead:

- What action does this enable?
- Why does it exist?
- What user decision or outcome does it support?

A visual attribute is only requirement-worthy when it carries semantic meaning, communicates status, supports accessibility, or reflects a brand/system rule.

### 2. Skipping edge cases

Mockups usually show happy paths. A good requirement must infer and document non-happy paths even when not shown:

- Empty states
- Error states
- Loading states
- Disabled/unavailable states
- Permission/role restrictions
- Offline/network failures where relevant
- Success/confirmation states

### 3. Conflating design with requirements

The mockup’s font, color, spacing, animation, or layout is not automatically a product requirement. Treat visual details as design implementation unless they communicate a required behavior, state, hierarchy, brand rule, or accessibility constraint.

### 4. No user context

Requirements without a clear user are hollow specs. Always identify:

- Who the user is
- What they are trying to accomplish
- Their context or entry point
- What success looks like

### 5. Missing acceptance criteria

A PRD without testable acceptance criteria is only a description. Each requirement should include criteria that QA and engineering can verify.

Good acceptance criteria are observable, testable, and tied to user/business outcomes.

### 6. Over-specifying implementation

PRDs should state what the product must do and why. Avoid leaking technical decisions from mockup assumptions, such as specific frameworks, database structures, component internals, or algorithm details unless they are true constraints.

Move implementation decisions to architecture notes, ADRs, or dev tasks.

## Review checklist

Before marking a PRD, design brief, or handoff ready, confirm:

- [ ] It explains user intent, not just visible UI.
- [ ] User/persona and scenario are clear.
- [ ] Empty, error, loading, disabled, success, and responsive states are considered.
- [ ] Visual details are separated from actual requirements.
- [ ] Acceptance criteria are testable.
- [ ] Implementation details are not over-specified in the PRD.
- [ ] Technical constraints are labeled as constraints, not inferred from the mockup.

## Related artifacts

- PRD template: `templates/prd-template/prd.md`
- Design understanding template: `templates/design/understanding.md`
- Design verification template: `templates/design/verification.md`
- Design-to-dev handoff template: `templates/design/design-to-dev-handoff.md`

## Open questions / known gaps

- None.
