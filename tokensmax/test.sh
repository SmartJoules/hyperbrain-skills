#!/usr/bin/env bash
# tokensmax smoke test — no engine login required. Exercises parsing, --dry resolution, the
# confirm gate, and graceful empty-usage, against a throwaway config. Run: ./test.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TM="$HERE/bin/tokensmax"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
export TOKENSMAX_HOME="$tmp/conf" TOKENSMAX_REPORTS="$tmp/reports"
mkdir -p "$TOKENSMAX_HOME"
cat > "$TOKENSMAX_HOME/engines.conf" <<'EOF'
[claude]
driver = claude
model = claude-opus-4-8
model_fast = claude-haiku-4-5
strengths = design
[codex]
driver = codex
model = gpt-5.5
effort = high
effort_fast = low
strengths = logic
EOF

pass=0; fail=0
ok(){ printf '  ✓ %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  ✗ %s\n' "$1"; fail=$((fail+1)); }

echo "tokensmax smoke test"
bash -n "$TM"            && ok "syntax"  || no "syntax"
"$TM" help   >/dev/null 2>&1 && ok "help"   || no "help"
"$TM" list   >/dev/null 2>&1 && ok "list"   || no "list"
"$TM" status >/dev/null 2>&1 && ok "status" || no "status"

out="$("$TM" run claude --dry "x" 2>&1)"
[[ "$out" == *"claude -p"* && "$out" == *"--output-format json"* ]] && ok "claude --dry resolves" || no "claude --dry: $out"

out="$("$TM" run codex --fast --dry "x" 2>&1)"
[[ "$out" == *"codex exec"* && "$out" == *"model_reasoning_effort=low"* ]] && ok "codex --fast → low effort" || no "codex --fast --dry: $out"

# the confirm gate: a non-interactive dispatch with no --yes MUST refuse (before any engine call)
if "$TM" run codex "x" </dev/null >/dev/null 2>&1; then no "gate must refuse without --yes"; else ok "gate refuses dispatch without --yes"; fi
"$TM" run codex --dry "x" </dev/null >/dev/null 2>&1 && ok "gate allows --dry" || no "gate blocked --dry"

# unknown flags must be REJECTED loudly, not silently mis-parsed as the engine/prompt
if "$TM" run claude --research --tools=none "x" </dev/null >/dev/null 2>&1; then no "unknown flag must be rejected"; else ok "unknown flag rejected"; fi

"$TM" usage >/dev/null 2>&1 && ok "usage (no reports) graceful" || no "usage errored on empty"

# watch: no in-flight dispatches must exit 0 with the empty-state message, not error
"$TM" watch >/dev/null 2>&1 && ok "watch (nothing in flight) graceful" || no "watch errored on empty"

# kill: no args → loud usage error; `kill all` with nothing live → graceful no-op
if "$TM" kill </dev/null >/dev/null 2>&1; then no "kill without args must error"; else ok "kill without args errors"; fi
[[ "$("$TM" kill all 2>/dev/null)" == *"nothing to stop"* ]] && ok "kill all (nothing live) graceful" || no "kill all errored on empty"

# help must print ONCE and instantly (a backtick in an unquoted heredoc once made it fork-bomb)
h="$("$TM" help 2>/dev/null)"
[[ "$(printf '%s' "$h" | grep -c 'orchestrate multiple')" == 1 && "$h" == *'`usage`'* ]] \
  && ok "help prints once, backticks literal" || no "help output wrong (recursion or missing lines)"

# failure visibility: a failing engine must leave a ⚠ FAILED footer + non-zero exit — fg AND bg
# (set -e once aborted cmd_run before the footer; the bg subshell died silently and watch said ✓)
mkdir -p "$tmp/stub"; printf '#!/bin/bash\necho partial; exit 3\n' > "$tmp/stub/codex"; chmod +x "$tmp/stub/codex"
if PATH="$tmp/stub:$PATH" "$TM" run codex --yes "fg fail probe" </dev/null >/dev/null 2>&1; then
  no "fg engine failure must exit non-zero"
else
  grep -rq 'FAILED (exit 3)' "$TOKENSMAX_REPORTS" && ok "fg failure footer written" || no "fg failure footer missing"
fi
printf '#!/bin/bash\necho partial; exit 4\n' > "$tmp/stub/codex"
PATH="$tmp/stub:$PATH" "$TM" run codex --bg --yes "bg fail probe" </dev/null >/dev/null 2>&1; sleep 1
grep -rq 'FAILED (exit 4)' "$TOKENSMAX_REPORTS" && ok "bg failure footer written" || no "bg failure footer missing"

# queue task files are NUL-delimited data, never eval'd; a $(...) in a task must survive as a literal
export TOKENSMAX_QUEUE="$tmp/queue"
"$TM" queue add codex 'task with $(dangerous) chars' >/dev/null 2>&1
qf="$(ls "$tmp/queue/pending/"*.task 2>/dev/null | head -1)"
if [[ -n "$qf" ]] && [[ "$(tr '\0' '\n' < "$qf" | tail -1)" == 'task with $(dangerous) chars' ]]; then
  ok "queue stores args verbatim (no eval)"
else no "queue task format wrong"; fi
printf '#!/bin/bash\nexit 0\n' > "$tmp/stub/codex"
if PATH="$tmp/stub:$PATH" "$TM" queue run </dev/null >/dev/null 2>&1 && ls "$tmp/queue/done/"*.task >/dev/null 2>&1; then
  ok "queue run NUL roundtrip → done/"
else no "queue run failed on NUL task"; fi

# LIVE gate: --live must refuse without an explicit --grant-live (a TTY is not consent)
if "$TM" run codex --live --yes "live probe" </dev/null >/dev/null 2>&1; then
  no "LIVE without --grant-live must refuse"
else ok "LIVE gate requires explicit --grant-live"; fi

# workflow: init writes examples, list shows them, show prints one (no dispatch).
# Capture output via $(...) rather than `| grep -q`: a multi-line producer piped into an
# early-exiting grep -q gets SIGPIPE (141), which `set -o pipefail` would surface as a failure.
export TOKENSMAX_WORKFLOWS="$tmp/wf"
if "$TM" workflow init >/dev/null 2>&1 \
   && [[ "$("$TM" workflow list 2>/dev/null)" == *build-review* ]] \
   && [[ "$("$TM" workflow show build-review 2>/dev/null)" == *"step:"* ]] \
   && "$TM" workflow run --help >/dev/null 2>&1; then
  ok "workflow init/list/show/help"
else no "workflow init/list/show/help"; fi

echo "── $pass passed, $fail failed ──"
[[ $fail -eq 0 ]]
