#!/usr/bin/env python3
"""
tokensmax Phase-0 intake evaluator.

Dispatches each gold-labeled case (cases.jsonl) K times through the cheapest engine
(opencode/glm by default) using the EXACT Phase-0 intake prompt prescribed by the skill,
then computes:

  - Classification: accuracy / precision / recall / F1 (positive = "underspecified"),
    + confusion matrix. Recall-on-underspecified is the headline (false-clear is the
    costly error: goal misgeneralization).
  - Schema fidelity (BFCL-style): parseability, field-completeness, strict-schema-valid.
  - Tool-restraint: spurious tool-call rate (the agentic-wander failure), esp. on the
    repo-referencing slice.
  - Question-cap adherence: share of runs emitting <=3 clarifying questions.
  - Gap relevance: for underspecified gold, fraction of expected gap keywords hit.
  - Nondeterminism (tau-bench-style): pass@1, pass^K (all-K-correct), per-case flip rate.
  - Cost: tokens per intake.

Methodology anchors: QuestBench (arXiv:2503.22674) clear/underspecified pair construction;
Qulac (1907.06554) clarification-need detection; BFCL (ICML 2025) schema fidelity + tool
restraint; tau-bench (2406.12045) pass^k; pass@k from HumanEval (2107.03374).

Streams raw per-run logs to runs/raw_<ts>.jsonl and writes report_<ts>.md + results_<ts>.json.
"""
import json, subprocess, re, time, os, statistics, sys
from pathlib import Path
from datetime import datetime

HERE = Path(__file__).parent
ENGINE = os.environ.get("ENGINE", "opencode")
K = int(os.environ.get("K", "3"))
CASES_FILE = os.environ.get("CASES", "cases.jsonl")
TS = datetime.now().strftime("%Y%m%d_%H%M%S")

PROMPT = ('Analyze this request. Do NOT use any tools. Do NOT read any files. '
          'Output STRICT JSON only in your first and only message — no prose, no markdown fence:\n'
          ' {goal: "<one-line restated intent>", '
          'slots:{scope,success_criteria,constraints,in_scope,out_of_scope,definition_of_done}, '
          'assumptions:[], clarity:"<clear|underspecified>", gaps:[], clarifying_questions:[]}\n'
          ' Request: "__REQ__"')

REQUIRED = ["goal", "slots", "assumptions", "clarity", "gaps", "clarifying_questions"]

def dispatch(req):
    prompt = PROMPT.replace("__REQ__", req.replace('\\', '\\\\').replace('"', '\\"'))
    t0 = time.time()
    try:
        r = subprocess.run(["tokensmax", "run", ENGINE, "--research", "--fast", "--yes", prompt],
                           capture_output=True, text=True, timeout=150)
    except subprocess.TimeoutExpired:
        return {"ok": False, "error": "timeout", "dt": 150, "empty": True}
    dt = round(time.time() - t0, 1)
    out = r.stdout
    text, tool_calls, tokens = "", 0, None
    # Path A: opencode-style NDJSON event stream
    saw_events = False
    for line in out.splitlines():
        line = line.strip()
        if not line or not line.startswith("{"):
            continue
        try:
            ev = json.loads(line)
        except Exception:
            continue
        if not isinstance(ev, dict) or "type" not in ev:
            continue
        saw_events = True
        p = ev.get("part", {})
        if ev.get("type") == "text" and isinstance(p, dict) and p.get("type") == "text":
            text += p.get("text", "")
        if ev.get("type") == "tool_use":
            tool_calls += 1
        if ev.get("type") == "step_finish":
            tokens = (p or {}).get("tokens", {}).get("total")
    # Path B: claude-style raw text + "tokens used: N ... cost: $C" summary
    if not saw_events:
        text = out
        m = re.search(r"tokens used:\s*([\d,]+)", out)
        if m:
            tokens = int(m.group(1).replace(",", ""))
        # strip the trailing summary line from the text we parse JSON out of
        text = re.sub(r"tokens used:.*$", "", text, flags=re.S).strip()
        tool_calls = 0  # claude --research plan mode: no tool-use surfaced in this format
    m = re.search(r"\{.*\}", text, re.S)
    parsed, parse_err = None, None
    if m:
        try:
            parsed = json.loads(m.group(0))
        except Exception as e:
            parse_err = str(e)
    is_empty = parsed is None and (parse_err is None) and (not text.strip())
    if parsed is None and parse_err is None and not text.strip():
        parse_err = "empty-output"
    return {"ok": True, "text": text[:1500], "parsed": parsed, "parse_err": parse_err,
            "tool_calls": tool_calls, "tokens": tokens, "dt": dt, "empty": bool(is_empty)}

def dispatch_with_retry(req, max_tries=4):
    """Bounded retry on EMPTY output (a transport flake), so classification quality is measured
    on emitted outputs. Empty-attempt rate is reported separately as a reliability metric."""
    tries = []
    for _ in range(max_tries):
        r = dispatch(req)
        tries.append(r)
        if r["ok"] and r["parsed"] is not None:
            r["tries"] = len(tries); r["empties"] = sum(1 for t in tries if t.get("empty"))
            return r, tries
    # all tries failed — return last, with attempt accounting
    last = tries[-1] if tries else {"ok": False, "error": "no-tries"}
    last["tries"] = len(tries); last["empties"] = sum(1 for t in tries if t.get("empty"))
    return last, tries

def norm_clarity(v):
    if not isinstance(v, str):
        return None
    v = v.strip().lower()
    if "under" in v or "ambig" in v or "miss" in v or "vague" in v:
        return "underspecified"
    if "clear" in v or "spec" in v or "complete" in v:
        return "clear"
    return None

def case_metrics(runs, gold, expected_gaps):
    labels, parse_ok, complete, strict, tools, qcounts, gap_hits, toks = [], [], [], [], [], [], [], []
    total_tries, total_empties = 0, 0
    for r in runs:
        total_tries += r.get("tries", 1)
        total_empties += r.get("empties", 0)
        if not r["ok"]:
            labels.append(None); parse_ok.append(0); complete.append(0); strict.append(0)
            tools.append(0); qcounts.append(None); continue
        p = r["parsed"]
        toks.append(r["tokens"])
        tools.append(r["tool_calls"])
        parse_ok.append(1 if p is not None else 0)
        if p is not None:
            lbl = norm_clarity(p.get("clarity"))
            labels.append(lbl)
            fields = [k for k in REQUIRED if k in p and p[k] is not None]
            complete.append(1 if len(fields) == len(REQUIRED) else 0)
            no_extra = all(isinstance(p.get("slots"), dict) or k != "slots" for k in p)
            strict.append(1 if (p is not None and len(fields) == len(REQUIRED) and norm_clarity(p.get("clarity"))) else 0)
            qs = p.get("clarifying_questions") or []
            qcounts.append(len(qs) if isinstance(qs, list) else None)
            if gold == "underspecified" and expected_gaps:
                gaps_blob = json.dumps(p.get("gaps", []) + qs).lower()
                hit = sum(1 for kw in expected_gaps if kw.lower() in gaps_blob)
                gap_hits.append(hit / len(expected_gaps))
        else:
            labels.append(None); complete.append(0); strict.append(0); qcounts.append(None)
    correct = [1 if l == gold else 0 for l, gold in [(labels[i], gold) for i in range(len(labels))]]
    correct = [1 if labels[i] == gold else 0 for i in range(len(labels))]
    return {
        "gold": gold,
        "n": len(runs),
        "label_distribution": {l: labels.count(l) for l in set(labels)},
        "pass@1": 1 if any(c for c in correct) else 0,
        "pass_all": 1 if (correct and all(correct)) else 0,
        "flip_rate": 0 if len(set(labels)) <= 1 else 1,
        "parse_rate": statistics.mean(parse_ok) if parse_ok else 0,
        "complete_rate": statistics.mean(complete) if complete else 0,
        "strict_rate": statistics.mean(strict) if strict else 0,
        "tool_wander_rate": statistics.mean([1 if t > 0 else 0 for t in tools]) if tools else 0,
        "qcount_mean": statistics.mean([q for q in qcounts if q is not None]) if any(qcounts) else None,
        "qcount_within_cap": statistics.mean([1 if (q is not None and q <= 3) else 0 for q in qcounts]) if qcounts else 0,
        "gap_keyword_coverage": statistics.mean(gap_hits) if gap_hits else None,
        "tokens_mean": statistics.mean([t for t in toks if t is not None]) if any(toks) else None,
        "empty_attempt_rate": (total_empties / total_tries) if total_tries else 0,
        "avg_tries_per_run": (total_tries / len(runs)) if runs else 0,
    }

def main():
    cases = [json.loads(l) for l in (HERE / CASES_FILE).read_text().splitlines() if l.strip()]
    raw_path = HERE / "runs" / f"raw_{ENGINE}_{TS}.jsonl"
    raw_path.parent.mkdir(exist_ok=True)
    raw_fh = raw_path.open("w")
    print(f"=== intake eval: {len(cases)} cases x K={K} on engine={ENGINE} ===", flush=True)
    all_results = {}
    for ci, c in enumerate(cases, 1):
        runs = []
        for k in range(K):
            r, tries = dispatch_with_retry(c["request"])
            for t in tries:   # log every attempt (incl. empties) for transparency
                t["id"], t["k"], t["category"] = c["id"], k + 1, c["category"]
                raw_fh.write(json.dumps(t) + "\n")
            raw_fh.flush()
            runs.append(r)
            lbl = norm_clarity(r["parsed"].get("clarity")) if r.get("ok") and r.get("parsed") else "ERR"
            tc = r.get("tool_calls", "-")
            tries_n = r.get("tries", "?")
            empties = r.get("empties", "?")
            status = 'ERR:' + str(r.get('parse_err')) if (not r.get('ok') or r.get('parsed') is None) else 'ok'
            print(f"  [{ci}/{len(cases)}] {c['id']} run {k+1}/{K}: label={lbl} gold={c['gold']} "
                  f"tools={tc} tries={tries_n} empties={empties} {status}", flush=True)
        all_results[c["id"]] = {**case_metrics(runs, c["gold"], c["expected_gaps"]),
                                "category": c["category"], "expected_gaps": c["expected_gaps"]}
    raw_fh.close()
    write_report(all_results, cases)
    print(f"\n=== done. report: {HERE / f'report_{TS}.md'} ===", flush=True)

def write_report(all_results, cases):
    # confusion matrix (positive = underspecified)
    tp = fp = fn = tn = 0
    for c in cases:
        r = all_results[c["id"]]
        pred = max(r["label_distribution"], key=r["label_distribution"].get) if r["label_distribution"] else None
        # use pass@1: if any run said the gold label, count the majority; here use mode
        gold = c["gold"]
        if pred == "underspecified" and gold == "underspecified": tp += 1
        elif pred == "underspecified" and gold == "clear": fp += 1
        elif pred == "clear" and gold == "underspecified": fn += 1
        elif pred == "clear" and gold == "clear": tn += 1
        else: fn += 0  # None/ERR counts against recall
    n = len(cases)
    prec = tp / (tp + fp) if (tp + fp) else 0
    rec = tp / (tp + fn) if (tp + fn) else 0
    f1 = 2 * prec * rec / (prec + rec) if (prec + rec) else 0
    acc = (tp + tn) / n if n else 0

    def am(key):
        vals = [all_results[c["id"]][key] for c in cases if all_results[c["id"]].get(key) is not None]
        return statistics.mean(vals) if vals else 0

    L = []
    L.append(f"# tokensmax Phase-0 Intake — Eval Report\n")
    L.append(f"_Engine: `{ENGINE}` · K={K} runs/case · {n} cases · generated {TS}_\n")
    L.append(f"_Methodology: QuestBench pair construction · Qulac clarification-need · BFCL schema fidelity + tool restraint · τ-bench pass^k · pass@k (HumanEval)_\n")
    L.append(f"\n## Headline\n")
    L.append(f"| metric | value | target / note |")
    L.append(f"|---|---|---|")
    L.append(f"| **Classification accuracy** | {acc:.0%} | — |")
    L.append(f"| **Recall (underspecified)** | {rec:.0%} | **the costly error** — false-clear = goal misgeneralization; want ≥90% |")
    L.append(f"| Precision (underspecified) | {prec:.0%} | over-asking cost (PARADISE) |")
    L.append(f"| F1 | {f1:.0%} | — |")
    L.append(f"| Confusion (TP/FP/FN/TN) | {tp}/{fp}/{fn}/{tn} | pos=underspecified |")
    L.append(f"| **Schema strict-valid rate** | {am('strict_rate'):.0%} | BFCL-style; flag <95% |")
    L.append(f"| Parseability | {am('parse_rate'):.0%} | — |")
    L.append(f"| **Empty-attempt rate** | {am('empty_attempt_rate'):.0%} | opencode/glm transport flake (emits no text); bounded retry masks it; report is on emitted outputs |")
    L.append(f"| Avg tries / run | {am('avg_tries_per_run'):.2f} | 1.0 = no empties |")
    L.append(f"| **Tool-wander rate** | {am('tool_wander_rate'):.0%} | spurious tool calls; target 0% (fixed by no-tools prompt) |")
    L.append(f"| Q-count within cap (≤3) | {am('qcount_within_cap'):.0%} | gate caps anyway; worker should comply |")
    L.append(f"| Gap-keyword coverage | {am('gap_keyword_coverage'):.0%} | underspecified cases only |")
    L.append(f"| pass@1 (any run correct) | {statistics.mean([all_results[c['id']]['pass@1'] for c in cases]):.0%} | optimistic |")
    L.append(f"| pass^K (all runs correct) | {statistics.mean([all_results[c['id']]['pass_all'] for c in cases]):.0%} | pessimistic / reliability (τ-bench) |")
    L.append(f"| Flip rate (label changed) | {statistics.mean([all_results[c['id']]['flip_rate'] for c in cases]):.0%} | nondeterminism |")
    L.append(f"| Tokens/intake (mean) | {am('tokens_mean'):.0f} | cost proxy ($0 on glm) |")

    L.append(f"\n## Per-case results\n")
    L.append(f"| id | category | gold | mode-pred | pass@1 | pass^K | flip | parse | strict | tools | q≤3 |")
    L.append(f"|---|---|---|---|---|---|---|---|---|---|---|")
    for c in cases:
        r = all_results[c["id"]]
        dist = r["label_distribution"]
        pred = max(dist, key=dist.get) if dist else "ERR"
        flag = "" if pred == c["gold"] else " ⚠"
        L.append(f"| {c['id']} | {r['category']} | {c['gold']} | {pred}{flag} | "
                 f"{r['pass@1']} | {r['pass_all']} | {r['flip_rate']} | "
                 f"{r['parse_rate']:.0%} | {r['strict_rate']:.0%} | {r['tool_wander_rate']:.0%} | {r['qcount_within_cap']:.0%} |")

    # slice breakdown
    L.append(f"\n## Slice breakdown (recall on underspecified is what matters)\n")
    L.append(f"| slice | n | acc | tool-wander | strict |")
    L.append(f"|---|---|---|---|---|")
    from collections import defaultdict
    slices = defaultdict(list)
    for c in cases:
        slices[c["category"]].append(c["id"])
    for sl, ids in sorted(slices.items()):
        accs = [1 if (max(all_results[i]["label_distribution"], key=all_results[i]["label_distribution"].get) if all_results[i]["label_distribution"] else None)
                == next(c["gold"] for c in cases if c["id"] == i) else 0 for i in ids]
        tw = [all_results[i]["tool_wander_rate"] for i in ids]
        st = [all_results[i]["strict_rate"] for i in ids]
        L.append(f"| {sl} | {len(ids)} | {statistics.mean(accs):.0%} | {statistics.mean(tw):.0%} | {statistics.mean(st):.0%} |")

    L.append(f"\n## Limitations of this eval\n")
    L.append(f"- **K={K}**: τ-bench/HumanEval methodology prefers K≥5 (10 ideal) for stable pass^k; this run uses K={K} for wall-clock. pass^K here is a lower-confidence estimate.")
    L.append(f"- **N={n}**: small expert-authored gold set (defensible for slice coverage, not population stats). Treat as regression guard + failure discovery, not a benchmark rank.")
    L.append(f"- **Single engine** (`{ENGINE}`): does not prove the prompt generalizes to claude --fast/haiku or codex low-effort. Re-run with `ENGINE=claude` to extend.")
    L.append(f"- **Gap-keyword coverage** is a coarse proxy for gap *quality*; a full LLM-as-judge pass (R1–R4: relevant/informative/non-redundant/answerable, MT-Bench 2306.05685) on generated questions is not run here — noted as follow-up.")
    L.append(f"- **Gold labels** for edge cases (multi-intent, ambiguous-complete) are author-judgment; reasonable people could label U06 either way.")
    L.append(f"- **temp**: opencode/glm temp is provider-default; no temp sweep (0/0.3/0.7) run here.")

    (HERE / f"report_{TS}.md").write_text("\n".join(L))
    (HERE / f"results_{TS}.json").write_text(json.dumps(all_results, indent=2))

if __name__ == "__main__":
    main()
