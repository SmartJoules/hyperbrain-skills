# Enforcement & honest limits

## The `--yes` confirm gate (CLI)

`tokensmax run|fleet` **refuse to dispatch without `--yes`** when run non-interactively (i.e. by the
orchestrator). Add `--yes` only *after* the user picked an option. `--dry` previews the resolved
command/model without running. This stops *accidental* silent dispatch — but since an LLM operates the
CLI, a determined caller can self-confirm, so it is **not** a hard human lock.

## The real human gate — the hook

For a true pause-before-dispatch, register the bundled PreToolUse hook. Copy `hooks/tokensmax-guard.sh`
to `~/.claude/hooks/` and add to `~/.claude/settings.json`:

```json
"hooks": { "PreToolUse": [ { "matcher": "Bash",
  "hooks": [ { "type": "command", "command": "$HOME/.claude/hooks/tokensmax-guard.sh" } ] } ] }
```

Claude Code then **prompts the user to approve every `run|fleet` dispatch** (showing engine/model/path),
even under auto-accept; `--dry` and read-only ops pass through. This is the only layer that can pause a
human while an LLM drives the CLI — the CLI itself can't (the LLM is its caller).

## The frictionless choice — allow the CLI (recommended for interactive use)

The hook above is the *paranoid* setting: a hard pause before every dispatch. For normal interactive
use the meaningful confirm is already the **route-picker** (AskUserQuestion) plus the `--yes` gate — a
raw Bash-approval prompt on top of that is redundant friction. Allow the CLI in `~/.claude/settings.json`:

```json
{ "permissions": { "allow": [
  "Bash(tokensmax:*)",
  "Bash(git merge --no-ff:*)",
  "Bash(git apply:*)"
] } }
```

`Bash(tokensmax:*)` covers the entire dispatch — tokensmax's workers (git worktree, `codex exec`,
`claude -p`) run as **child processes** of the CLI, not as separate Bash tool calls, so Claude Code's
permission layer only ever sees the one `tokensmax …` invocation. The two `git` rules let you accept a
build (the printed `merge`/`apply`) without a prompt. Settings load at session start — open a fresh
session. Pick **one** model: this allow-rule (gate = the picker) *or* the hook (gate = a hard pause);
installing both means the hook still prompts.

## Honest limits

- **`--build` isolation** is at the git-worktree level (review the diff, keep/discard). Codex build is
  additionally OS-sandboxed to the worktree; Claude build is **not** an OS jail — treat the *diff* as the boundary.
- **`doctor` auth** is a heuristic (config present), not a live token check; validity confirms on first run.
- **No "tokens left this session"** is exposed by any vendor — `usage` shows actual tokens + $ + the
  **reset time** when a seat maxes out; set `session_limit = <tokens>` per engine for a "N left" readout.
- **Read-only** (`--research`/`--review`): Claude has no edit/write tools and no Bash; Codex uses an
  OS `-s read-only` sandbox. OpenCode/Cursor/Antigravity have no native flag — rely on `--build`'s worktree.
