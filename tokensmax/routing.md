# Routing protocol — run this BEFORE any dispatch

Source of truth: [`dispatch-policy.yaml`](./dispatch-policy.yaml). Active mode: **propose-then-confirm**.

## Phase 0 — Understand & ground the goal FIRST (before magnitude, strategy, or any proposal)
The loop below assumes the task is *understood*. It isn't, until you've **grounded** it. Skipping this is
the "confidently-wrong" failure: you propose a polished plan against a goal you *assumed*, the user
approves the plan, and the misread only surfaces after tokens are spent (**goal misgeneralization**).
The plan gate (step 6) checks the *how*; only a goal gate checks the *what/why*.

**Use your cheapest fast tier for intake** — `tokensmax run claude --research --fast` (haiku; the most
reliable intake engine in our eval — 0% empty-output, 0% tool-wander). An OpenCode/GLM cheap model is
the $0 fallback (weaker + flaky non-interactive, ~29% empty; retry masks most). Resolve the concrete
model from `tokensmax status`; never burn a mid/deep model on this — it's structured, low-reasoning
work (FrugalGPT cascade + RouteLLM + OpenAI input-guardrail). **Intake is the one auto-dispatch that
needs no plan-pick** — fixed/read-only/cheap; `propose-then-confirm` still governs the execution plan.

Dispatch it as a **structured-output** research call — STRICT JSON, so gaps are *enumerated* not
vibe-checked (models are ~50% wrong at self-detecting underspecification, QuestBench). **Forbid tool
use** — agentic cheap engines otherwise wander off to read files on repo-referencing requests and return
no JSON (verified in `test/intake_eval`):
```
tokensmax run claude --research --fast "Analyze this request. Do NOT use any tools. Do NOT read any
 files. Output STRICT JSON only in your first and only message — no prose, no markdown fence:
 {goal: '<one-line restated intent>',
  slots: {scope, success_criteria, constraints, in_scope, out_of_scope, definition_of_done},
  assumptions: ['<things you'd fill in to proceed>'],
  clarity: '<clear|underspecified>',
  gaps: ['<which required slots are missing/ambiguous>'],
  clarifying_questions: ['<the 1-3 sharpest questions to close the gaps>']}
 Request: \"<the user's words>\""
```
> No `claude` seat? Fall back to `opencode`/glm-4.7 ($0, expect ~29% empty — retry masks it) or another
> cheap engine, or run intake inline in this session (same JSON). The point is the *gate*, not which
> process emits it.

**Then the confirm-goal gate — 🛑 STOP. Do NOT estimate magnitude or pick a strategy yet:**
- **`underspecified`** → ask the `clarifying_questions` via **AskUserQuestion** (cap **1–3**; one good
  question captures most of the value — Qulac). Merge answers into the slots, re-confirm. STOP.
- **`clear`** → restate the **goal + key assumptions** in ONE line, ask *"correct?"*. STOP.

**Silence is not consent** — wait for an explicit OK on the goal before Phase 1. Honor *"just do it /
skip intake"*, but the **bar to skip is high**: a request is "manifestly clear" only if it states a
single bounded action + a success criterion; when in doubt, run intake.

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
5. **Pick the RIGHT model** via `model_routing` — match capability to the task by **tier**: simple/mechanical →
   cheap+fast (`--fast`), moderate → mid (`-m <current mid model>`), hard/ambiguous/correctness-critical →
   deep (default top model / high-effort). Not biggest-by-default, not cheapest-by-default — the fit.
   Resolve the concrete model from `tokensmax status` + the current lineup; never a fixed version here.
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
- `--build` **commits its work on the branch** and saves a durable `.patch`. To keep it, run the printed
  `keep:` command (`git -C <repo> merge --no-ff <branch>`) or `git apply` the `.patch`. Output is **never
  lost to worktree cleanup** (the old "stage-only, copy files out" advice is obsolete — it caused file loss).
- The CLI **staggers** parallel `--build` launches and **auto-seeds HEAD** on a fresh `git init` repo.
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
