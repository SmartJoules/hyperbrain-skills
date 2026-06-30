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

"$TM" usage >/dev/null 2>&1 && ok "usage (no reports) graceful" || no "usage errored on empty"

echo "── $pass passed, $fail failed ──"
[[ $fail -eq 0 ]]
