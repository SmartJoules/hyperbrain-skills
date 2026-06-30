# tokensmax Phase-0 Intake — Evaluation Findings

Proof that the Phase-0 intake gate works, where it doesn't, and why — grounded in SOTA eval methodology
and verified against two engines.

## Methodology (anchors)
- **QuestBench** (NeurIPS 2025, arXiv:2503.22674) — clear/underspecified *pair* construction; frontier models
  fail ~50% at minimal-question detection. We construct both variants.
- **Qulac / clarification-need detection** (SIGIR 2019, arXiv:1907.06554) — binary "does this need
  clarification?"; P@1; one good question > many.
- **BFCL** (ICML 2025) — schema fidelity (AST/strict-valid) + tool-restraint ("irrelevant" no-op slice).
- **τ-bench pass^k** (arXiv:2406.12045) + **pass@k** (HumanEval, arXiv:2107.03374) — nondeterminism.
- **PARADISE / Horvitz EVPI** — over-asking has a cost, but it is a *safe* failure direction vs. the
  costly one (false-clear → goal misgeneralization, arXiv:2105.14111).

## What was run
- `run_eval.py` dispatches each case in `cases.jsonl` through the **exact Phase-0 intake prompt**
  prescribed by the skill, K times, bounded retry on empty output, and computes the metrics above.
- **Run 1 — `opencode` (glm-4.7), K=3, 16 cases** (full stratified set). Report: `report_20260630_171901.md`. Raw: `runs/raw_20260630_171901.jsonl`. Console: `eval.log`.
- **Run 2 — `claude` (haiku-4-5), K=2, 5 cases** (failure-slice cross-check: terse-clear + ambiguous-complete
  + 2 underspecified). Report: `report_20260630_174822.md`. Raw: `runs/raw_claude_20260630_174822.jsonl`. Console: `eval_claude.log`.
  > Run 2's headline accuracy (40%) is **not representative** — the subset is deliberately weighted toward the hard-clear slice. Its purpose is the cross-engine *diagnosis*, not a benchmark.

## Results — what is PROVEN (working)

| claim | evidence |
|---|---|
| **Never misses an underspecified request** (the costly error) | **Recall(underspecified) = 100% on BOTH engines** (glm: TP=7 FN=0; haiku: TP=2 FN=0). Zero false-clears → the goal-misgeneralization failure the gate exists to prevent **did not occur**. |
| **Tool-wander bug is fixed** by the no-tools prompt | glm 2% (1 attempt of ~70), haiku **0%**. On the repo-referencing trap cases (U07/U08) — the original bug that returned 100% empty — **tools=0** across all runs (see proof excerpt below). |
| **Schema is sound** | haiku strict-valid 100%, parse 100%; glm 94% (drops are the empty-output flake, not schema breakage). |
| **It actually clarifies** | on underspecified cases it emits concrete, relevant gaps + questions (gap-keyword coverage 69–75%). |

Verbatim proof — U08 (repo-referencing, underspecified), correctly handled with **no tool wander**:
```
clarity: underspecified | goal: Improve the controller firmware in /Users/mac/Documents/controllerFirmware
gaps: ['What type of improvements are needed (bug fixes, features, performance, refactoring, security)?',
        'What specific issues or pain points exist with current firmware?']
questions: ['What specific improvements do you need?',
            'What issues are you experiencing with current firmware?']
tools: 0   empties: 0
```

## Results — LIMITATIONS (honest)

| limitation | evidence | severity / direction |
|---|---|---|
| **Over-asks on terse-clear requests** ("bump version to 1.2.0", "gitignore node_modules") | Reproduces on **both** engines (C07: glm 3/3 underspecified, haiku 2/2; C08 ambiguous-complete: both engines both runs). → **prompt-intrinsic, not glm-specific.** | **Safe failure** — over-asking is friction (PARADISE), not a wrong goal. Precision(underspecified) glm 78% / haiku 40%-on-subset. |
| **opencode/glm transport flake** — emits no final text on ~29% of attempts despite consuming tokens | glm empty-attempt 29%, avg 1.48 tries/run; even 4× retry didn't rescue every run. **haiku: 0% empty.** | Engine-specific. → **prefer haiku for intake** when available; glm is the $0 fallback. |
| **Nondeterminism** | glm pass^K=44%, flip 50% (inflated by empties + terse-clear flips); haiku pass^K=40%-on-subset, flip 20%. | τ-bench: frontier agents pass^k ≪ pass@1 is normal. K=3 here is below the K≥5 recommendation. |
| **Worker emits >3 questions** (cap not obeyed by the model) | q≤3 cap adherence: glm 29%, haiku 20%. | The **gate** caps at relay time (orchestrator picks ≤3); worker non-compliance is cosmetic. |
| **no-tools prompt ≠ 100%** | 1 glm attempt still called a tool (U01). | Residual 2%; the worktree/read-only profile is the real backstop. |
| Small N (16), K=3, no temp sweep, no LLM-as-judge on question quality | by construction | Defensible as regression guard + failure discovery, not a population benchmark. |

## Cross-engine diagnosis (the key result of Run 2)
| metric | opencode/glm | claude/haiku | verdict |
|---|---|---|---|
| Recall (underspecified) | 100% | 100% | **holds on both** |
| Empty-output | 29% | **0%** | glm-specific flake |
| Tool-wander | 2% | **0%** | no-tools prompt cleaner on haiku |
| Strict schema | 94% | **100%** | haiku cleaner |
| Over-asks terse-clear | yes | **yes** | **prompt-intrinsic** |
| Tokens/intake | ~10,018 | **~1,072** | haiku ~10× cheaper (but $-billed; glm is $0) |

**Conclusion:** the Phase-0 design is sound — it reliably catches underspecified requests (100% recall on
both engines) and the tool-wander regression is fixed. Two real limitations remain, both correctly
characterized: (1) **terse-clear over-asking is intrinsic to the prompt** and is a *safe* failure
direction (worth a future prompt refinement, but not a correctness bug); (2) **opencode/glm is flaky in
non-interactive mode**, so the skill should **prefer claude --fast/haiku for intake** when available.

## Post-rebase re-verification (2026-06-30 19:45 IST) — sanctity check
After rebasing onto the rewritten `feat/enterprise-fleet` (lean skill + new `bin/tokensmax` that
prepends a header line to dispatch output), the harness was re-run on `opencode` over all 16 cases, K=3
(report `report_20260630_194558.md`; console `eval_verify_opencode.log`):

| metric | pre-rebase | **post-rebase** |
|---|---|---|
| **Recall (underspecified)** | 100% | **100%** (TP=7, FN=0) |
| **Tool-wander** | 2% | **0%** (incl. repo-referencing trap U07/U08) |
| **Schema strict-valid** | 94% | **98%** |
| Empty-attempt (glm flake) | 29% | 26% |
| Accuracy / precision | 88% / 78% | 69% / 58% |

**The core invariant holds**: zero false-clears (the goal-misgeneralization error never fires), tool-wander
eliminated, schema clean. The harness also proved robust to the new CLI output (it skips the header line
and parses the NDJSON stream). The accuracy/precision dip is the known **terse-clear over-asking** —
nondeterministic run-to-run (pass^K=50%, flip=44%) and a *safe* failure direction; recall is stable at 100%.

**Blocker on the primary engine:** `claude`/haiku was **429 session-capped** at re-verification time
(raw `claude -p …` returns `is_error:true, api_error_status:429, "session limit · resets 9:20pm"`), so
the primary-engine re-run could not be completed — re-run `K=3 ENGINE=claude CASES=cases.jsonl python3
run_eval.py` after the seat resets to confirm the primary path. *(Also noted: the new CLI surfaces only a
prompt echo + trailer when an engine errors, swallowing the 429 message — a minor upstream UX gap.)*

## Reproduce
```bash
cd skills/tokensmax/test/intake_eval
K=3 ENGINE=opencode python3 run_eval.py        # full run
K=2 ENGINE=claude CASES=cases_crosscheck.jsonl python3 run_eval.py   # cross-check
```
