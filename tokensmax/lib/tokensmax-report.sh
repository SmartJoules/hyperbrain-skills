#!/usr/bin/env bash
# tokensmax lib: report — usage · watch · reports
# Sourced by bin/tokensmax (not run directly). Uses globals/helpers
# (cfg, die, exp, REPORTS, WORKTREES, QUEUE, prompt_*, cmd_run, require_conf) from the entrypoint.

cmd_usage(){ # tokensmax usage [today|all|YYYY-MM-DD]  — per-run estimate vs actual + per-engine totals
  set +e   # reporting/aggregation: a grep-no-match is normal here; don't let set -e abort mid-table
  local scope="${1:-today}" root="$REPORTS" dir
  case "$scope" in today) dir="$root/$(date +%F)";; all) dir="$root";; *) dir="$root/$scope";; esac
  [[ -d "$dir" ]] || { echo "no reports under $dir  (run a fleet first)"; return 0; }
  local files; files="$(find "$dir" -type f -name '*.md' 2>/dev/null | sort)"
  [[ -z "$files" ]] && { echo "no reports under $dir"; return 0; }
  echo "usage — $dir"
  echo "  EST = orchestrator's pre-run estimate (--est) · ACTUAL = measured tokens · ⚠ = engine hit its limit"
  local f base eng est act n limited when task
  printf '  %-8s %-9s %4s %8s  %-34s %s\n' WHEN ENGINE EST ACTUAL 'TASK (who solved what)' ''
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    base="$(basename "$f")"; eng="$(printf '%s' "$base" | sed -E 's/.*\.([A-Za-z0-9_-]+)\.md$/\1/')"
    when="${base:0:6}"; when="${when:0:2}:${when:2:2}:${when:4:2}"
    est="$(sed -n 's/.*est:\([^ _]*\).*/\1/p' "$f" 2>/dev/null | head -1)"; [[ -n "$est" ]] || est="—"
    n="$(grep -A1 -i 'tokens used' "$f" 2>/dev/null | grep -oE '[0-9][0-9,]*' | tr -d ',' | head -1)"; [[ -n "$n" ]] && act="$n" || act="—"
    task="$(sed -n '1s/^# //p' "$f" 2>/dev/null | cut -c1-34)"; [[ -n "$task" ]] || task="—"
    limited=""; grep -qiE 'usage limit reached|rate limit reached|limit will reset|rate_limit_error|overloaded_error|quota (exceeded|reached)|too many requests|429' "$f" 2>/dev/null && limited="⚠ limit" || true
    printf '  %-8s %-9s %4s %8s  %-34s %s\n' "$when" "$eng" "$est" "$act" "$task" "$limited"
  done <<< "$files"
  echo
  printf '  %-10s %5s %10s %9s  %s\n' TOTAL/eng RUNS ACTUAL 'COST$' STATE
  local engs e ct tok cost c el reset cap rem costdisp gtok gcost
  gtok=0; gcost=0
  engs="$(printf '%s\n' "$files" | sed -E 's/.*\.([A-Za-z0-9_-]+)\.md$/\1/' | sort -u)"
  for e in $engs; do
    ct=0; tok=0; cost=0; el=""; reset=""
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue; ct=$((ct+1))
      n="$(grep -A1 -i 'tokens used' "$f" 2>/dev/null | grep -oE '[0-9][0-9,]*' | tr -d ',' | head -1)"; [[ -n "$n" ]] && tok=$((tok+n)) || true
      c="$(grep -oE 'cost: \$[0-9.]+' "$f" 2>/dev/null | grep -oE '[0-9.]+' | head -1)"; [[ -n "$c" ]] && cost="$(awk -v a="$cost" -v b="$c" 'BEGIN{printf "%.4f",a+b}')" || true
      if grep -qiE 'usage limit reached|rate limit reached|limit will reset|rate_limit_error|overloaded_error|quota (exceeded|reached)|too many requests|429' "$f" 2>/dev/null; then
        el="⚠ maxed"; reset="$(grep -oiE 'resets [0-9:apm.]+' "$f" 2>/dev/null | head -1)"
      fi
    done < <(printf '%s\n' "$files" | grep "\.$e\.md$")
    cap="$(cfg "$e" session_limit)"; rem=""
    [[ "$cap" =~ ^[0-9]+$ && $tok -gt 0 ]] && rem="  ($(( cap>tok ? cap-tok : 0 )) left of $cap)"
    costdisp="—"; [[ "$cost" != 0 ]] && costdisp="\$$cost"
    gtok=$((gtok+tok)); gcost="$(awk -v a="$gcost" -v b="$cost" 'BEGIN{printf "%.4f",a+b}')"
    printf '  %-10s %5s %10s %9s  %s%s%s\n' "$e" "$ct" "$([[ $tok -gt 0 ]] && echo "$tok" || echo "—")" "$costdisp" "$el" "${reset:+ ($reset)}" "$rem"
  done
  echo
  printf '  window so far: %s tokens · $%s  (cost shown where the engine reports it — Claude does)\n' "$gtok" "$gcost"
  echo "  No vendor exposes remaining session quota — the ⚠ maxed flag (+ reset time) is your real ceiling."
  echo "  Want a 'remaining' number? set \`session_limit = <tokens>\` per engine (YOUR plan's window cap; we can't read it)."
}

# ---- live per-seat progress of in-flight dispatches -------------------------
# WHY: a `--build` runs headless and the claude driver buffers its whole reply to the
# END (json), so a blocking foreground dispatch is a black box for minutes. The real
# live signal for a build is the WORKTREE filling with files; for research/review it's
# the background report growing. `watch` surfaces both so the orchestrator can show the
# user, between turns, what each seat has produced so far.
_watch_live_engines(){ # echo the engines whose background run is still alive
  local pf pid stem eng
  for pf in "$REPORTS"/*/*.pid; do
    [[ -e "$pf" ]] || continue
    pid="$(cat "$pf" 2>/dev/null || true)"; [[ -n "$pid" ]] || continue
    kill -0 "$pid" 2>/dev/null || continue
    stem="$(basename "${pf%.pid}")"; eng="${stem##*.}"
    printf '%s\n' "$eng"
  done
}
_mtime(){ stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }  # epoch mtime (BSD|GNU)
# Seconds since a run last showed life — the freshest of its report OR its build worktree(s).
# (Needed because the claude driver buffers stdout to the END: a claude BUILD looks idle in its
#  report while it is actively writing files, so the worktree is the true liveness signal.)
_watch_idle(){ # <report-file> <engine> -> idle seconds
  local rep="$1" eng="$2" now best wt m p; now="$(date +%s)"; best="$(_mtime "$rep")"
  for wt in "$WORKTREES"/*-"$eng"-*/; do
    [[ -d "$wt" ]] || continue
    # scan the TREE, not just the root: POSIX dir mtime only bumps on direct-child create/delete,
    # so an engine writing wt/src/main.go looks "stalled" if we stat wt/ alone. Worktrees are small.
    while IFS= read -r p; do m="$(_mtime "$p")"; [[ "$m" -gt "$best" ]] && best="$m"; done \
      < <(find "$wt" -name .git -prune -o -print 2>/dev/null)
  done
  [[ "$best" -gt 0 ]] || { echo 0; return 0; }  # nothing on disk yet → just started, not 55yr stalled
  echo $(( now - best ))
}
_watch_snapshot(){ # <match>  — one progress frame
  local match="${1:-}" any=0 pf pid stem eng rep
  printf '⏱  tokensmax watch · %s\n' "$(date '+%T')"
  # A) background runs still executing — show each report's tail (what it's said so far)
  for pf in "$REPORTS"/*/*.pid; do
    [[ -e "$pf" ]] || continue
    pid="$(cat "$pf" 2>/dev/null || true)"; [[ -n "$pid" ]] || continue
    rep="${pf%.pid}.md"; stem="$(basename "${pf%.pid}")"; eng="${stem##*.}"
    [[ -n "$match" && "$stem" != *"$match"* ]] && continue
    if kill -0 "$pid" 2>/dev/null; then
      any=1
      local idle lines health
      idle="$(_watch_idle "$rep" "$eng")"
      lines="$(grep -cv '^[[:space:]]*$' "$rep" 2>/dev/null || echo 0)"
      if grep -qiE 'usage limit reached|rate limit reached|limit will reset|rate_limit_error|overloaded_error|too many requests|429' "$rep" 2>/dev/null; then health='⚠ rate-limited'
      elif [[ "$idle" -gt 90 ]]; then health='⚠ stalled — no output'
      else health='● working'; fi
      printf '\n%s  %-8s · %s lines · %ss idle (bg pid %s)\n' "$health" "$eng" "$lines" "$idle" "$pid"
      [[ -f "$rep" ]] && grep -v '^[[:space:]]*$' "$rep" 2>/dev/null | tail -8 | sed 's/^/    │ /' || true
    else
      rm -f "$pf" 2>/dev/null || true   # reap: process gone, report is complete
      printf '\n✓ %-8s finished — read: tokensmax reports cat %s\n' "$eng" "$(basename "$rep" .md)"
    fi
  done
  # B) build worktrees — the live file-by-file signal (claude buffers stdout, but files land here)
  local live d nm weng wt st n
  live="$(_watch_live_engines 2>/dev/null | tr '\n' ' ' || true)"
  for wt in "$WORKTREES"/*/; do
    [[ -d "$wt" ]] || continue
    d="$(basename "$wt")"; nm="${d%-*}"; nm="${nm%-*}"; weng="${nm##*-}"
    [[ -n "$match" && "$d" != *"$match"* ]] && continue
    st="$(git -C "$wt" status --short 2>/dev/null || true)"
    n="$(printf '%s\n' "$st" | grep -c . 2>/dev/null || true)"
    [[ "$n" -gt 0 ]] || continue
    any=1
    if [[ " $live " == *" $weng "* ]]; then printf '\n▶ %-8s BUILDING · %s file(s) so far · %s\n' "$weng" "$n" "$d"
    else printf '\n◦ %-8s worktree idle · %s file(s) · %s\n' "$weng" "$n" "$d"; fi
    printf '%s\n' "$st" | head -12 | sed 's/^/    /' || true
    git -C "$wt" diff --stat 2>/dev/null | tail -6 | sed 's/^/    /' || true
  done
  [[ "$any" == 1 ]] || printf '\n(no in-flight dispatches — nothing running, no active worktrees)\n'
}
cmd_watch(){ # tokensmax watch [--follow [n]] [match]  — live per-seat progress; default one frame
  local follow=0 ticks=10 match=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --follow) follow=1; [[ "${2:-}" =~ ^[0-9]+$ ]] && { ticks="$2"; shift; }; shift ;;
      --once)   follow=0; shift ;;
      *)        match="$1"; shift ;;
    esac
  done
  local i=0
  while :; do
    i=$((i+1)); _watch_snapshot "$match"
    [[ "$follow" == 1 && $i -lt $ticks ]] || break
    printf '\n— refresh %s/%s (5s) —\n' "$i" "$ticks"; sleep 5
  done
}

_kill_tree(){ # TERM a pid and ALL its descendants (engine work happens in grandchildren —
  # bg-subshell → driver → engine — so killing only direct children leaves orphans)
  local c; for c in $(pgrep -P "$1" 2>/dev/null); do _kill_tree "$c"; done
  kill -TERM "$1" 2>/dev/null || true
}
cmd_kill(){ # tokensmax kill <match|all> — stop live background runs (the remedy `watch` points at)
  local match="${1:-}" any=0 pf pid stem rep
  [[ -n "$match" ]] || die "usage: tokensmax kill <match|all>   (see what's live: tokensmax watch)"
  [[ "$match" == all ]] && match=""
  for pf in "$REPORTS"/*/*.pid; do
    [[ -e "$pf" ]] || continue
    pid="$(cat "$pf" 2>/dev/null || true)"; [[ -n "$pid" ]] || continue
    stem="$(basename "${pf%.pid}")"; rep="${pf%.pid}.md"
    [[ -n "$match" && "$stem" != *"$match"* ]] && continue
    kill -0 "$pid" 2>/dev/null || { rm -f "$pf" 2>/dev/null || true; continue; }  # reap dead entries
    any=1
    _kill_tree "$pid"
    # shellcheck disable=SC2016  # literal backticks are intentional markdown in the report
    printf '\n- ✋ stopped by `tokensmax kill` at %s — partial output above is preserved\n' "$(date '+%T')" >> "$rep" 2>/dev/null || true
    rm -f "$pf" 2>/dev/null || true
    printf '✋ stopped %s (pid %s) — partial report kept: tokensmax reports cat %s\n' "$stem" "$pid" "$(basename "$rep" .md)"
  done
  # shellcheck disable=SC2016  # literal quoting in the hint is intentional
  [[ "$any" == 1 ]] || echo "nothing to stop — no live background runs${match:+ matching '$match'}"
}

cmd_reports(){ # list past durable reports/patches, or `cat <match>` to read one
  local root="$REPORTS"
  [[ -d "$root" ]] || { echo "no reports yet ($root)"; return 0; }
  if [[ "${1:-}" == cat ]]; then
    shift; local f; f="$(find "$root" -type f 2>/dev/null | grep -F -- "${1:-}" | sort | tail -1)"
    [[ -n "$f" ]] && { echo "── $f ──"; cat "$f"; } || echo "no report matching '${1:-}'"
    return 0
  fi
  echo "reports under $root   (read one: tokensmax reports cat <name-substring>)"
  find "$root" -type f \( -name '*.md' -o -name '*.patch' \) 2>/dev/null | sort | tail -40 \
    | while IFS= read -r f; do printf '  %s\n' "${f#"$root"/}"; done
}

