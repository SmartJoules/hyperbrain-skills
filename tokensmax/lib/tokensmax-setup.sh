#!/usr/bin/env bash
# tokensmax lib: setup — CLI/seat discovery · auth · doctor · list · init
# Sourced by bin/tokensmax (not run directly). Uses globals/helpers
# (cfg, die, exp, REPORTS, WORKTREES, QUEUE, prompt_*, cmd_run, require_conf) from the entrypoint.

antigravity_cli(){  # echo absolute path to the antigravity-ide binary, or empty
  if have antigravity-ide; then command -v antigravity-ide
  elif [[ -x "/Applications/Antigravity IDE.app/Contents/Resources/app/bin/antigravity-ide" ]]; then
    printf '%s' "/Applications/Antigravity IDE.app/Contents/Resources/app/bin/antigravity-ide"
  fi
}
cli_for_driver(){  # echo the CLI binary name an engine driver uses
  case "$1" in
    claude|anthropic-api) echo claude ;;
    codex) echo codex ;;
    cursor) echo cursor-agent ;;
    opencode) echo opencode ;;
    antigravity) antigravity_cli ;;
    *) echo "" ;;
  esac
}

# list logged-in Claude seats: "<config_dir>\t<label>"
discover_claude_seats(){
  local f
  # 1. default seat — creds live at ~/.claude.json (NOT inside ~/.claude/)
  f="$HOME/.claude.json"
  if [[ -f "$f" ]] && grep -q '"oauthAccount"' "$f" 2>/dev/null; then
    printf '%s\t%s\n' "$HOME/.claude" "default seat (creds: ~/.claude.json)"
  fi
  # 2. custom / enterprise seats — creds live inside <dir>/.claude.json
  #    The glob ~/.claude-* covers ~/.claude-enterprise, ~/.claude-team, etc.
  #    Dedup via array (paths may contain spaces); no explicit literal entry (avoids double-print).
  local -a seen=()
  local g match s
  for g in "$HOME"/.claude-*/ ; do
    [[ -e "$g" ]] || continue
    g="${g%/}"
    is_claude_default "$g" && continue
    match=0
    for s in "${seen[@]+"${seen[@]}"}"; do [[ "$s" == "$g" ]] && { match=1; break; }; done
    [[ $match -eq 1 ]] && continue
    if [[ -f "$g/.claude.json" ]] && grep -q '"oauthAccount"' "$g/.claude.json" 2>/dev/null; then
      printf '%s\t%s\n' "$g" "custom seat (creds: $g/.claude.json)"; seen+=("$g")
    fi
  done
}

opencode_data_default(){ printf '%s/.local/share/opencode' "$HOME"; }
opencode_has_auth(){
  local data f
  data="${1:-$(opencode_data_default)}"; f="$data/auth.json"
  [[ -f "$f" ]] && grep -qE '"(key|access_token|refresh_token|apiKey)"' "$f" 2>/dev/null
}
# Best-effort default provider name from opencode auth.json (first key whose value is an object
# carrying a credential). Prefers python3 JSON parsing; falls back to a grep heuristic.
opencode_default_provider(){
  local f="$1"
  [[ -f "$f" ]] || return 0
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$f" <<'PY' 2>/dev/null
import json,sys
try:
    d=json.load(open(sys.argv[1]))
    for k,v in d.items():
        if isinstance(v,dict) and any(x in v for x in ("key","access_token","refresh_token","apiKey")):
            print(k); break
except Exception:
    pass
PY
  else
    grep -oE '"[A-Za-z0-9_.-]+"[[:space:]]*:[[:space:]]*\{' "$f" | head -1 | sed -E 's/[":{[:space:]]//g'
  fi
}

# ---- auth checks (heuristic; validity confirmed on first real run) ----
auth_status(){ # <engine> -> single line status (no header)
  local e="$1" d; d="$(cfg "$e" driver)"; load_secrets
  case "$d" in
    claude)
      # heuristic: oauthAccount presence in the REAL creds file (default ~/.claude.json, or <dir>/.claude.json for a custom seat)
      local cd_ creds; cd_="$(cfg "$e" config_dir)"; creds="$(claude_creds_path "$cd_")"
      if [[ -f "$creds" ]] && grep -q '"oauthAccount"' "$creds" 2>/dev/null; then
        echo "~ configured ($creds) — validity confirmed on first run"
      else
        if is_claude_default "$cd_"; then
          echo "✗ no login at $creds — run: claude   then /login, then /exit"
        else
          echo "✗ no login at $creds — run: CLAUDE_CONFIG_DIR=\"$cd_\" claude   then /login, then /exit"; fi
      fi ;;
    codex)
      local home; home="$(cfg "$e" codex_home)"; [[ -z "$home" ]] && home="$HOME/.codex"
      if CODEX_HOME="$home" codex login status >/dev/null 2>&1; then echo "✓ logged in ($home)"; else
        echo "✗ run:  CODEX_HOME=\"$home\" codex login"; fi ;;
    anthropic-api)
      local ke; ke="$(cfg "$e" key_env)"
      if [[ -n "${!ke:-}" ]]; then echo "✓ key present ($ke)"; else
        echo "✗ add key:  echo '$ke=YOUR_KEY' >> \"$SECRETS\" && chmod 600 \"$SECRETS\""; fi ;;
    cursor)
      if have cursor-agent && cursor-agent status >/dev/null 2>&1; then echo "✓ logged in"; else
        echo "✗ install cursor-agent + run:  cursor-agent login"; fi ;;
    opencode)
      local data; data="$(cfg "$e" opencode_data)"; [[ -z "$data" ]] && data="$(opencode_data_default)"
      if opencode_has_auth "$data"; then echo "✓ credentials present ($data/auth.json)"; else
        echo "✗ run:  opencode auth   (then add a provider)"; fi ;;
    antigravity)
      local cli; cli="$(cfg "$e" cli)"; [[ -z "$cli" ]] && cli="$(antigravity_cli)"
      if [[ -n "$cli" ]]; then echo "~ IDE found ($cli) — Google login is confirmed inside the IDE, not headlessly"; else
        echo "✗ Antigravity IDE not found — install it or set 'cli =' in engines.conf"; fi ;;
    *) echo "? unknown driver" ;;
  esac
}

cmd_auth(){
  require_conf
  local target="${1:-}"
  for e in $(engines); do
    [[ -n "$target" && "$target" != "$e" ]] && continue
    local d; d="$(cfg "$e" driver)"; printf '── %s (%s) ──\n' "$e" "$d"
    echo "  $(auth_status "$e")"
  done
}

cmd_doctor(){
  require_conf
  echo "config: $CONF"
  printf '%-12s %-15s %-9s %-8s %s\n' ENGINE DRIVER CLI BIN AUTH
  for e in $(engines); do
    local d cli ok bin; d="$(cfg "$e" driver)"
    cli="$(cli_for_driver "$d")"
    if [[ -z "$cli" ]]; then
      ok="?"; bin="-"; printf 'tokensmax: warning: engine %q has unknown driver %q\n' "$e" "$d" >&2
    elif have "$cli"; then
      ok="ok"; bin="$(command -v "$cli")"
    else
      ok="MISSING"; bin="-"
    fi
    printf '%-12s %-15s %-9s %-8s %s\n' "$e" "$d" "$ok" "$bin" "$(auth_status "$e")"
  done
}

cmd_list(){ require_conf; for e in $(engines); do printf '%-12s driver=%-13s model=%s\n' "$e" "$(cfg "$e" driver)" "$(cfg "$e" model)"; done; }

# ---- init: discovery-driven, interactive ----
cmd_init(){
  NONINTERACTIVE=0   # reset so re-entrant calls in one session behave consistently
  local FORCE=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force|-f) FORCE=1; shift ;;
      --yes|-y)   NONINTERACTIVE=1; shift ;;
      --)         shift; break ;;
      -*)         die "init: unknown flag '$1' (use --force, --yes)" ;;
      *)          die "init: unexpected argument '$1'" ;;
    esac
  done
  mkdir -p "$CONF_DIR" "$REPORTS" "$WORKTREES"

  echo "tokensmax init — discovering installed engines…"
  echo

  # --- detect CLIs ---
  declare -a DETECTED=()        # parallel arrays (bash 3.2 has no assoc arrays)
  declare -a D_DRIVER=()
  local n=0
  detect(){ # <name> <driver>   (records if CLI present)
    local name="$1" driver="$2" cli
    cli="$(cli_for_driver "$driver")"
    if [[ -n "$cli" ]] && have "$cli"; then
      DETECTED[$n]="$name"; D_DRIVER[$n]="$driver"; n=$((n+1))
      printf '  ✓ %-12s (%s)  %s\n' "$name" "$driver" "$(command -v "$cli")"
    else
      printf '  · %-12s (%s)  not installed\n' "$name" "$driver"
    fi
  }
  detect claude claude
  detect codex codex
  detect opencode opencode
  detect antigravity antigravity
  detect cursor cursor
  echo

  if [[ $n -eq 0 ]]; then
    die "no supported coding-agent CLI found on PATH. Install at least one (claude, codex, opencode, …)."
  fi

  # --- existing config? ---
  if [[ -f "$CONF" && $FORCE -ne 1 ]]; then
    echo "config exists: $CONF  (re-run with --force to overwrite)"
  else
    # Build into a temp file then atomically move into place (no half-written config on SIGINT).
    local tmp; tmp="$CONF.tmp.$$"
    {
      printf '# tokensmax engines — generated by `tokensmax init` (discovery-driven).\n'
      printf '# Edit freely. driver: claude | codex | cursor | opencode | antigravity | anthropic-api\n'
      printf '# Re-run: tokensmax init --force   |   Verify: tokensmax auth && tokensmax doctor\n\n'
    } > "$tmp"

    # --- per-engine prompts ---
    local i name driver enabled
    for ((i=0; i<n; i++)); do
      name="${DETECTED[$i]}"; driver="${D_DRIVER[$i]}"
      if prompt_yn y "Enable engine '$name'?"; then enabled=1; else enabled=0; fi
      echo
      [[ $enabled -ne 1 ]] && continue

      case "$driver" in
        claude)
          printf '[%s]\ndriver = claude\n' "$name" >> "$tmp"
          # choose seat: discover logged-in seats; if several or none, ask
          local seats cnt=0 chosen_dir="" chosen_lbl
          seats="$(discover_claude_seats)"
          cnt="$(printf '%s\n' "$seats" | grep -c . || true)"
          if [[ $cnt -eq 0 ]]; then
            echo "  no logged-in Claude seat detected."
            if prompt_yn y "Bind the DEFAULT seat (~/.claude)? (you'll need to run: claude  /login)"; then
              chosen_dir=""   # empty => default, unpinned at dispatch
            else
              echo "  skipped claude — log in then re-run init."; echo; continue
            fi
          elif [[ $cnt -eq 1 ]]; then
            chosen_dir="$(printf '%s' "$seats" | cut -f1)"; chosen_lbl="$(printf '%s' "$seats" | cut -f2)"
            echo "  detected: $chosen_lbl"
            if ! is_claude_default "$chosen_dir"; then
              prompt_yn y "Pin this custom seat (CLAUDE_CONFIG_DIR=$chosen_dir)?" || chosen_dir=""
            else
              chosen_dir=""   # default seat: never pin (pinning would break creds discovery)
            fi
          else
            echo "  multiple Claude seats detected:"
            local idx=1 line pick max
            declare -a SDIR=()
            while IFS= read -r line; do
              [[ -z "$line" ]] && continue
              printf '    %d) %s\n' "$idx" "$(printf '%s' "$line" | cut -f2)"
              SDIR[$idx]="$(printf '%s' "$line" | cut -f1)"; idx=$((idx+1))
            done <<< "$seats"
            max=$((idx-1))
            if [[ "$NONINTERACTIVE" == 1 ]] || ! tty_available; then
              pick=1; echo "  (auto-selected #1)"
            else
              while true; do
                read -r -p "  pick seat [1]: " pick </dev/tty || { echo; pick=1; break; }
                [[ -z "$pick" ]] && pick=1
                if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= max )); then break; fi
                echo "  invalid choice '$pick' (enter a number 1–$max)" >&2
              done
            fi
            chosen_dir="${SDIR[$pick]}"
            is_claude_default "$chosen_dir" && chosen_dir=""
          fi
          if [[ -n "$chosen_dir" ]]; then
            printf 'config_dir = %s   # custom seat — pinned via CLAUDE_CONFIG_DIR at dispatch\n' "$chosen_dir" >> "$tmp"
          else
            printf '# default seat (~/.claude) — left unpinned so Claude reads ~/.claude.json\n' >> "$tmp"
          fi
          echo "  models & role (press Enter to accept the default):"
          local cm cf cs
          cm="$(prompt_str claude-opus-4-8 "    deep model — opus/sonnet/fable")"
          cf="$(prompt_str claude-haiku-4-5 "    fast model (used with --fast)")"
          cs="$(prompt_str "design, reasoning, prose, planning, architecture" "    used for (strengths)")"
          printf 'model = %s\nmodel_fast = %s\nstrengths = %s\n\n' "$cm" "$cf" "$cs" >> "$tmp"
          ;;
        codex)
          echo "  models & role (Enter = default):"
          local xm xe xs
          xm="$(prompt_str gpt-5.5 "    model (your ChatGPT/Team plan; gpt-5-codex needs API-key auth)")"
          xe="$(prompt_str high "    reasoning effort — low|medium|high|xhigh")"
          xs="$(prompt_str "logic, refactor, code-review, tests, mechanical-precision" "    used for (strengths)")"
          printf '[%s]\ndriver = codex\ncodex_home = ~/.codex\nmodel = %s\neffort = %s\neffort_fast = low\nstrengths = %s\n\n' "$name" "$xm" "$xe" "$xs" >> "$tmp"
          ;;
        opencode)
          printf '[%s]\ndriver = opencode\nopencode_data = ~/.local/share/opencode\n' "$name" >> "$tmp"
          # try to read a default provider/model from auth.json (robust JSON parse)
          local f="$HOME/.local/share/opencode/auth.json" prov
          prov="$(opencode_default_provider "$f")"
          if [[ -n "$prov" ]]; then printf 'model = %s/glm-4.6   # provider/model — adjust to your plan\n' "$prov" >> "$tmp"
          else printf 'model = zai-coding-plan/glm-4.6   # provider/model — adjust to your plan\n' >> "$tmp"; fi
          printf '# agent = <name>   # optional: pin an opencode agent (see: opencode agent list)\n' >> "$tmp"
          printf 'strengths = cheap, bulk, drafts, high-volume, fast\n\n' >> "$tmp"
          ;;
        antigravity)
          printf '[%s]\ndriver = antigravity\n' "$name" >> "$tmp"
          local acli; acli="$(antigravity_cli)"
          [[ -n "$acli" ]] && printf 'cli = "%s"\n' "$acli" >> "$tmp"
          printf 'mode = agent   # ask | edit | agent (GUI-backed; opens an IDE window)\nstrengths = ide-aware, gemini, design\n# NOTE: antigravity chat is GUI-backed, not headless — fine for solo, noisy in a fleet.\n\n' >> "$tmp"
          ;;
        cursor)
          printf '[%s]\ndriver = cursor\nmodel = auto\nstrengths = ide-aware, quick-edits\n\n' "$name" >> "$tmp"
          ;;
      esac
    done
    mv -f "$tmp" "$CONF"   # atomic publish of the fully-built config
    echo "wrote $CONF"
  fi

  [[ -f "$SECRETS" ]] || { umask 077; printf '# tokensmax secrets (API keys). chmod 600.\n# GLM_API_KEY=...\n' > "$SECRETS"; echo "wrote $SECRETS (600)"; }
  echo
  echo "next: tokensmax auth && tokensmax doctor"
}

