# Routing protocol — run this BEFORE any dispatch

Source of truth: [`dispatch-policy.yaml`](./dispatch-policy.yaml). Active mode: **propose-then-confirm**.

## Phase 0 — Understand & ground the goal FIRST (before magnitude, strategy, or any proposal)
The loop below assumes the task is *already understood*. It isn't, until you've **grounded** it with the
user. Skipping this is the #1 cause of "confidently wrong" runs: you propose a polished plan against a
goal you *assumed*, the user approves the plan (it looks right), and the misread only surfaces after
tokens are spent. That failure mode has a name — **goal misgeneralization** (capability intact, wrong
target). The plan gate (step 6) checks the *how*; only a goal gate checks the *what/why*.

**Use `claude --fast` (haiku) for intake** — `tokensmax run claude --research --fast`. Haiku is the
most reliable intake engine we tested (0% empty-output, 0% tool-wander, ~10× fewer tokens than glm).
Intent parsing, slot extraction, and gap-detection are structured, low-reasoning work, squarely
cheap-tier (FrugalGPT cascade + RouteLLM, whose router is an 8B model + OpenAI's input-guardrail
pattern). Do **not** burn this session or a deep model on it; keep them for *planning + dispatch*,
which runs only once the goal is grounded. **`opencode`/glm-4.7 is the $0 fallback** — weaker than
haiku and flaky non-interactive (~29% empty; retry masks most). **glm-5.2 is a worker tier, not
intake** (stronger than sonnet, weaker than opus-4.8). **Intake is the one auto-dispatch that needs no
plan-pick** — it's fixed, read-only, and cheapest-tier; there's no meaningful model/path choice for the
user to make, so `propose-then-confirm` does not apply here (it still governs the *execution* plan).

Dispatch intake as a **structured-output** research call (STRICT JSON, so gaps are *enumerated*, not
vibe-checked — models are ~50% wrong at self-detecting underspecification, QuestBench). **Forbid tool
use** in the prompt — the cheap engine is agentic and will otherwise wander off to read files when the
request references a repo, returning no JSON (verified in sandbox):
```
tokensmax run claude --research --fast "Analyze this request. Do NOT use any tools. Do NOT
 read any files. Output STRICT JSON only in your first and only message — no prose, no markdown fence:
 {goal: '<one-line restated intent>',
  slots: {scope, success_criteria, constraints, in_scope, out_of_scope, definition_of_done},
  assumptions: ['<things you'd fill in to proceed>'],
  clarity: '<clear|underspecified>',
  gaps: ['<which required slots are missing/ambiguous>'],
  clarifying_questions: ['<the 1-3 sharpest questions to close the gaps>']}
 Request: \"<the user's words>\""
```
> No `claude` seat configured? Fall back to `opencode` (glm-4.7, $0, expect ~29% empty — the bounded
> retry handles it) or another cheap engine, or run intake inline in this session (same JSON). The point
> is the *gate*, not which process emits the JSON.

**Then the confirm-goal gate — 🛑 STOP. Do NOT estimate magnitude or pick a strategy yet:**
- **`underspecified`** → ask the `clarifying_questions` via **AskUserQuestion** (cap at **1–3**; one
  good question captures most of the recoverable value — Qulac — more is annoying, per PARADISE's
  cost-of-asking). Merge the answers into the slots and re-confirm. STOP.
- **`clear`** → restate the **goal + key assumptions** in ONE line and ask *"correct?"*. If the user
  amends a slot, take it. STOP.

**Silence is not consent** — wait for an explicit OK on the goal before Phase 1. Honor an inline
*"just do it / skip intake"* override for power users, but the **bar to skip is high**: a request is
"manifestly clear" only if it states a single bounded action + a success criterion; when in doubt,
run intake (QuestBench: models ~50% wrong at self-detecting underspecification).

## The loop  (Phase 1+ — only after the goal is grounded)
1. **Estimate magnitude** by *reasoning* about scope (subsystems, breadth, open-endedness, expected
   output) — never a token number, never keyword-matching the prompt. **If it's large (L): phase it.**
   Propose a phased plan (bounded sub-tasks + a review gate between phases) instead of one mega-run —
   that's the default; the user can override (*"just one-shot it"*). Carry `--est <S|M|L>` per dispatch.
2. **Classify** the rest on the rubric axes (cheap, in-head):
   `task_complexity · files_touched · independence · design_vs_logic_mix · risk_ambiguity · reversibility`.
3. **Match** against `routing:` rules in order → first fit is the candidate strategy.
4. **Bind roles → engines** by matching the role's nature to each engine's `strengths`
   (from `~/.config/tokensmax/engines.conf`): design/prose/plan → a reasoning engine;
   logic/refactor/review → a code engine.
5. **Pick the RIGHT model** via `model_routing` — match capability to the task: simple/mechanical →
   small+fast (`--fast`), moderate → mid (`-m claude-sonnet-4-6`), hard/ambiguous/correctness-critical →
   strong (opus default / high-effort). Not biggest-by-default, not cheapest-by-default — the fit.
   Per role/phase if they differ (e.g. a mid drafter + a strong reviewer).
6. **Present OPTIONS via AskUserQuestion, then 🛑 STOP** — this is the **plan gate** (the *second*
   gate; Phase 0 was the goal gate). Don't dump text; offer the interactive
   picker (like brainstorming). Build **3–5 options from `tokensmax status`** (the actual engines +
   models), scaled to what's configured: recommended split · swapped split · cross-check (if ≥2
   engines) · cheap/fast · phased-if-large. Each option label names `engine → role → model` + write
   mode. **Run nothing** (no Bash, no worktree, no `run/fleet`) until the user picks. Silence ≠ consent.
   (Exception: an explicit up-front "just do it".) If AskUserQuestion is unavailable, fall back to this
   text block and wait:
   ```
   Magnitude: <S|M|L>   (because <reason>)   → <single run | N phases>
   1) <engine> → <role> → <model>  ·  <write mode>  ·  <paths>      ← recommended
   2) <engine> → <role> → <model>  ·  …                            (swapped)
   3) cross-check: both engines, compare
   4) cheap: <engine> --fast
   ```
7. On OK → **dispatch with `--yes`** (plus `--fast`/`-m <model>`, `--est <S|M|L>`). The CLI **refuses to
   run without `--yes`**, so you cannot skip step 6 — add `--yes` only now, after the user agreed. For a
   phased plan: run phase i → **review gate** (other engine `--review`) → only then phase i+1; fan out
   independent phases across both seats. On pushback → adjust. If a result comes back shallow, **re-run
   one tier up**. Check `tokensmax usage` for estimate vs actual + cost + any ⚠ limit hits.

## After dispatch — assembly invariants
- `--build` worktrees **stage but don't commit**. Copy the produced files out of each worktree
  into the real repo, then commit. Don't rely on `git merge` (branches sit at HEAD).
- **Stagger** two `--build` launches >1s apart — branch names are timestamped to the second.
- For `parallel-split`, commit `SPEC.md` to HEAD **before** dispatch so every worktree sees it.
- **Verify** before claiming done: contract IDs present, code parses, hooks line up.

## Switching modes
Edit `mode:` in `dispatch-policy.yaml` (`propose-then-confirm` | `auto-announce` | `auto-escalate`),
or the user says so inline for one task. User instruction overrides the file.

## Example
Task: a small static dashboard, HTML/CSS + JS. Classified: 3 files, high independence, clear
design↔logic seam, low risk → **parallel-split**. Bind shell/ui → reasoning engine, behavior →
code engine. Write `SPEC.md` (DOM ids + data model), commit to HEAD, dispatch both `--build`
staggered, copy files out, verify ids + JS parse. Under propose-then-confirm this is shown and
confirmed before dispatch.
