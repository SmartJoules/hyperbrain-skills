---
name: tokensmax
description: Orchestrates the user's coding-agent subscriptions (Claude, Codex, OpenCode, GLM, Cursor, Antigravity) as a fleet via the `tokensmax` CLI — briefs what's available, proposes routing options across seats and model tiers, dispatches the chosen plan, reports cost. Use whenever the user asks to build, write, research, review, or "do" a non-trivial task and a fleet is configured: route the work to the right (often cheaper) seat instead of doing it all in this session. This is the default way to handle such tasks here, not only when the user says "use my agents".
---

# tokensmax — you orchestrate, you don't do

The user brings a task; you **route it to their other agent seats** via the `tokensmax` CLI. Doing it
all yourself burns this expensive session's tokens — delegating to a cheaper or other seat is the point.

## The loop — MUST follow, in order

1. **Brief.** Run `tokensmax status` and tell the user what's wired: subscriptions, each engine's model
   tiers, what each is for. Read it — don't assume the fleet.
2. **Propose options — and build NOTHING yet.** Present routing choices via **AskUserQuestion**.
   🛑 If you are about to Write/Edit/run the task yourself before the user picks — **STOP. That is the
   failure this skill exists to prevent.** (You may ask *one* scoping question first if the task is
   ambiguous — but the routing picker still comes before any work.)
3. **Dispatch** the chosen plan: `tokensmax run|fleet --yes [-m <model> | --effort <lvl>] --est S|M|L`.
4. **Report.** `tokensmax usage` → who solved what, tokens + $.

## Building the options — reason from the real fleet, never a hardcoded list

From `tokensmax status`, form the sensible **permutation × combination** of `seat × model-tier × role`
(solo · build+review · cross-check · phased), then:
- **Lead with a recommendation** + one line why; label each by the **outcome** it buys (recommended
  first), engine→model/effort + rough cost in the `description`. Not a menu of model-combos.
- **Always include a token-saving option:** hand the *whole* task to a cheaper/other seat (e.g. Codex or
  GLM, solo) so this session spends almost nothing — pick the concrete seat from what's configured.
- **Span the tiers:** a cheap, a mid (often the pick), a top, and — with ≥2 seats — a cross-check. Vary
  Codex effort; reach any model with `-m` from the current lineup. Never pin to the top, never hardcode names.
- More seats → more options; one seat → fewer. **The user picks the model + path, every time.**

## Default to orchestrating

Any build / research / review / "do X" request → run the loop. Do it **in this session instead** only
when it's genuinely undispatchable — and then say so and ask first:
- needs **live data** a worker can't reach → offer `--live` (see [reference/access.md](reference/access.md)),
- it's **judging an already-rendered UI** (no worker sees pixels — but *building* UI IS dispatchable),
- you **already hold the answer**.

## Depth — read on demand

- Strategies, routing rubric, modes → [dispatch-policy.yaml](dispatch-policy.yaml) · [routing.md](routing.md)
- Live access, blind spots, exceptions → [reference/access.md](reference/access.md)
- The `--yes` gate + approval hook + honest limits → [reference/enforcement.md](reference/enforcement.md)
- Profiles: `--research` (default, read-only) · `--review` (no edits/shell) · `--build --repo DIR` (worktree-isolated)
- Briefing/usage detail: `status` shows subscriptions+tiers; `usage` shows est-vs-actual tokens + $ + ⚠ limits.
