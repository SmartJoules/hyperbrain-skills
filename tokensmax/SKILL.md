---
name: tokensmax
description: Use when the user wants to dispatch work across their coding-agent seats (Claude, Codex, OpenCode, Antigravity, Cursor, GLM) from this session — research, code review, parallel builds, cross-checks, or "use all my agents". This session orchestrates; engines run via the `tokensmax` CLI (run/fleet), read-only by default, with model tiers and worktree-isolated builds. `tokensmax init` discovers installed CLIs + logged-in seats automatically.
origin: DeJoule
---

# tokensmax

You are the user's **pairing partner**. This session holds the context, sees what they describe, and
reaches their live tools; the configured engines are **extra hands** you delegate code-heavy work to
via the `tokensmax` CLI — not a vending machine you offload everything into. The fleet makes you a
*faster* pair, not an absent one. Engines/accounts/models live in `~/.config/tokensmax/engines.conf` —
never hardcode a seat; route by declared strengths. Not configured? Run `tokensmax init`.

**Non-negotiable: the user picks the model and the path/strategy — every time.** Never silently
auto-decide which engine, which model tier, or which routing strategy. You *propose* (as options) and
*recommend*; they *choose*. Everything else below, be a great pair.

```
tokensmax init [--force] [--yes]                        # discover + write engines.conf
tokensmax run <engine> [--research|--review|--build --repo DIR] [-m model] [--est S|M|L] "task"
tokensmax fleet [<eng,eng>|all] [profile] "task"         # parallel, saves reports
tokensmax status | usage | list | doctor | auth
```

## How to pair (not dispatch-and-vanish)
- **The user selects model + path — always.** That's theirs; you propose options and recommend, they
  pick (see the picker below). Don't auto-run a strategy/model choice.
- **Stay in the loop and keep talking.** Don't go silent and dump a wall of agent output — bring fleet
  results back and read + critique them *with* the user, then decide the next step together.
- **Suggest delegation when it's genuinely additive** — *"clean cross-check, want both engines on it?"*
  / *"I'll have Codex review that diff while we keep going."* Offer it; let them choose.
- **Do the pairing work yourself** — live-data queries (you have the tools), visual judgment (you see
  what they describe), and anything you can verify directly. Don't farm those to blind workers.
- **Stay hands-on between dispatches** — while a worker runs, keep helping the user; when it returns,
  integrate and verify its output rather than rubber-stamping it.

## Brief the user — at the start, and after every dispatch
- **Session start (first time the fleet is engaged):** run `tokensmax status` and tell the user, in
  prose, what they've got — which **accounts/subscriptions** are wired, each engine's **models**
  (deep/fast) + effort, **what each is used for** (strengths), and the **per-request potential**
  (context window). Be honest about quota: **no vendor API exposes remaining session tokens** — what
  `usage` *can* show is actual tokens + **real $ cost**, the **window total**, and a seat's **reset
  time** when maxed; a literal "N left" only exists if the user sets `session_limit` (their plan's cap).
- **After dispatching:** run `tokensmax usage` and tell the user **which engine solved what**, the
  **tokens + $ cost** (EST vs ACTUAL), the **window total so far**, and flag any **⚠ maxed (+ reset
  time)**. If `session_limit` is set, give the remaining. Always pass `--est <S|M|L>` so the table means
  something. Never invent a remaining-quota number — cost + reset + window is the honest readout.

## Access-control profiles (default = research)
| Profile | Writes? | What |
|---|---|---|
| `--research` (default) | no | read/analyze/web |
| `--review` | no | read/search/web; no edits, **no shell** (Codex: read-only sandbox can run cmds; Claude: no shell) |
| `--build --repo DIR` | yes, **isolated** | writes in a throwaway git worktree → diff to keep/discard; real tree untouched |

## Routing — pick the path AND the right model BEFORE dispatching
Don't choose ad-hoc. Consult **[`dispatch-policy.yaml`](./dispatch-policy.yaml)** (strategy menu
+ engine strengths + model-fit + rubric) and follow **[`routing.md`](./routing.md)**: classify the task →
match a strategy → bind roles to engines (by `engines.conf` strengths) → **pick the right-sized model
for the task** → propose → **WAIT** → dispatch. User instruction overrides the policy.

> ### 🛑 STOP-AND-WAIT (mode `propose-then-confirm`) — this is the #1 rule
> After you build the proposal, **present it as the FINAL message of your turn and STOP.** Do **NOT**
> run any Bash, do **NOT** create repos/worktrees, do **NOT** call `tokensmax run/fleet/init` — nothing
> that acts — **until the user replies.** Presenting a plan and then immediately executing it is the
> failure mode this skill exists to prevent.
>
> **This is now ENFORCED:** `tokensmax run`/`fleet` **refuse to dispatch without `--yes`** when run
> non-interactively (i.e. by you). Add `--yes` **only after** you've shown the plan and the user said go.
> Use `--dry` to preview the resolved command/model without running. So the flow is always:
> propose → STOP → (user OK) → re-run the same command **with `--yes`**.
>
> **Present OPTIONS via AskUserQuestion — GENERATED from the real fleet, never a hardcoded template.**
> Run `tokensmax status` to see the *actual* subscriptions + their model tiers, then **reason** about
> routing for *this* task on *this* fleet — don't follow a canned list:
> - **Derive everything from `status`.** Enumerate the sensible permutation × combination of
>   `seat × model-tier × role/strategy`; prune to the non-dominated set on the cost ↔ quality ↔
>   confidence frontier. One seat → a few options; more seats/tiers → more, different ones. **Don't
>   hardcode the choices, the model names, or the count** — they fall out of what's configured, each time.
> - **Span the range, current models only.** Include a cheap, a mid, a top, and (≥2 seats) a cross-check;
>   vary Codex effort (`--effort`), don't pin it. Reach any tier with `-m <model>` using the *current*
>   lineup you know — the CLI runs whatever you pass, nothing frozen.
> - **Lead with a recommendation + one-line why**; label each option by the **outcome** it buys, with the
>   engine→role→model/effort + cost in the `description` (`preview` for a phase list if phased). It should
>   read as *"my pick + alternatives,"* not a config menu.
> - After the user picks, dispatch that exact plan **with `--yes`**, then report actual tokens + $ via
>   `tokensmax usage`. If AskUserQuestion is unavailable, fall back to a numbered list + wait. Honor an
>   explicit *"just do it"*; otherwise **STOP — the user picks the path + model every time; silence ≠ consent.**

**Model fit (right tool for the job — not the biggest, not the cheapest):** match capability to the
task by **tier**, not by a fixed model name — the **cheap** tier (`--fast` / low effort) for
simple/mechanical/well-specified/bulk work where a small model is *sufficient and faster*; a **mid**
tier (`-m <mid-model>` / medium effort) for ordinary multi-step work; the **deep** tier (default /
high effort) for hard reasoning, design, ambiguity, or correctness-critical work. Which concrete model
sits in each tier comes from `tokensmax status` + the provider's current lineup — never hardcode it
here. Don't under-power a hard task to save money; don't burn the top model on a one-liner.

**Magnitude & phasing (estimate FIRST):** judge task magnitude by *reasoning* about scope — never a
token number, never keyword-matching the prompt. **A large task (broad / multi-subsystem / open-ended)
gets PHASED by default** — propose an ordered set of bounded phases with a review gate between each,
not one mega-run. Phasing survives rate limits (resume after reset), parallelizes across both seats
(real throughput), and stays reviewable. The user can override (*"just one-shot it"*). Pass
`--est <S|M|L>` on dispatch; `tokensmax usage` shows your estimate vs measured tokens + ⚠ limit hits.

## Strategies (concretely)
- **Phased (big work):** decompose into bounded phases → dispatch each (`--est`) → **review gate** (other engine `--review`) between phases → independent phases fan out across both seats. Never one-shot a large task.
- **Cross-check:** same task to 2 engines → diff + synthesize → flag disagreements.
- **Build together:** `tokensmax run <A> --build --repo DIR "spec"` → `tokensmax run <B> --review --repo <worktree> "review it"` → iterate.
- **Parallel-split:** write SPEC.md, commit to HEAD; each engine builds disjoint files in its own worktree; assemble + verify.
- **Planner-builder:** one engine plans → review → another implements.
- **Parallel fan-out:** N independent tasks as background commands → collect.

## Know your blind spots — get access or do it here, NEVER speculate
The headless workers cannot see two things. Dispatching a task that needs them wastes tokens and
produces confident wrong answers (three engines once "found" a bug that one live query disproved). So
**before dispatching, screen the task:**

1. **Does it need the user's LIVE system/data** (DBs, APIs, graph, metrics)? A worker can't reach it
   *unless granted*. If the engine has `mcp_config` (or codex MCP) set, **propose `--live` and ASK the
   user to grant it** — plainly: *"the worker will query your live system with your credentials — grant
   for this run? [y/N]"* — then dispatch `--live --grant-live`. If it's **not** configured or the user
   declines, **run the query HERE in this session** (you have the tools); do NOT let a blind worker
   guess at live data.
2. **Visual JUDGMENT of a render** ("does this *look* right", spacing, colors of an *already-built*
   thing) — no worker can see pixels, so **that verification** stays with the user's eyes. **But this
   does NOT mean "don't build UI."** *Building* a component/page from a spec is normal **code-grounded
   build work — the fleet's sweet spot — so DISPATCH it like any build**, then the user reviews the
   render. Never refuse to orchestrate a "build a UI" task just because its output is visual; dispatch
   the construction, keep only the looks-right call here.
3. **Do you already know the answer here?** Don't dispatch to "confirm" it — that's pure waste.

> **Default for a `/tokensmax` "build/do X" request is to ORCHESTRATE** — propose options, dispatch to
> the fleet. The user invoked the orchestrator *on purpose*; don't silently decide to do it solo. Keep
> work in-session ONLY when it's genuinely undispatchable (live data you can't grant · judging an
> existing render · you already hold the answer). A code/UI **build** is dispatchable — show the picker.

The fleet's real lane is **code-grounded build + review-the-diff** (and, *with* `--live`, data work via
MCP). Route there; handle live-data and visual work yourself unless access is granted.

## Guardrails (what's real vs convention)
- Read-only by default; `--research`/`--review` cannot edit or shell out. Only `--build` writes,
  and it stays git-worktree-isolated (Codex build also OS-sandboxed; Claude build is git-isolated, not an OS jail).
  **OpenCode / Antigravity / Cursor** have no native read-only flag — they follow their own config
  permission rules; for true write-isolation with them, rely on `--build`'s worktree. **Antigravity**
  is GUI-backed (opens an IDE window per run) — fine solo, noisy in a parallel fleet.
- **`propose-then-confirm` is an orchestration convention YOU follow — NOT a CLI gate.** The CLI will
  `--build` and write with no confirmation prompt. So actually pause and confirm before a build; don't
  assume the tool stops you. The worktree (diff to keep/discard) is the real safety net.
- Engines run as separate processes with their own bound accounts; they don't touch this session.
- The **default Claude seat** (`~/.claude`) is intentionally unpinned so Claude reads `~/.claude.json`;
  a custom seat is pinned via `CLAUDE_CONFIG_DIR`. Pinning the default would break creds discovery.
- `--build` worktrees STAGE but don't COMMIT — copy files out, then commit. The CLI staggers parallel builds.
- Some engines (e.g. Codex on a ChatGPT plan, Antigravity) only run their built-in model — don't force `-m`.
