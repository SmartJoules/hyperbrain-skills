# HyperBrain Skills — Install & Usage Guide

How to install these skills into your AI assistant, and **which skill to use when**.

There are **37 skills**. With Claude Code they activate automatically based on the task
(via each skill's `description`). With Codex/Cursor/Copilot they're indexed in a
generated `AGENTS.md` and opened on demand.

---

## Part 1 — Installation

### 1A. Claude Code (recommended path)

The installer copies each skill into its own folder under `~/.claude/skills/`,
which is exactly what Claude Code expects.

```bash
git clone https://github.com/SmartJoules/hyperbrain-skills.git /tmp/hyperbrain-skills
cd /tmp/hyperbrain-skills
./install.sh

# Restart Claude Code — skills are immediately available
```

**Manual (per-skill copy).** Each skill is a directory with a `SKILL.md`; Claude Code
registers it by the `name` in the frontmatter and needs one folder per skill. Do **not**
clone the repo straight into `~/.claude/skills`, and do **not** `cp -r repo/* ...`
(that copies top-level docs and `.git` as junk):

```bash
git clone https://github.com/SmartJoules/hyperbrain-skills.git /tmp/hyperbrain-skills
mkdir -p ~/.claude/skills
find /tmp/hyperbrain-skills -name SKILL.md -not -path '*/.git/*' | while read -r f; do
  d="$(dirname "$f")"
  cp -r "$d" ~/.claude/skills/"$(basename "$d")"
done
# Restart Claude Code
```

### 1B. Pi (pi.dev)

Pi uses the **same `SKILL.md` format as Claude Code** (a directory per skill with
`name` + `description` frontmatter), discovered under `~/.pi/agent/skills/`. So every
skill works in Pi unchanged.

```bash
git clone https://github.com/SmartJoules/hyperbrain-skills.git /tmp/hyperbrain-skills
cd /tmp/hyperbrain-skills
./install.sh --assistant pi
```

Skills load automatically (Pi advertises available skills in its system prompt) or on
demand via `/skill:<name>`. A skill's `bin/` CLI installs to `~/.local/bin`; slash
`commands/` install to `~/.pi/agent/commands/`. To install one skill by hand:
`cp -r <skill> ~/.pi/agent/skills/<skill>`.

### 1C. Codex / Cursor / Copilot

These have no native `SKILL.md` registry, so the installer puts the skills under
`skills/<name>/SKILL.md` **and generates an `AGENTS.md`** index (which Codex auto-reads).

```bash
./install.sh --assistant codex     # or: cursor | copilot
# Then point the agent at the generated AGENTS.md, e.g.:
cp ~/.codex/skills/AGENTS.md /path/to/your/repo/AGENTS.md
```

The generated `AGENTS.md` lists every skill with its description and bakes in the
mandatory engineering standards. The agent opens the matching `skills/<name>/SKILL.md`
for the task at hand.

### 1D. Update / re-install

Re-run `./install.sh` (it backs up the existing skills first).
Default install dir per assistant: `~/.claude/skills`, `~/.pi/agent/skills`,
`~/.cursor/skills`, `~/.copilot/skills`, `~/.codex/skills`. Override with `--dir`.
Skip backup with `--skip-backup`.

### 1E. Verify it worked

```bash
ls ~/.claude/skills        # each skill is its own folder containing SKILL.md
ls ~/.claude/skills/engineering-standards/SKILL.md
```

In Claude Code, ask something matching a skill (e.g. "scaffold a new endpoint in
jt-api-v2") and the relevant skill should engage. If a skill never triggers, check that
its `SKILL.md` starts with valid YAML frontmatter (`---` + `name:` + `description:`).

---

## Part 2 — Which Skill When

### 2.1 Always-on (apply to most coding tasks)

| Skill | Use it… |
|-------|---------|
| **engineering-standards** | On **every** code change — SOLID, design patterns, DRY/KISS/minimal-diff, no leaks/unhandled promises, error/loading/empty/partial states, caching with eviction, Kafka/Redis connection rules. The non-negotiable quality gate. |
| **superpowers-brainstorm** | At the **start** of a new task/feature — clarify requirements, break down the problem, weigh approaches before coding. |
| **expert-personas** | When a task benefits from a specific senior lens (PM for a PRD, design engineer for UI, SRE for infra, QA for tests). |

### 2.2 Starting / scoping work

| Situation | Skill |
|-----------|-------|
| "Build/scaffold a backend API, service, repository, DTO, feature" | **engineering-ai-assistant** (discovers DB schema + repo patterns, generates production-ready code in the project's style) |
| Any codegen where the agent should first detect the repo + bind to its real stack | **prompt-harness** |
| A task too big for one context window (multi-file, migration, repo-wide refactor) | **agentic-engineering** (retrieve-don't-read + planner→scoped-sub-agents; keeps token cost down) |
| "What algorithm / data structure should I use?" | **algorithm-picker** |
| New to the codebase / need orientation | **jouletrack-onboarding**, **jouletrack-library** (index), **dejoule-knowledge-base** |

### 2.3 Frontend

| Building… | Skill |
|-----------|-------|
| Angular (JouleTRACK) components/services/dashboards | **jouletrack-angular** |
| Angular UI styling / visual consistency | **ui-ux-design** |
| React components/hooks/state | **react-patterns** |
| Vue 3 (Composition API) | **vue-patterns** |
| Next.js apps (routing, data fetching, API routes) | **nextjs-patterns** |
| State management (Redux/Zustand/Pinia/NgRx) | **state-management** |
| A PRD/spec → clickable HTML mockup in the JouleTRACK look | **prd-to-html-prototype** |

### 2.4 Backend

| Building… | Skill |
|-----------|-------|
| jt-api-v2 backend (architecture/conventions) | **backend-knowledge-base** |
| Node.js / Express services | **nodejs-patterns** |
| Python / FastAPI services | **python-patterns** |
| Go / Gin services | **go-patterns** |
| Schema design / migrations / data modeling | **database-patterns** |

### 2.5 Databases & performance

| Situation | Skill |
|-----------|-------|
| "Why is this query slow / make it faster" — PostgreSQL, DynamoDB, MongoDB, InfluxDB, Redis; interpret EXPLAIN/explain() | **database-query-optimizer** |
| InfluxDB time-series queries / measurement & tag design | **influxdb-patterns** |
| General schema/query design | **database-patterns** |

### 2.6 IoT / streaming

| Working on… | Skill |
|-------------|-------|
| IoT system architecture (device → ingestion → cloud) | **iot-architecture** |
| IoT platform context (ingestion, device mgmt, telemetry) | **iot-knowledge-base** |
| Kafka producers/consumers/topics/streams | **kafka-patterns** |
| MQTT topics/payloads/QoS | **mqtt-patterns** |

### 2.7 Testing & QA

| Situation | Skill |
|-----------|-------|
| Writing a feature/bugfix the TDD way (80%+ coverage) | **tdd-workflow** |
| E2E tests with Playwright | **playwright-patterns** |
| Test strategy / QA coverage planning | **qa-automation** |

### 2.8 Context, tokens & MCP (the efficiency layer)

| Want to… | Skill |
|----------|-------|
| Map a repo into a queryable graph (low-token context) | **graphify-integration** |
| Precompute & cache a repo's structure as a local KB | **local-kb** |
| Run large work cheaply (orchestration + budgets) | **agentic-engineering** |
| Install the HyperBrain MCP servers | **mcp-installer** |
| Configure / troubleshoot MCP servers | **mcp-setup** |
| Turn a specific MCP server on only when a step needs it | **mcp-on-demand** |
| Have the assistant remember your preferences/patterns | **self-learning** |

---

## Part 3 — How Skills Compose

Most real tasks use **several** skills together. Typical flows:

- **New backend feature (large):**
  `superpowers-brainstorm` → `agentic-engineering` (plan + scoped sub-agents) →
  `prompt-harness`/`engineering-ai-assistant` (generate, repo-aware) →
  `database-patterns`/`influxdb-patterns` for data →
  `engineering-standards` (always) → `tdd-workflow` (tests).

- **New frontend screen from a PRD:**
  `expert-personas` (design engineer) → `prd-to-html-prototype` (mock) →
  `jouletrack-angular` + `ui-ux-design` (real build) → `engineering-standards`.

- **Slow query / perf issue:**
  `database-query-optimizer` (diagnose + rewrite) →
  `influxdb-patterns`/`database-patterns` (store-specific) →
  `algorithm-picker` if the approach itself is wrong → `engineering-standards`.

- **Onboarding to a repo:**
  `jouletrack-onboarding`/`dejoule-knowledge-base` →
  `graphify-integration`/`local-kb` (build low-token context) → then start work.

> **Rule of thumb:** `superpowers-brainstorm` to start, `engineering-standards` always,
> the domain skill(s) for the stack, and `agentic-engineering` whenever the task is big.
> Skip the heavy skills for trivial one-line edits (KISS).

---

## Part 4 — Multi-Agent & Multi-Skill Orchestration

For work too big for one agent/context: run **several agents in parallel/sequence**, each scoped tight. The skills that make this work (use them together):

| Step | Skill |
|------|-------|
| Decide solo vs fleet; plan the decomposition | **agentic-engineering** (the operating model) + **agent-orchestration** |
| Write each agent a tight brief (goal, files, contract, allowed tools, stop condition) | **agent-delegation-contracts** |
| Give each agent only its minimal context (no leakage, token budget per agent) | **agent-context-manager** |
| Actually dispatch the workers (parallel, model tiers, worktree-isolated writes) | **agent-fleet-runner** + **tokensmax** (CLI) |
| Merge/reconcile the agents' outputs, resolve conflicts, final verify | **agent-integration-reviewer** |

### Multi-agent playbook
1. **Plan** ([[agentic-engineering]] + agent-orchestration): break the task into **independent, scoped sub-tasks**, each with `{goal, the 1–5 files it touches, input, expected output/contract, done-criteria}`. Mark dependencies so independents run in parallel.
2. **Brief** (agent-delegation-contracts): each sub-agent gets ONLY its goal + its files + the one relevant skill (e.g. `jouletrack-angular`) + the contract — never "the whole codebase".
3. **Dispatch** (agent-fleet-runner / tokensmax): run independent sub-agents **in parallel**, sequence only real dependencies; right-size the model per task (cheap for mechanical, strong for hard); writes go in isolated worktrees so they don't collide.
4. **Each agent returns a structured result** (files changed + summary + new contracts) — NOT its whole transcript. The orchestrator keeps the plan + results, not the union of everything.
5. **Integrate & verify** (agent-integration-reviewer): stitch results, reconcile cross-task contracts, run build/tests, diff-only review against [[engineering-standards]]; re-scope only the sub-tasks that fail.

### Multi-skill on one task
Most real tasks chain skills (see Part 3). The pattern: **brainstorm → plan → the domain skill(s) for the stack → engineering-standards (always) → tests → review**. You can name several explicitly ("use software-architecture-planner then code-reviewer"); skills also auto-load by description. Keep only the skills relevant to the current step in context.

### tokensmax fleet (CLI, across your seats)
`/tokensmax <task>` orchestrates Claude + Codex (+ GLM/OpenCode/Cursor) as a headless fleet — proposes routing options across seats/tiers, dispatches the chosen plan, reports cost. Read-only by default; writes worktree-isolated; nothing dispatches until you pick a plan. For unattended/long work: `tokensmax queue add|run`, `--bg`, and `schedule`. See the **tokensmax** skill.

> **When NOT to go multi-agent:** a single-file or <3-step change. The orchestration overhead (briefs, integration) costs more than it saves (KISS).

---

## Part 5 — Low-Token Mode (cheaper runs)

The lever isn't "use a smaller model" — it's **read less into context and offload**. Full operating model: **agentic-engineering**. The moves, in order of impact:

1. **Retrieve, don't read.** Pull *precomputed, summarized* context first — `graphify-out/GRAPH_REPORT.md` ([[graphify-integration]]), `ai-context/*`, a repo's local KB ([[local-kb]]), and the relevant hyperbrain KB skill — instead of opening source "to understand". Summaries are 10–100× cheaper than files.
2. **Targeted reads only.** grep for the symbol/route/class and read the matching lines + a small window; read the one function you'll change, not the 800-line file. Full-file read is a last resort.
3. **Set a context budget per phase** and **summarize-and-discard**: after reading something large, write a 3–5 line note (what it does, the contract, the gotcha) and drop the source from context. Compact at phase boundaries. Avoid the last ~20% of the window for heavy multi-file work — decompose instead.
4. **Decompose + scope** (Part 4): total tokens scale with **#sub-tasks, not files × tasks**, because each agent holds only its slice. This is the biggest structural saving on large work.
5. **Right-size the model** (tokensmax tiers / model routing): cheap model for classification/lookups/mechanical edits, strong only for hard reasoning/verification. Don't run Opus on a rename.
6. **MCP on demand** ([[mcp-on-demand]]): enable a heavy MCP server only for the step that needs it; don't hold them all open.
7. **Tight prompts** ([[prompt-engineering]]): prompt caching for the stable prefix; truncate tool/retrieved results to what's needed; no redundant re-statements.
8. **Persist** (self-learning / project memory): record decisions/contracts so the *next* run reads even less.

### Quick low-token checklist
- [ ] Used graphify/ai-context/KB BEFORE reading any source
- [ ] Targeted symbol/grep reads, not whole files
- [ ] Per-phase budget; summarized-and-discarded big reads
- [ ] Decomposed large work into scoped sub-agents (Part 4)
- [ ] Model tier matched to task difficulty
- [ ] MCP enabled only where needed; prompts tight + cached

> One-liner: **"Retrieve don't read · decompose don't accumulate · cheap model unless it's hard."**

---

For the full skill list with one-line summaries, see the [README](README.md).
For how to call agents/skills + the full catalog, see [AGENTS_AND_SKILLS.md](AGENTS_AND_SKILLS.md).
For the install/usage doc that ships to the JouleTRACK & jt-api-v2 repos, see
`docs/HYPERBRAIN_SKILLS.md` in those repos.
