#!/usr/bin/env bash
# tokensmax PreToolUse guard (Claude Code hook).
#
# Forces a HUMAN approval prompt before any real dispatch — `tokensmax run` / `tokensmax fleet`
# without `--dry` — even under auto-accept. This is the only layer that can pause a human while the
# orchestrating LLM drives the CLI (the CLI itself can't; the LLM is its caller). Read-only ops
# (status/usage/doctor/list/init) and `--dry` previews pass straight through.
#
# Generic by design: it gates the dispatch VERB, not any specific engine, model, or subscription.
#
# Install: copy to ~/.claude/hooks/ and register under hooks.PreToolUse (matcher "Bash") in
# ~/.claude/settings.json — see the snippet printed by install.sh / the skill README.

input="$(cat)"
# Extract the Bash command (python3 if present; else scan the raw JSON so the guard still fires).
cmd="$(printf '%s' "$input" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)"
[ -z "$cmd" ] && cmd="$input"

is_dispatch() { printf '%s' "$cmd" | grep -qE '(^|[^A-Za-z0-9_/.])tokensmax[[:space:]]+(run|fleet)([[:space:]]|$)'; }
is_dry()      { printf '%s' "$cmd" | grep -qE -- '(^|[[:space:]])--dry([[:space:]]|$)'; }

if is_dispatch && ! is_dry; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"tokensmax dispatch — review the engine/model/path in the command and approve before it runs. (Read-only ops and --dry are not gated.)"}}'
fi
exit 0
