#!/usr/bin/env bash
# tokensmax lib: autonomy — queue · schedule · workflow
# Sourced by bin/tokensmax (not run directly). Uses globals/helpers
# (cfg, die, exp, REPORTS, WORKTREES, QUEUE, prompt_*, cmd_run, require_conf) from the entrypoint.

cmd_queue(){ # durable autonomous task queue: add | list | run | clear
  require_conf
  local action="${1:-list}"; shift || true
  mkdir -p "$QUEUE/pending" "$QUEUE/done" "$QUEUE/failed"
  case "$action" in
    add)
      [[ $# -ge 1 ]] || die "usage: tokensmax queue add <engine> [--research|--review|--build --repo DIR] [-m|--effort] \"task\""
      local id; id="$(date +%Y%m%d-%H%M%S)-$$"
      # NUL-delimited args: read back verbatim with `read -d ''` — no eval, so a planted task file
      # is data, not code. (bash-3.2-safe; `mapfile -d` is not.)
      printf '%s\0' "$@" > "$QUEUE/pending/$id.task"
      echo "queued $id  →  $*"
      ;;
    list)
      printf 'queue: %s pending · %s done · %s failed\n' \
        "$(find "$QUEUE/pending" -name '*.task' 2>/dev/null | wc -l | tr -d ' ')" \
        "$(find "$QUEUE/done" -name '*.task' 2>/dev/null | wc -l | tr -d ' ')" \
        "$(find "$QUEUE/failed" -name '*.task' 2>/dev/null | wc -l | tr -d ' ')"
      local t; for t in "$QUEUE"/pending/*.task; do [[ -e "$t" ]] && printf '  • %s: %s\n' "$(basename "$t" .task)" "$(tr '\0' ' ' < "$t")"; done
      ;;
    run)  # execute every pending task unattended (idempotent: done tasks are moved out). Each saves a report.
      local t any=0 a
      for t in "$QUEUE"/pending/*.task; do
        [[ -e "$t" ]] || continue; any=1
        local args=()
        while IFS= read -r -d '' a; do args+=("$a"); done < "$t"
        if [[ ${#args[@]} -eq 0 ]]; then  # legacy %q-format or corrupt file — never eval it
          echo "  ⚠ skip (legacy/bad task file — re-add with: tokensmax queue add ...): $t"
          mv "$t" "$QUEUE/failed/" 2>/dev/null || true; continue
        fi
        echo "▶ queue $(basename "$t" .task) → ${args[*]}"
        if ( cmd_run "${args[@]}" --yes ); then mv "$t" "$QUEUE/done/" 2>/dev/null || true; echo "  ✓ done"
        else mv "$t" "$QUEUE/failed/" 2>/dev/null || true; echo "  ⚠ failed → queue/failed (inspect + re-add)"; fi
      done
      # if-form, not `[[ ]] &&`: as the branch's LAST command a false &&-list returns 1,
      # which made a SUCCESSFUL `queue run` exit 1 (and would trip set -e).
      if [[ $any == 0 ]]; then echo "queue empty (nothing pending)"; fi
      ;;
    clear) rm -f "$QUEUE"/pending/*.task 2>/dev/null || true; echo "cleared pending" ;;
    *) die "queue: unknown action '$action' (use: add | list | run | clear)" ;;
  esac
}

cmd_schedule(){ # run the queue autonomously on a schedule (launchd on macOS, cron elsewhere)
  local action="${1:-status}"; shift || true
  local label="com.tokensmax.queue" plist="$HOME/Library/LaunchAgents/com.tokensmax.queue.plist" tmbin
  tmbin="$(command -v tokensmax || echo "$HOME/.local/bin/tokensmax")"
  case "$action" in
    on)
      local secs="${1:-3600}"   # default: hourly
      echo "⚠ ToS: scheduled/unattended runs against INTERACTIVE SUBSCRIPTION seats (Claude Max, ChatGPT) are a"
      echo "   gray area — those plans are for interactive use. Prefer API-key engines (e.g. GLM) for scheduled load."
      if have launchctl; then
        mkdir -p "$(dirname "$plist")"
        cat > "$plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>$tmbin</string><string>queue</string><string>run</string></array>
  <key>StartInterval</key><integer>$secs</integer>
  <key>RunAtLoad</key><false/>
  <key>StandardOutPath</key><string>$HOME/.tokensmax/schedule.log</string>
  <key>StandardErrorPath</key><string>$HOME/.tokensmax/schedule.log</string>
</dict></plist>
PL
        launchctl unload "$plist" 2>/dev/null || true
        launchctl load "$plist" 2>/dev/null && echo "✓ scheduled: \`tokensmax queue run\` every ${secs}s · log: ~/.tokensmax/schedule.log" \
          || echo "  ⚠ launchctl load failed — load it manually: launchctl load \"$plist\""
      else
        echo "no launchctl here — add this to your crontab (crontab -e):"
        # cron's minute field is 0-59: "*/120" for 2h would fire hourly-at-best (or be rejected),
        # so intervals ≥1h must move to the hour field.
        local mins=$(( secs / 60 )) hrs=$(( secs / 3600 ))
        if [[ "$hrs" -ge 1 && $(( secs % 3600 )) -eq 0 ]]; then
          echo "  0 */$hrs * * * $tmbin queue run >> \$HOME/.tokensmax/schedule.log 2>&1"
        elif [[ "$mins" -ge 1 && "$mins" -le 59 ]]; then
          echo "  */$mins * * * * $tmbin queue run >> \$HOME/.tokensmax/schedule.log 2>&1"
        else
          echo "  # cron can't express ${secs}s cleanly — nearest hourly form:"
          echo "  0 */$(( hrs > 0 ? hrs : 1 )) * * * $tmbin queue run >> \$HOME/.tokensmax/schedule.log 2>&1"
        fi
      fi ;;
    off)
      if have launchctl; then launchctl unload "$plist" 2>/dev/null || true; rm -f "$plist"; echo "✓ unscheduled (launchd)"
      else echo "remove the tokensmax line from your crontab (crontab -e)"; fi ;;
    status|*)
      if have launchctl; then launchctl list 2>/dev/null | grep -q "$label" && echo "scheduled (launchd: $label) · log: ~/.tokensmax/schedule.log" || echo "not scheduled"
      else echo "check: crontab -l | grep tokensmax"; fi ;;
  esac
}


# ---- workflows: saved, replayable, parameterised multi-step dispatches ----
# A workflow is a plain-text .wf file (blocks of key: value, one `step:` per dispatch) under
# $CONF_DIR/workflows. Steps run in order; each dispatches via cmd_run and saves a report.
# Substitutions in a prompt/repo: {{param}} (from key=value args), {{repo}} (the run --repo),
# and {{prev_worktree}} / {{prev_patch}} (the previous BUILD step's output — enables review-the-diff).
_wf_val(){ printf '%s' "${1#*:}" | sed 's/^[[:space:]]*//'; }   # value after the first ':'

WF_PREV_WT=""; WF_PREV_PATCH=""; WF_PARAMS=()
_wf_dispatch(){ # <name> <repo> <sid> <eng> <prof> <mdl> <eff> <srepo> <prompt> -> rc
  local name="$1" repo="$2" sid="$3" eng="$4" prof="$5" mdl="$6" eff="$7" srepo="$8" prompt="$9"
  [[ -n "$eng" ]] || return 0
  local p="$prompt" kv k v
  p="${p//\{\{repo\}\}/$repo}"; p="${p//\{\{prev_worktree\}\}/$WF_PREV_WT}"; p="${p//\{\{prev_patch\}\}/$WF_PREV_PATCH}"
  for kv in ${WF_PARAMS[@]+"${WF_PARAMS[@]}"}; do k="${kv%%=*}"; v="${kv#*=}"; p="${p//\{\{$k\}\}/$v}"; done
  [[ "$p" == *'{{'* ]] && echo "  ⚠ step $sid: unfilled $(printf '%s' "$p" | grep -oE '\{\{[A-Za-z_]+\}\}' | tr '\n' ' ')"
  local r="${srepo:-$repo}"; r="${r//\{\{repo\}\}/$repo}"; r="${r//\{\{prev_worktree\}\}/$WF_PREV_WT}"
  local -a a=("$eng")
  case "$prof" in
    build)    a+=(--build);    [[ -n "$r" ]] && a+=(--repo "$r") ;;
    review)   a+=(--review);   [[ -n "$r" ]] && a+=(--repo "$r") ;;
    research) a+=(--research);  [[ -n "$r" ]] && a+=(--repo "$r") ;;
    *) die "workflow step '$sid': profile must be build|review|research (got '$prof')" ;;
  esac
  [[ -n "$mdl" ]] && a+=(-m "$mdl")
  [[ -n "$eff" ]] && a+=(--effort "$eff")
  a+=("$p" --yes --est M --session "wf:$name")
  echo "  ▸ step [$sid]: $eng $prof${r:+ · repo $r}"
  local out rc; out="$( cmd_run "${a[@]}" 2>&1 )"; rc=$?
  printf '%s\n' "$out" | sed 's/^/    /'
  # capture this step's build output so a later step can review-the-diff
  local wt patch
  wt="$(printf '%s' "$out" | sed -n 's/.*worktree: \([^ ]*\) (branch.*/\1/p' | head -1)"
  patch="$(printf '%s' "$out" | sed -n 's/.*patch saved: \([^ ]*\) .*/\1/p' | head -1)"
  [[ -n "$wt" ]] && WF_PREV_WT="$wt"; [[ -n "$patch" ]] && WF_PREV_PATCH="$patch"
  return "$rc"
}

_workflow_usage(){ cat <<'EOF'
tokensmax workflow — saved, replayable multi-step pipelines (.wf under ~/.config/tokensmax/workflows)
  workflow list                     list saved workflows + descriptions
  workflow show <name>              print a workflow's steps
  workflow init                     write example workflows (build-review, cross-check)
  workflow run <name> [opts] k=v…   run a workflow; each {{key}} is replaced by its key=value arg
      --repo DIR    base repo for build/review steps (a step may override via repo:)
      --yes         confirm dispatch (required non-interactively; same gate as run/fleet)
      --bg          run the WHOLE workflow in the background → follow it with: tokensmax watch
EOF
}
_workflow_run(){ # <wfdir> [name] [--repo DIR] [--yes] [--bg] key=value…
  local wfdir="$1"; shift
  case "${1:-}" in -h|--help|help|'') _workflow_usage; return 0 ;; esac
  local name="$1"; shift
  local wf="$wfdir/$name.wf"; [[ -f "$wf" ]] || die "no workflow '$name' (see: tokensmax workflow list)"
  local repo="" yes="" bg=""; WF_PARAMS=(); WF_PREV_WT=""; WF_PREV_PATCH=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo) [[ -n "${2:-}" ]] || die "--repo needs a directory"; repo="$2"; shift 2 ;;
      --yes|--confirm) yes=1; shift ;;
      --bg) bg=1; shift ;;
      -h|--help) _workflow_usage; return 0 ;;
      *=*) WF_PARAMS+=("$1"); shift ;;
      *) die "workflow run: unexpected '$1' (want --repo DIR, --yes, --bg, or key=value)" ;;
    esac
  done
  [[ -n "$yes" || -t 0 ]] || die "refusing to run workflow non-interactively without --yes.
  Present the workflow's steps to the user first, then re-run with --yes (same gate as run/fleet)."
  if [[ -n "$bg" ]]; then   # fire the whole pipeline in the background; steps still save their own reports
    local day rdir rfile; day="$(date +%F)"; rdir="$REPORTS/$day"; mkdir -p "$rdir"
    rfile="$rdir/$(date +%H%M%S)-$$-workflow-$name.wf.md"
    { printf '# workflow: %s\n- started: %s\n\n' "$name" "$(date '+%F %T')"
      _workflow_exec "$wf" "$name" "$repo"
      printf '\n- finished: %s\n' "$(date '+%T')"; } > "$rfile" 2>&1 &
    local pid=$!; echo "$pid" > "${rfile%.md}.pid"
    printf '▶ workflow %s running in BACKGROUND (pid %s) → %s   (follow: tokensmax watch)\n' "$name" "$pid" "$rfile"
    return 0
  fi
  _workflow_exec "$wf" "$name" "$repo"
}
_workflow_exec(){ # <wf-file> <name> <repo>  — the step loop; uses WF_PARAMS/WF_PREV_* globals
  local wf="$1" name="$2" repo="$3"
  echo "▶ workflow: $name  ($(sed -n 's/^description:[[:space:]]*//p' "$wf" | head -1))"
  local line sid="" eng="" prof="" mdl="" eff="" srepo="" prompt=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      step:*)
        _wf_dispatch "$name" "$repo" "$sid" "$eng" "$prof" "$mdl" "$eff" "$srepo" "$prompt" \
          || { echo "  ⚠ stopping workflow at step '$sid'"; return 1; }
        sid="$(_wf_val "$line")"; eng=""; prof=""; mdl=""; eff=""; srepo=""; prompt="" ;;
      engine:*)  eng="$(_wf_val "$line")" ;;
      profile:*) prof="$(_wf_val "$line")" ;;
      model:*)   mdl="$(_wf_val "$line")" ;;
      effort:*)  eff="$(_wf_val "$line")" ;;
      repo:*)    srepo="$(_wf_val "$line")" ;;
      prompt:*)  prompt="$(_wf_val "$line")" ;;
      *) : ;;   # description:, comments, blanks
    esac
  done < "$wf"
  _wf_dispatch "$name" "$repo" "$sid" "$eng" "$prof" "$mdl" "$eff" "$srepo" "$prompt" \
    || { echo "  ⚠ stopping workflow at step '$sid'"; return 1; }
  echo "✓ workflow '$name' complete — review: tokensmax usage · tokensmax reports"
}

_workflow_write_examples(){ # <wfdir>
  local d="$1"; mkdir -p "$d"
  cat > "$d/build-review.wf" <<'WF'
description: build with one seat, then review-the-diff with another (bounded gate)
step: build
engine: codex
profile: build
prompt: {{task}}
step: review
engine: claude
profile: review
repo: {{prev_worktree}}
prompt: Review ONLY against the task "{{task}}". First line exactly 'VERDICT: BUG' or 'VERDICT: CLEAN'; then list each BLOCKING defect on its own line. Ignore style nits.
WF
  cat > "$d/cross-check.wf" <<'WF'
description: two seats attempt the SAME task independently; orchestrator diffs + synthesizes
step: attempt-a
engine: codex
profile: build
prompt: {{task}}
step: attempt-b
engine: claude
profile: build
prompt: {{task}}
WF
}

cmd_workflow(){ # tokensmax workflow list | show <name> | run <name> [--repo DIR] k=v… | init
  local action="${1:-list}"; shift || true
  local wfdir="${TOKENSMAX_WORKFLOWS:-$CONF_DIR/workflows}"; mkdir -p "$wfdir"
  case "$action" in
    -h|--help|help) _workflow_usage ;;
    list)
      local f any=0
      for f in "$wfdir"/*.wf; do [[ -e "$f" ]] || continue; any=1
        printf '  • %-16s %s\n' "$(basename "$f" .wf)" "$(sed -n 's/^description:[[:space:]]*//p' "$f" | head -1)"; done
      [[ $any == 1 ]] || echo "no workflows yet — run: tokensmax workflow init   (or write one in $wfdir)" ;;
    show)
      local f="$wfdir/${1:-}.wf"; [[ -f "$f" ]] || die "no workflow '${1:-}' (see: tokensmax workflow list)"; cat "$f" ;;
    init) _workflow_write_examples "$wfdir"; echo "wrote build-review.wf + cross-check.wf to $wfdir (list: tokensmax workflow list)" ;;
    run)  require_conf; _workflow_run "$wfdir" "$@" ;;
    *) die "workflow: unknown action '$action' (use: list | show <name> | run <name> [--repo DIR] k=v… | init)" ;;
  esac
}
