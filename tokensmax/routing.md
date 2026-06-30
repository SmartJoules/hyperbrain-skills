# Routing protocol — run this BEFORE any dispatch

Source of truth: [`dispatch-policy.yaml`](./dispatch-policy.yaml). Active mode: **propose-then-confirm**.

## The loop
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
6. **Present OPTIONS via AskUserQuestion, then 🛑 STOP** — don't dump text; offer the interactive
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
