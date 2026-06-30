---
name: design-doc-harness
description: End-to-end design-doc process used by top product companies (Google/Amazon/Meta-style). Use when starting, authoring, running, or standardizing a design doc / RFC / tech spec / ADR — to get the right TEMPLATE to write from, the lifecycle (Draft → human review → automated review → approval → implementation), the roles (author/reviewers/approver), the doc tier (RFC vs lightweight ADR), and how it plugs into the CI gate and the design-doc-review-agent. Use whenever someone says "write a design doc / start an RFC / what's our design-doc process / set up design docs for this repo".
---

# Design Doc Harness (FAANG-style authoring → approval pipeline)

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** The full design-doc process + a ready-to-fill template, the way top product orgs run it
**Version:** 1.0.0

---

## 🎯 When to Use

Starting or standardizing a design doc/RFC/spec/ADR — to get the template, the stages, the roles, and the gates. This is the **authoring + process** side; the **review** side is [[design-doc-review-agent]] (rich review) + [[design-doc-reviewer]] (rules) + the CI lint gate. Composes [[software-architecture-planner]] (turn requirements into the design), [[superpowers-brainstorm]] (frame the problem first), [[engineering-standards]] (the constraints), and [[agentic-engineering]] (for large efforts).

> The doc exists to **drive a decision and de-risk the build**, not to be a deliverable. Tight, decision-first, ≤15 pages. If it's not making a decision clearer, cut it (KISS).

---

## 🧭 Pick the doc tier (don't over-process small changes)

| Tier | Use when | Shape | Approver |
|------|----------|-------|----------|
| **One-pager / ADR** | A single decision, small/local change | Context · Decision · Alternatives · Consequences (lightweight template) | Tech lead |
| **RFC / Design Doc** | A feature/system, cross-team or non-trivial blast radius | Full template (below) | Owning tech lead + impacted-area reviewers |
| **Architecture Doc** | New service, major re-architecture, multi-repo | Full template + deeper alternatives/rollout/cost; pairs with [[software-architecture-planner]] | Principal/architect + leads |

Scale rigor to the change. A 200-line feature does not need an architecture doc.

---

## 🔄 Lifecycle (the pipeline)

```
0. Frame      — problem & goals clear before writing (superpowers-brainstorm)
1. Draft      — author writes from the TEMPLATE; status: Draft
2. Self-check — author runs the CI lint locally (sections, ≤15pp, no secrets); fixes blockers
3. Human review — named reviewers comment; author iterates; status: In-Review
4. Human APPROVAL — a human approver signs off; status: Approved   ◀── REQUIRED before step 5
5. Automated review — design-doc-review-agent (+ CI gate) verifies correctness, repo-alignment,
                      FAANG-standard; REJECT/APPROVE-WITH-CHANGES/APPROVE
6. Decision   — Approved doc is the source of truth; record the decision + date
7. Implement  — build to the doc; deviations update the doc (it's living until shipped)
8. Archive    — mark Implemented/Superseded; link the PRs
```

**Order matters:** humans review and approve **first**; the automated reviewer is a *second* gate, not the first (it rejects un-approved docs). This mirrors how product orgs run it — people own the decision, automation enforces the bar.

**Gates (a doc cannot advance until):**
- → step 3: passes self lint (required sections, ≤15 pages, no hardcoded secrets/site-ids).
- → step 5: carries a human-approval signal (`Status: Approved` / `Reviewed by <name>`).
- → step 7: automated review verdict is APPROVE (or APPROVE-WITH-CHANGES with the changes made).

---

## 👥 Roles

- **Author** — writes the doc, drives it to a decision, keeps it current during implementation.
- **Reviewers** — named humans from impacted areas (frontend/backend/IoT/security/SRE as relevant); leave actionable comments. Use [[expert-personas]] to cover perspectives.
- **Approver** — a human (tech lead / principal) who signs off; their approval is the gate before automated review.
- **Automated reviewer** — [[design-doc-review-agent]] / CI gate: enforces structure, constraints, repo-alignment, FAANG-standard.

---

## 📐 What a good doc contains (FAANG-style)

Decision-first, prose over bullet-soup (Amazon narrative style), honest about uncertainty:
- **Context & problem** framed before any solution — why now, what breaks without it, who's affected.
- **Goals & Non-Goals** — measurable goals; non-goals bound scope.
- **Proposed design WITH rationale** — the approach and *why*; diagrams for non-trivial flows; key decisions justified.
- **Alternatives considered** — ≥2 real options with pros/cons and *why rejected*.
- **Cross-cutting concerns** sized to the change — scalability, failure modes/reliability, security & privacy, data model/migration, observability, cost, rollout + rollback.
- **Testing & validation**, **risks & open questions**, **decision/approval trail**.

(The [[design-doc-review-agent]] grades against exactly this; write to it.)

---

## 🛠 Set it up in a repo

1. Drop `templates/DESIGN_DOC_TEMPLATE.md` (and `ADR_TEMPLATE.md`) into the repo's `docs/` so authors copy from it.
2. Install the CI gate (lint + advisory review) — see [[design-doc-reviewer]]'s `workflow-template.yml` + `design-doc-lint.js` (enforces ≤15pp, required sections, secrets, and human-approval when `DDLINT_REQUIRE_APPROVAL=1`).
3. Put design docs under a discoverable path (`docs/design/`, `docs/rfcs/`, `docs/adr/`) matching the workflow's `paths:`.
4. Authors call [[design-doc-review-agent]] before requesting the automated gate.

---

## ✅ Harness Checklist
- [ ] Right tier chosen (ADR vs RFC vs architecture doc) — rigor scaled to the change
- [ ] Authored from the template; problem framed before solution; ≤15 pages
- [ ] Self-lint passed locally (sections, secrets, length)
- [ ] Human reviewers named + comments addressed; **human approval recorded** before automated review
- [ ] Automated review (design-doc-review-agent + CI gate) = APPROVE
- [ ] Decision + date recorded; doc kept current through implementation; archived/linked when shipped

See `templates/` for the fill-in docs.
