# tokensmax

**Run your coding agents as a fleet.** You pay for Claude, Codex, maybe more — but you talk to one at
a time while the rest sit idle. `tokensmax` turns the session you're already in into an **orchestrator**:
it sizes the task, offers you a routing plan across your seats, and — once you pick — dispatches them
in parallel as headless workers, each bound to the right account, then tells you who did what and what
it cost.

```
YOU ── goal ──▶  this session (orchestrator)
                   │  🛑 ground the goal (cheap intake) → estimate size · pick strategy · PROPOSE
                   │  └──── 🛑 you confirm the goal, then pick a plan ────┐
         ┌──────────┼──────────┐                   │
         ▼          ▼          ▼                    ▼
      Claude     Codex      others   ──────▶   dispatch  (read-only, or isolated build)
    design /    logic /     cheap /
    reasoning   review      bulk
         └──────── merge ────────┘   → one answer, or a diff you keep / discard
```

---

## Watch it work

You're in a session. You type:

```
/tokensmax build a small weather dashboard — current conditions + 5-day forecast
```

**0. It grounds the goal first.** The cheapest fast tier (haiku) reads your request and returns a
structured read — for this clear, bounded request it restates: *"build a static weather dashboard,
current conditions + 5-day forecast — correct?"* You confirm; it moves on. (For an under-specified ask
it would ask 1–3 sharp questions here and stop until you answer.)

**1. It briefs you on the fleet** (`tokensmax status`) — your actual seats, models, and what each is for:

```
● claude   enterprise seat · cheap haiku · mid sonnet · deep opus · 1M context · design / reasoning
● codex    ChatGPT seat     · gpt-5.5 at effort low|med|high|xhigh · ~256K · logic / review / tests
```

**2. It sizes the task and offers routing options** — built from *your* seats and the *current* model
ladder, not a fixed menu. It runs **nothing** yet:

```
┌ Routing — weather dashboard  (magnitude: S–M, a bounded frontend build) ──────────┐
│ ▸ Claude/sonnet builds · Codex/high reviews     recommended — mid tier, ~½ opus $   │
│   Claude/opus builds · Codex reviews            deep — overkill here                │
│   Claude --fast (haiku), one-shot               cheap first draft                   │
│   Cross-check: both build, I diff + synthesize  highest confidence, ~2× spend       │
└─────────────────────────────────────────────────────────────────────────────────────┘
   ↑/↓ navigate · Enter to pick · Esc to cancel
```

**3. You pick "Cross-check."** It dispatches **both seats in parallel**, each in its own throwaway git
worktree — your real branch never touched — then diffs the two builds and synthesizes the best of each.

**4. It reports who did what, and the real cost:**

```
WHEN     ENGINE  EST  ACTUAL  TASK
19:42:10 claude   M   14,203  weather dashboard
19:42:10 codex    M    9,876  weather dashboard
window so far: 24,079 tokens · $0.071   (Claude reports $; Codex reports tokens)
```

From one prompt: two independent attempts, merged — nothing hardcoded, nothing run without your pick.

## What makes it different

Most "run N agents" tools loop over a list and hope. tokensmax is opinionated where it counts:

- **Grounds the goal before it plans.** The cheapest fast tier reads your request first and surfaces a
  restated goal + assumptions (or asks 1–3 sharp questions) — you confirm *what* before it proposes
  *how*. No more confidently-wrong plans against a goal it silently assumed.
- **Right-sized models, not max-by-default.** It offers the full ladder (cheap → mid → deep) and
  *recommends the fit* — you don't pay Opus prices for a lint pass, and it won't silently default to the
  top model. Uses the **current** lineup; no version is hardcoded.
- **Confirm at the tool boundary.** `run`/`fleet` refuse to dispatch without `--yes`; and the optional
  `tokensmax-guard` **hook** makes Claude Code **pause for your approval before every dispatch** — a real
  human-in-the-loop, not the orchestrator's goodwill.
- **Big work auto-phases.** A broad task decomposes into bounded phases with a review gate — they
  checkpoint (survive a rate limit, resume after reset) and parallelize across seats. Real throughput,
  not raw burn.
- **Honest about cost & quota.** Real `$` per run, window totals, and a reset time when a seat maxes
  out. It will **not** fake a "tokens left" number — no vendor exposes one.
- **Inspectable routing.** Who-plans-who-builds is a policy file you can read and edit
  ([`dispatch-policy.yaml`](./dispatch-policy.yaml)), not a black box.
- **Account-bound.** Each engine is pinned to its own login; it can't fall back to the wrong seat.

Day to day:

```bash
tokensmax fleet "compare two cache-eviction strategies for a read-heavy store; cite tradeoffs"
tokensmax run codex  --review --repo ~/myapp "audit src/ for data races, cite file:line"
tokensmax run claude --build  --repo ~/myapp "add a --version flag"   # isolated worktree → diff
```

---

# Setup (about 5 minutes)

Need: **macOS or Linux**, stock **bash**, **git**, optionally **python3** (for Claude token/cost
capture — works without it, just less precise), and **at least one agent CLI** logged into your own
account. Four steps, in order.

### 1 — Install tokensmax

```bash
./install.sh tokensmax        # CLI → ~/.local/bin · skill → ~/.claude/skills · slash cmds → ~/.claude/commands
tokensmax --help              # prints usage → you're installed
```

If `~/.local/bin` isn't on your PATH, the installer prints the one line to add.

### 2 — Install the agent CLIs you want, and log in

At least one (Claude + Codex is the recommended pair). One-time login to **your own** account —
credentials are per person, never shared.

| Engine | Install (official source) | Log in |
|---|---|---|
| **Claude** | Claude Code — `npm i -g @anthropic-ai/claude-code` (or the native installer) | run `claude`, then `/login`, then `/exit` |
| **Codex** | Codex CLI — `npm i -g @openai/codex` | `codex login` |
| OpenCode *(optional)* | opencode.ai | `opencode auth` |
| Cursor / Antigravity *(optional)* | their installers | `cursor-agent login` / sign in in the IDE |
| GLM / any Anthropic-compatible API *(optional)* | — | key in `secrets.env` (step 4) |

> **Separate work + personal Claude seats?** Log the work one into its own dir:
> `CLAUDE_CONFIG_DIR="$HOME/.claude-work" claude` → `/login`. tokensmax pins that seat so it can
> **never** fall back to your personal `~/.claude`.

### 3 — Discover + write your config

```bash
tokensmax init     # scans installed CLIs + logged-in seats, asks which to bind, lets you pick models + roles
```

No hand-writing paths. Re-run `tokensmax init --force` after adding an engine; `--yes` accepts defaults.

### 4 — Verify, then go

```bash
tokensmax auth          # each engine logged in / configured?
tokensmax doctor        # CLI found · on PATH · authed — one table
tokensmax status        # the briefing
tokensmax run codex "reply with exactly: OK"     # first dispatch
```

All green in `doctor` → you're done. For API-keyed engines (e.g. GLM), put the key in
`~/.config/tokensmax/secrets.env` (`chmod 600`, never committed).

---

## Reference

### Commands

```
tokensmax status                       what's wired: accounts, models, what-for, per-call context
tokensmax run <engine> [opts] "task"   one engine
tokensmax fleet [eng,eng|all] "task"   several in parallel → saved reports
tokensmax usage [today|all|DATE]       who solved what · est vs actual tokens · $ cost · ⚠ limits
tokensmax init | doctor | auth | list
```

From inside a session: `/tokensmax <task>`, plus `/tm-status` and `/tm-usage`.

### Access-control profiles — what you let an agent do

Default is read-only. You allocate the *kind* of access, not just the task.

| Profile | Writes? | What |
|---|---|---|
| `--research` *(default)* | no | read / analyze / web |
| `--review` | no | code review — read, search, web; **no edits, no shell** (Codex can run *read-only* shell via its sandbox; Claude reads + reasons only) |
| `--build --repo DIR` | yes, isolated | builds in a throwaway **git worktree** off `DIR` → prints a diff + a keep/discard one-liner. Your tree is never touched. |

### Models

```bash
tokensmax run claude --fast "rename 12 symbols"                # cheap tier (model_fast)
tokensmax run claude -m claude-sonnet-4-6 "ordinary feature"   # mid, by name
tokensmax run claude "design a sharding scheme"                # deep (default)
tokensmax run codex  --fast "lint pass"                        # low effort; default is high
```

The CLI is **model-agnostic** — it runs whatever you pass with `-m`, no version baked in. Your config
holds the default + fast model; the orchestrator picks other tiers from the provider's current lineup.
`--dry` previews the resolved command and model without running.

Cross-family capability ladder (for tier assignment — names still resolve from `tokensmax status`):
**glm-4.7 < haiku < sonnet < glm-5.2 < opus-4.8**. So `glm-5.2` is a strong $0 worker (use it
mid-to-hard), while `glm-4.7` is the weakest cheap tier — fine for bulk, but **prefer haiku for Phase-0
intake** (glm-4.7 is flaky in non-interactive mode).

### Big tasks get phased, not one-shot

A single huge run can hit a rate limit mid-way and return nothing, can't be reviewed, can't resume. So
a **large** task (broad, multi-subsystem, open-ended) is decomposed into bounded phases with a review
gate between each — surfaced in the proposal, overridable with *"just one-shot it."* Magnitude is the
model's *judgment about scope* — never a hardcoded budget, never a regex on your prompt. Tag a run with
`--est S|M|L` and `usage` shows it against actuals.

### The dispatch policy

Before dispatching, the orchestrator reads [`dispatch-policy.yaml`](./dispatch-policy.yaml) and follows
[`routing.md`](./routing.md): **Phase 0 — ground the goal** (cheapest fast tier `--research --fast` —
prefer haiku — returns a structured read → restate goal+assumptions, or ask 1–3 clarifying questions, and
STOP until you confirm it) → estimate magnitude → match a strategy (`solo` · `parallel-split` ·
`planner-builder` · `cross-check` · `pipeline` · `phased`) → bind roles to engines by `strengths` →
pick the right-sized model → **present options and stop** → on your pick, dispatch + verify. `mode:`
switches between `propose-then-confirm` (default), `auto-announce`, `auto-escalate`.

### Testing & verification

Two tiers — run **Tier 1** on every change; run **Tier 2** when you touch Phase 0 (intake), the routing
policy, or the intake prompt.

**Tier 1 — smoke test (no auth, ~1 s).** `./test.sh` exercises the CLI mechanics with no engine logged
in: argument parsing, `--fast`/`--effort`/`-m` model resolution, the confirm gate (`run`/`fleet` refuse
without `--yes`), `--dry`, and graceful `usage` with no reports.

**Tier 2 — Phase-0 intake eval (needs auth, ~10 min).** `test/intake_eval/` is a gold-labeled,
stratified harness that dispatches each case through the **exact intake prompt** the skill prescribes,
K times, and measures whether the gate behaves. Methodology + latest results in
[`test/intake_eval/FINDINGS.md`](./test/intake_eval/FINDINGS.md); the gist:

- **Dataset:** 16 cases as clear/underspecified pairs + edge slices (terse-clear, ambiguous-complete,
  multi-intent, and the **repo-referencing tool-wander trap**). Methodology: QuestBench pairs
  (arXiv:2503.22674) + Qulac clarification-need (1907.06554).
- **Metrics:** classification **precision/recall/F1** (recall-on-underspecified is the headline — a
  false-clear is the costly error, goal misgeneralization); **schema fidelity** (BFCL-style, ICML'25);
  **tool-restraint** (the overtooling/no-op slice); **pass@k / pass^k** nondeterminism
  (τ-bench 2406.12045, HumanEval 2107.03374); cost.
- **Latest result:** recall(underspecified) **100% on both opencode/glm and claude/haiku** (0
  false-clears); tool-wander **fixed** by the no-tools intake prompt (haiku 0%, glm 2%); schema
  strict-valid 94–100%. Known limits: cheap models **over-ask on terse-clear** requests —
  prompt-intrinsic and a *safe* failure direction; **opencode/glm intermittently returns empty** in
  non-interactive mode (~29%; haiku 0%). It's a regression guard + failure-discovery set (small N, K=3),
  not a population benchmark.

```bash
# Tier 1
./test.sh
# Tier 2 — full run (default engine: opencode)
K=3 ENGINE=opencode python3 test/intake_eval/run_eval.py
# Tier 2 — cross-engine diagnostic on the failure slice
K=2 ENGINE=claude CASES=cases_crosscheck.jsonl python3 test/intake_eval/run_eval.py
```

### Where it helps — and its two blind spots

Headless workers are blind to two things, and pushing tasks into them just burns tokens on confident
wrong answers. The orchestrator is told to *screen for this* and not dispatch into a blind spot:

- ✅ **Sweet spot:** scaffolding/building **from the codebase**, refactors, parallel **review-the-diff**,
  a second opinion on a *code* decision.
- ❌ **Not (by default):** debugging against **live data/systems** (a worker can't reach your DB/API),
  anything needing the **rendered UI**, or work you can already verify directly.

### Live access — let a worker query your real system (gated)

You can lift blind spot #1. Point an engine at the **MCP servers** that reach your live data, then a
worker can actually *query* it instead of guessing:

```ini
[claude]
mcp_config = ~/.config/tokensmax/mcp/labs.json     # MCP servers → your live DB/API/graph
live_tools = mcp__sentinel__* mcp__morpheus__*     # what --live unlocks
```
```bash
tokensmax run claude --review --live "is the tonnage broadcast or per-asset? check InfluxDB, cite the query"
```

Live access is **two gates, not one**: `--live` activates it, but the CLI **refuses to run without
`--grant-live`** — a stronger, separate permission than the normal `--yes`. The orchestrator must ask
you first (*"the worker will hit your live system with your credentials — grant?"*) and only adds
`--grant-live` after you say yes. A human typing `--live` in a terminal is auto-granted. (Codex gets
live tools from its own `codex mcp add` setup, gated the same way.) The **rendered-UI** blind spot is
not lifted — that stays with your eyes.

### Usage, cost, and the quota question

Each run records real tokens and (for Claude) real **$ cost**, rolled into a window total. There is **no
vendor API for remaining session quota** — what you get instead is spend + a **reset time** when a seat
maxes out (the honest ceiling). For a literal "N left", set `session_limit = <tokens>` per engine —
*your* plan's window cap, which you know and the API doesn't.

### What's enforced vs convention

| Mechanism | Real guarantee? |
|---|---|
| `--research` / `--review` read-only | ✅ Claude: no edit/write tools, no Bash. Codex: OS `-s read-only` sandbox. OpenCode/Cursor/Antigravity have no native flag — rely on `--build`'s worktree. |
| `--build` isolation | ✅ git worktree (branch untouched). Codex build is also OS-sandboxed to the worktree; Claude build is git-isolated but not an OS jail — treat the *diff* as the boundary. |
| Account binding | ✅ pinned per engine; a logged-out seat errors, never silently switches. |
| Confirm-before-dispatch | ✅ two layers. The CLI refuses dispatch without `--yes` (stops *accidental* silent runs). For a true human gate, install the **PreToolUse hook** (`hooks/tokensmax-guard.sh`) — Claude Code then **prompts you to approve every dispatch**, since an LLM driving the CLI could otherwise self-confirm. `--dry` + read-only ops aren't gated. |
| `doctor` auth status | ⚠️ heuristic (config present), not a live token check. |
| "tokens left this session" | ❌ not exposed by any vendor — use cost + reset, or set `session_limit`. |

### Credentials & plan terms

Share the **tooling**, never a **login** — each user signs into their own seat; copying someone else's
`~/.claude` / `~/.codex` shares a token (ToS + security) and scrambles billing. "Both seats busy" only
saves money with **separate billing seats**. Scheduled/unattended bulk load against *interactive
subscription* seats is a **ToS gray area** — the **API** is the sanctioned path for automation.

### Troubleshooting

| Symptom | Fix |
|---|---|
| `command not found` | add `~/.local/bin` to PATH, re-open the shell |
| `no config — run: tokensmax init` | run `tokensmax init` |
| an engine shows `✗` in `doctor` | log into that seat, then `tokensmax auth` |
| `refusing to dispatch without confirmation` | by design — pick a plan, then it re-runs with `--yes` |
| empty report + `⚠ limit` | that seat is rate-limited; `usage` shows the reset — use the other seat or `--fast` |
| Codex rejects `-m gpt-5-codex` | ChatGPT-plan Codex runs plan models only; use `gpt-5.5`, dial depth with effort |
| Claude report is raw JSON | install `python3` (formats the result + captures tokens/cost) |
| want "tokens left" | set `session_limit = <tokens>` per engine (no API exposes quota) |

### Config

`~/.config/tokensmax/engines.conf` (see [`engines.conf.example`](./engines.conf.example)) declares each
engine: `driver`, auth location, `model` / `model_fast`, `effort` / `effort_fast`, `strengths`, optional
`session_limit`. Keys go in `secrets.env` (never committed). `tokensmax init` writes it for you.

Run `./test.sh` for a no-auth smoke test; see **Testing & verification** above for the full two-tier
strategy (incl. the Phase-0 intake eval).
