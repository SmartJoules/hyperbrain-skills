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

## Honest limits

- **`--build` isolation** is at the git-worktree level (review the diff, keep/discard). Codex build is
  additionally OS-sandboxed to the worktree; Claude build is **not** an OS jail — treat the *diff* as the boundary.
- **`doctor` auth** is a heuristic (config present), not a live token check; validity confirms on first run.
- **No "tokens left this session"** is exposed by any vendor — `usage` shows actual tokens + $ + the
  **reset time** when a seat maxes out; set `session_limit = <tokens>` per engine for a "N left" readout.
- **Read-only** (`--research`/`--review`): Claude has no edit/write tools and no Bash; Codex uses an
  OS `-s read-only` sandbox. OpenCode/Cursor/Antigravity have no native flag — rely on `--build`'s worktree.
