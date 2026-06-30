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

## Phase 0 — Understand & ground the goal FIRST (before magnitude, strategy, or any proposal)
This runs **before** the routing flow below. The whole routing flow assumes the task is *understood* —
it isn't, until you've **grounded** it with the user. Skipping this is the #1 cause of "confidently
wrong" runs: you propose a polished plan against a goal you *assumed*, the user approves the plan (it
looks right), and the misread only surfaces after tokens are spent. That failure mode has a name —
**goal misgeneralization** (capability intact, wrong target). The plan gate checks the *how*; only a
goal gate checks the *what/why*.

**Use `claude --fast` (haiku) for intake** — `tokensmax run claude --research --fast`. Haiku is the most
reliable intake engine we tested (0% empty-output, 0% tool-wander, ~10× fewer tokens than glm).
Intent parsing, slot extraction, and gap-detection are structured, low-reasoning work — squarely
cheap-tier (FrugalGPT cascade + RouteLLM, whose router is an 8B model + OpenAI's input-guardrail
pattern). Don't burn this session or a deep model on it; keep them for *planning + dispatch*, which
runs only once the goal is grounded. **`opencode`/glm-4.7 is the $0 fallback** — it sits *below* haiku
in quality and is flaky in non-interactive mode (~29% of attempts return empty; bounded retry masks
most of it). **glm-5.2 is not an intake model** — it's a worker tier (stronger than sonnet, weaker than
opus-4.8), wasteful here. **Intake is the one auto-dispatch that needs no plan-pick** — it's fixed,
read-only, cheapest-tier; there's no meaningful model/path choice for the user to make, so the *"user
picks model + path — always"* rule governs the *execution* plan, not intake.

Dispatch intake as a **structured-output** research call — STRICT JSON, so gaps are *enumerated*, not
vibe-checked (models are ~50% wrong at self-detecting underspecification — QuestBench). **Forbid tool
use** in the prompt — the cheap engine is agentic and will otherwise wander off to read files when the
request references a repo, returning no JSON (verified in sandbox):
```
tokensmax run claude --research --fast "Analyze this request. Do NOT use any tools. Do NOT
 read any files. Output STRICT JSON only in your first and only message — no prose, no markdown fence:
 {goal: '<one-line restated intent>',
  slots: {scope, success_criteria, constraints, in_scope, out_of_scope, definition_of_done},
  assumptions: ['<things you'd fill in to proceed>'],
  clarity: '<clear|underspecified>',
  gaps: ['<missing required slots>'],
  clarifying_questions: ['<1-3 sharpest questions>']}
 Request: \"<the user's words>\""
```
> The worker may still wrap the JSON in a ``` fence — strip it (or just read it; you're an LLM, not a
> parser). The fields matter, not the wrapper.
> No `claude` seat? Fall back to `opencode`/glm-4.7 ($0, ~29% empty — retry masks it) or another cheap
> engine, or do intake inline in this session (same JSON). The point is the *gate*, not which process
> emits the JSON.

**Then the confirm-goal gate — 🛑 STOP. Do NOT estimate magnitude or pick a strategy:**
- **`underspecified`** → ask the `clarifying_questions` via **AskUserQuestion** (cap **1–3**; one good
  question captures most of the value — Qulac; more is annoying). Merge answers into the slots,
  re-confirm. STOP.
- **`clear`** → restate the **goal + key assumptions** in ONE line, ask *"correct?"*. If they amend a
  slot, take it. STOP.

**Silence is not consent** — wait for an explicit OK on the goal before routing. Honor an inline
*"just do it / skip intake"* override, but the **bar to skip is high**: "manifestly clear" means a
single bounded action + a stated success criterion; when in doubt, run intake.

## Routing — pick the path AND the right model BEFORE dispatching
> **Precondition:** Phase 0 (above) is done — the goal is grounded. Don't classify or route a guess.
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
> **Present it as interactive OPTIONS, not a wall of text.** Use **AskUserQuestion** — the same picker
> you'd use when brainstorming — so the user clicks a plan instead of typing. Build the options
> **dynamically from `tokensmax status`** (the configured engines + their models), so they reflect what
> this user actually has. Offer **3–5 routing options**, scaled to what's configured:
> - your **recommended** split (engine → role → model)
> - a **swapped** split (e.g. the other engine builds)
> - **cross-check** — both engines do it independently, you compare *(only if ≥2 engines)*
> - a **cheap/fast** single-engine option (`--fast`)
> - for a large task, a **phased** plan (bounded phases + review gate)
>
> With one engine configured, that might be just 2 options; with two+ engines and model tiers, 4–5.
>
 **This is a PROPOSE-AND-CONFIRM, not a flat menu. Lead with a recommendation; frame options by OUTCOME.**
> First, in **one line before the picker**, say what you'd do and why — *"a bounded UI build → I'd go
> **Balanced**: Sonnet builds, Codex reviews."* Then in the picker:
> - `label` = the **outcome in plain words**, the recommended one **first and marked** — e.g.
>   **"Balanced · recommended"**, **"Top quality"**, **"Quick & cheap"**, **"Two independent takes"**.
>   NOT raw *"Sonnet builds · Codex reviews"* — that's jargon the user shouldn't have to decode to choose.
> - `description` = the mechanics behind the outcome: **who does what** (engine → role → model/effort) +
>   the **cost↔quality tradeoff** (cheap/mid/deep + ~token ballpark) — so the detail is there if they want it.
> It should read as *"here's my pick + why; confirm, or take an alternative,"* not *"choose 1 of 4 configs."*
> - **Span the engine's FULL model range — and use the LATEST models.** Pick tiers from the provider's
>   *current* lineup **as you know it right now** — never a frozen/hardcoded version string. For
>   **Claude**, that's the cheap → mid → deep → max families (haiku · sonnet · opus · fable) at their
>   **current versions**; for **Codex**, the model is fixed but its depth dial is **reasoning effort** —
>   **vary it across options with `--effort low|medium|high|xhigh`** (don't pin Codex to `high`; a
>   simple/bounded task is fine at low/medium and costs far less). The
>   config only gives the *default* + *fast* model; reach any other tier with `-m <current-model>` — the
>   CLI is model-agnostic and runs whatever you pass, so it never constrains you to a stale list. **Do
>   NOT default every option to the top model;** always include a **mid-tier** option (often the
>   recommended one for an ordinary task), alongside a cheap and a deep one. If unsure what the current
>   lineup is, prefer the user's configured models and the families above at their latest versions.
> - For a multi-phase plan, use the option's `preview` to show the phase list + which engine/tier runs
>   each phase.
>
> The question `header` is e.g. `Routing`; add a second AskUserQuestion (`header: Model`) only if model
> choice is a genuinely separate fork. After the user picks, dispatch that exact plan **with `--yes`**,
> then report the **actual tokens + $ per engine** via `tokensmax usage` (your estimate vs actual, so
> the next estimate is better). If AskUserQuestion isn't available, fall back to a numbered text list
> with the same detail and wait. Honor an explicit "just do it / don't ask"; otherwise **silence is not
> consent — wait.**

**Model fit (right tool for the job — not the biggest, not the cheapest):** match capability to the
task. Ladder: `glm-4.7 < haiku < sonnet < glm-5.2 < opus-4.8`. `--fast` (haiku / codex low-effort /
glm-4.7) for simple/mechanical/well-specified/bulk work where a small model is *sufficient and faster*;
`-m claude-sonnet-4-6` or `-m zai-coding-plan/glm-5.2` (mid; glm-5.2 is ~sonnet-class, $0) for ordinary
multi-step work; the deep default (opus / high-effort; or glm-5.2 as a $0 near-deep — stronger than
sonnet, weaker than opus) for hard reasoning, design, ambiguity, or correctness-critical tasks. Don't
under-power a hard task to save money; don't burn the top model on a one-liner.

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
2. **Does it need the rendered UI / a visual judgment** ("does this look right", spacing, colors)? No
   worker can see a render — **keep it in this session, with the user's eyes.** Never dispatch it.
3. **Do you already know the answer here?** Don't dispatch to "confirm" it — that's pure waste.

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
