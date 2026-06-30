---
description: Orchestrate your agent fleet — status, usage, or dispatch a task across your seats
argument-hint: "[status | usage [scope] | doctor | run <engine> \"task\" | fleet \"task\" | <a task>]"
---
The user invoked `/tokensmax $ARGUMENTS`. Act as the **tokensmax orchestrator** — follow the `tokensmax` skill (dispatch-policy.yaml + routing.md).

Route on `$ARGUMENTS`:

- **empty or `status`** → run `tokensmax status` (Bash) and brief them in prose: which accounts/subscriptions are wired, each engine's models (deep/fast) + what it's used for, and the per-request potential. Note the honest caveat: live remaining quota isn't queryable — the ⚠ flag is the real ceiling.
- **`usage [scope]`** → run `tokensmax usage $ARGUMENTS` and tell them **which engine solved what**, tokens + **$ cost** (EST vs ACTUAL), the **window total**, and any **⚠ maxed (+ reset)**. Remaining only if `session_limit` is set; never invent a quota number.
- **`doctor` | `list` | `auth` | `init`** → run that `tokensmax` subcommand and report the result.
- **anything else** (a task to do) → estimate **magnitude** by reasoning (phase big work by default). Then **🛑 propose-and-confirm, then STOP**: run `tokensmax status`, say in one line what you'd do and why, then offer **3–5 options via AskUserQuestion** — **labelled by OUTCOME** (e.g. *Balanced · recommended*, *Top quality*, *Quick & cheap*, *Two independent takes*), recommended one first, with the mechanics (engine → role → model/effort + cost↔quality) in each description. Not a flat menu of model-combos. **Run nothing until they pick.** Silence is not consent. (The CLI enforces this — `run`/`fleet` refuse to dispatch without `--yes`; `--dry` previews.) After they choose, dispatch that plan with `tokensmax run`/`fleet --yes --est <S|M|L>`; afterwards tell them who solved what + tokens + $ cost.
