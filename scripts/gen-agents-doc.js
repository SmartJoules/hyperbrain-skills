#!/usr/bin/env node
/**
 * gen-agents-doc.js — regenerate AGENTS_AND_SKILLS.md from the live SKILL.md frontmatter.
 * Keeps the catalog accurate as skills are added. Run from repo root:
 *   node scripts/gen-agents-doc.js > AGENTS_AND_SKILLS.md
 * (or `node scripts/gen-agents-doc.js --write`)
 */
'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = process.cwd();

// First sentence of a description, trimmed for the table.
function firstSentence(desc) {
  const s = (desc || '').replace(/\s+/g, ' ').trim();
  const m = s.match(/^(.*?[.])(\s|$)/);
  return (m ? m[1] : s).slice(0, 200);
}

function frontmatter(file) {
  const t = fs.readFileSync(file, 'utf8');
  if (!t.startsWith('---')) return null;
  const end = t.indexOf('\n---', 3);
  if (end === -1) return null;
  const fm = t.slice(3, end);
  const name = (fm.match(/^name:\s*(.+)$/m) || [])[1];
  // description may be folded (>) across lines; grab until the next top-level key.
  let desc = '';
  const dm = fm.match(/^description:\s*([\s\S]*?)(?:\n[a-z-]+:\s|\n*$)/m);
  if (dm) desc = dm[1].replace(/\s+/g, ' ').trim();
  return name ? { name: name.trim(), desc } : null;
}

// Discover every skill (dir with SKILL.md), skip node_modules/.git.
function discover() {
  const out = [];
  for (const entry of fs.readdirSync(ROOT, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    if (['node_modules', '.git', 'scripts'].includes(entry.name)) continue;
    const sk = path.join(ROOT, entry.name, 'SKILL.md');
    if (fs.existsSync(sk)) {
      const fm = frontmatter(sk);
      if (fm) out.push({ dir: entry.name, ...fm });
    }
  }
  return out.sort((a, b) => a.dir.localeCompare(b.dir));
}

// Classify into buckets by name/description signal (best-effort, transparent).
function bucket(s) {
  const n = s.dir, d = (s.desc || '').toLowerCase();
  if (/knowledge-base$|^design-knowledge|^dejoule-knowledge/.test(n)) return 'kb';
  // Agent = a callable WORKER. Decide by the NAME's role word, or an explicit
  // "callable"/"acts as" in the description. (A bare "use when" is not enough —
  // most guides start that way.)
  const isAgent =
    /(reviewer|review-agent|optimizer|analyzer|resolver|generator|planner|harness|runner|orchestration|picker|assistant|tokensmax|engineering-ai|agentic-engineering|agent-tool-design|agent-context|agent-delegation|agent-fleet|prompt-harness)/.test(n) ||
    /\b(callable|acts as|orchestrat)\b/.test(d);
  if (isAgent) return 'agent';
  return 'reference';
}

const skills = discover();
const agents = skills.filter(s => bucket(s) === 'agent');
const kbs = skills.filter(s => bucket(s) === 'kb');
const refs = skills.filter(s => bucket(s) === 'reference');

const lines = [];
lines.push('# HyperBrain Agents & Skills');
lines.push('');
lines.push('> Auto-generated from each skill\'s `SKILL.md` frontmatter by `scripts/gen-agents-doc.js`.');
lines.push('> Do not hand-edit — re-run the generator after adding/removing a skill.');
lines.push(`> Total: **${skills.length}** skills (${agents.length} agents/workers · ${kbs.length} knowledge bases · ${refs.length} reference/pattern skills).`);
lines.push('');
lines.push('## How to call them');
lines.push('');
lines.push('A skill = a directory with `SKILL.md` (`name` + `description`). Skills load **automatically** when your task matches the description; you can also invoke explicitly:');
lines.push('');
lines.push('- **Claude Code** — name the skill in your ask ("use the *code-reviewer* skill on this diff") or via the Skill tool. Install from this repo with `./install.sh`.');
lines.push('- **Pi (pi.dev)** — `/skill:<name>` (e.g. `/skill:design-doc-review-agent <doc>`); args after the command are passed to the skill. Install from this repo with `./install.sh --assistant pi`.');
lines.push('- **Codex / Cursor / Copilot** — no native registry; `./install.sh --assistant codex` generates an `AGENTS.md` index they read, then open `skills/<name>/SKILL.md` for the task.');
lines.push('- **CLI agents (tokensmax)** — the `tokensmax` skill ships a `tokensmax` CLI to dispatch work across Claude/Codex/GLM seats (`/tokensmax <task>`).');
lines.push('- **CI** — `design-doc-reviewer` ships a deterministic gate + `anthropics/claude-code-action` workflow that runs the review agent on PRs.');
lines.push('');
lines.push('Agents compose: a planner → implementer → reviewer chain is normal. See `USAGE_GUIDE.md` for "which skill when" and how they combine.');
lines.push('');

function table(title, rows) {
  lines.push(`## ${title}`);
  lines.push('');
  lines.push('| Skill | What it does (when to use it) |');
  lines.push('|-------|-------------------------------|');
  for (const r of rows) lines.push(`| **${r.dir}** | ${firstSentence(r.desc)} |`);
  lines.push('');
}

table('Agents & workers (callable — they DO work)', agents);
table('Knowledge bases (repo/domain context)', kbs);
table('Reference & pattern skills (standards / how-to)', refs);

const doc = lines.join('\n') + '\n';
if (process.argv.includes('--write')) {
  fs.writeFileSync(path.join(ROOT, 'AGENTS_AND_SKILLS.md'), doc);
  process.stderr.write('wrote AGENTS_AND_SKILLS.md\n');
} else {
  process.stdout.write(doc);
}
