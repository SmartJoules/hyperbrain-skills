#!/usr/bin/env bash
# tokensmax lib: status — model-ladder fetch · session briefing
# Sourced by bin/tokensmax (not run directly). Uses globals/helpers
# (cfg, die, exp, REPORTS, WORKTREES, QUEUE, prompt_*, cmd_run, require_conf) from the entrypoint.

ctx_for(){ # model -> per-request context window (the honest "potential" per call)
  case "$1" in
    *opus*|*sonnet*|*fable*) echo "1M" ;;
    *haiku*)                 echo "200K" ;;
    *glm-4*)                 echo "~128K" ;;
    gpt-5*|*gpt-4*)          echo "~256K" ;;
    *)                       echo "—" ;;
  esac
}
# FETCH the real model ladder from the installed claude (the same source `/model` reads) — not hardcoded,
# not config: current families + latest version each. Empty if claude isn't installed there.
claude_ladder(){
  local d="$HOME/.local/share/claude/versions" latest bin f fam tier m out=""
  latest="$(ls "$d" 2>/dev/null | sort -V | tail -1)"; [[ -n "$latest" ]] || return 1
  bin="$d/$latest"; [[ -e "$bin" ]] || return 1
  for f in haiku:cheap sonnet:mid opus:deep fable:max; do
    fam="${f%%:*}"; tier="${f##*:}"
    m="$(grep -oaE "claude-$fam-[0-9]+-[0-9]+" "$bin" 2>/dev/null | grep -vE '[0-9]{6}' | sort -uV | tail -1)"
    [[ -n "$m" ]] && out="$out · $tier $m"
  done
  [[ -n "$out" ]] && echo "${out# · }"
}
# GLM / any anthropic-compatible API: fetch the live model list from the endpoint (the real source).
api_models(){ # <engine>
  local base ke key; base="$(cfg "$1" base_url)"; ke="$(cfg "$1" key_env)"
  [[ -n "$base" && -n "$ke" ]] || return 1
  have curl && have python3 || return 1
  load_secrets; key="${!ke:-}"; [[ -n "$key" ]] || return 1
  curl -fsS --max-time 6 -H "x-api-key: $key" -H "authorization: Bearer $key" -H "anthropic-version: 2023-06-01" \
    "${base%/}/v1/models" 2>/dev/null | python3 -c 'import sys,json
try:
 d=json.load(sys.stdin); ids=[m.get("id","") for m in d.get("data",[]) if m.get("id")][:8]
 sys.stdout.write(" · ".join(ids))
except Exception: pass'
}
# Cursor: read model IDs the installed cursor-agent knows (best-effort).
cursor_ladder(){
  local cb; cb="$(command -v cursor-agent 2>/dev/null)" || return 1
  cb="$(readlink -f "$cb" 2>/dev/null || echo "$cb")"
  grep -oaE '(claude|gpt|gemini|o[0-9])[a-z0-9.-]{2,}' "$cb" 2>/dev/null | sort -u | head -6 \
    | awk '{printf "%s%s",(NR>1?" · ":""),$0} END{if(NR)print""}'
}
# The models display per engine — FETCHED from each engine's real source where one exists.
model_line(){ # <engine> <driver>
  local e="$1" d="$2" lad
  case "$d" in
    claude)        lad="$(claude_ladder)";  [[ -n "$lad" ]] && { echo "$lad   (fetched: claude install)"; return; } ;;
    anthropic-api) lad="$(api_models "$e")"; [[ -n "$lad" ]] && { echo "$lad   (fetched: ${e} /v1/models)"; return; } ;;
    cursor)        lad="$(cursor_ladder)";   [[ -n "$lad" ]] && { echo "$lad   (from cursor-agent)"; return; } ;;
    codex)         echo "model $(cfg "$e" model) · depth = effort low|medium|high|xhigh   (ChatGPT plan: one model, no list to fetch)"; return ;;
  esac
  local m mf mid; m="$(cfg "$e" model)"; mf="$(cfg "$e" model_fast)"; mid="$(cfg "$e" model_mid)"
  echo "deep ${m:-built-in}${mid:+ · mid $mid}${mf:+ · cheap $mf} · other tiers via -m"
}
cmd_status(){ # session-start briefing: subscriptions, models, what-for, per-call potential
  require_conf
  echo "tokensmax fleet — orchestrating from this session:"
  local e d seat m mf eff strg
  for e in $(engines); do
    d="$(cfg "$e" driver)"; m="$(cfg "$e" model)"; mf="$(cfg "$e" model_fast)"
    eff="$(cfg "$e" effort)"; strg="$(cfg "$e" strengths)"
    case "$d" in
      claude)        seat="$(cfg "$e" config_dir)"; [[ -n "$seat" ]] || seat="default seat (~/.claude.json)" ;;
      codex)         seat="$(cfg "$e" codex_home)"; [[ -n "$seat" ]] || seat="$HOME/.codex" ;;
      anthropic-api) seat="API key: $(cfg "$e" key_env)" ;;
      opencode)      seat="$(cfg "$e" opencode_data)" ;;
      *)             seat="$d" ;;
    esac
    printf '\n  ● %-10s (%s)\n' "$e" "$d"
    printf '      account  : %s\n' "$seat"
    printf '      models   : %s\n' "$(model_line "$e" "$d")"
    printf '      default  : %s%s%s\n' "${m:-built-in}" "${mf:+, fast=$mf}" "${eff:+, effort=$eff}"
    printf '      used for : %s\n' "${strg:-—}"
    printf '      potential: %s context per request\n' "$(ctx_for "$m")"
  done
  echo
  echo "  'potential' is the per-request context window above. Live remaining quota on a subscription seat"
  echo "  is NOT queryable by anyone — run \`tokensmax usage\` for ACTUAL tokens + cost(\$) spent + ⚠ + reset when maxed."
}
