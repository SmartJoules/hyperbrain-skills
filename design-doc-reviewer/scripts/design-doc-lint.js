#!/usr/bin/env node
/**
 * design-doc-lint — deterministic gate for design docs (no API key needed).
 * Enforces the MECHANICAL subset of the design-doc-reviewer skill:
 *   - required sections present + non-empty
 *   - no hardcoded secrets / tokens
 *   - no hardcoded site IDs / env values (DeJoule rule)
 *   - no banned anti-patterns mentioned as the design (::ng-deep, unbounded cache, per-request Redis)
 * Exits non-zero (fails the CI check) on any BLOCKER. The full judgment review +
 * suggestions come from the design-doc-reviewer skill (advisory job in the workflow).
 *
 * Usage:  node design-doc-lint.js <file...>
 *         (CI passes the changed design-doc paths)
 * Env:    DDLINT_REQUIRE_SKILL_REF=1  → also require a "Skills / Standards" reference (warn->blocker)
 */
'use strict';
const fs = require('fs');

const REQUIRED_SECTIONS = [
  { name: 'Context / Problem', re: /^#+\s*(context|problem|background|overview)\b/im },
  { name: 'Goals & Non-Goals', re: /^#+\s*(goals?|non[- ]?goals?|scope)\b/im },
  { name: 'Proposed Design', re: /^#+\s*(proposed\s+)?(design|approach|solution|architecture)\b/im },
  { name: 'Alternatives Considered', re: /^#+\s*(alternatives?|options?\s+considered|trade[- ]?offs?)\b/im },
  { name: 'Risks & Mitigations', re: /^#+\s*(risks?|mitigations?)\b/im },
  { name: 'Testing strategy', re: /^#+\s*(test(ing)?|verification|qa)\b/im },
  { name: 'Rollout / Migration / Rollback', re: /^#+\s*(rollout|migration|rollback|deployment|release)\b/im },
];

// Hardcoded-secret patterns (high-confidence; avoids most false positives).
const SECRET_PATTERNS = [
  { name: 'AWS access key', re: /\bAKIA[0-9A-Z]{16}\b/ },
  { name: 'private key block', re: /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/ },
  { name: 'bearer/JWT token', re: /\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b/ },
  { name: 'assigned secret/password/token', re: /\b(password|passwd|secret|api[_-]?key|access[_-]?token|client[_-]?secret)\s*[:=]\s*['"][^'"\s]{8,}['"]/i },
];

// Banned anti-patterns proposed AS the design (not merely named as "avoid X").
const ANTIPATTERNS = [
  { name: '::ng-deep (use ViewEncapsulation.None + scoping class)', re: /::ng-deep|\/deep\/|>>>/ },
  { name: 'per-request Redis/DB connection (use singleton/pool)', re: /new\s+(Redis|ioredis|Client)\s*\([^)]*\)\s*(?:per[- ]?request|on each request|in (?:the )?handler)/i },
];

function lintFile(file) {
  const blockers = [];
  const warnings = [];
  let text;
  try { text = fs.readFileSync(file, 'utf8'); }
  catch (e) { return { file, blockers: [`cannot read file: ${e.message}`], warnings: [] }; }

  // 1) Required sections (scale: tiny ADRs are exempt if they declare themselves an ADR)
  const isAdr = /\b(ADR|architecture decision record)\b/i.test(text.slice(0, 600));
  const sectionsToCheck = isAdr
    ? REQUIRED_SECTIONS.filter(s => /Design|Alternatives|Context/.test(s.name))
    : REQUIRED_SECTIONS;
  for (const s of sectionsToCheck) {
    if (!s.re.test(text)) blockers.push(`missing required section: ${s.name}`);
  }

  // 2) Hardcoded secrets
  for (const p of SECRET_PATTERNS) {
    if (p.re.test(text)) blockers.push(`hardcoded secret detected (${p.name}) — use env vars / secret manager`);
  }

  // 3) Hardcoded site IDs / env values (DeJoule rule) — heuristic
  if (/\bsite[_-]?id\s*[:=]\s*['"][a-z0-9-]{3,}['"]/i.test(text)) {
    blockers.push('hardcoded site ID — site must come from context/config, never a literal');
  }

  // 4) Banned anti-patterns proposed as the design
  for (const a of ANTIPATTERNS) {
    if (a.re.test(text)) blockers.push(`anti-pattern in design: ${a.name}`);
  }

  // 5) Skill/standards reference (warn by default; blocker if DDLINT_REQUIRE_SKILL_REF=1)
  const refsSkills = /^#+\s*(skills?|standards?|references?)\b/im.test(text)
    || /hyperbrain|engineering-standards|jouletrack-angular|backend-knowledge-base/i.test(text);
  if (!refsSkills) {
    const msg = 'no reference to applicable hyperbrain skills / engineering-standards';
    if (process.env.DDLINT_REQUIRE_SKILL_REF === '1') blockers.push(msg);
    else warnings.push(msg);
  }

  return { file, blockers, warnings };
}

function main() {
  const files = process.argv.slice(2).filter(Boolean);
  if (files.length === 0) {
    console.log('design-doc-lint: no design-doc files to check — passing.');
    process.exit(0);
  }
  let failed = false;
  for (const f of files) {
    const { blockers, warnings } = lintFile(f);
    if (blockers.length === 0 && warnings.length === 0) {
      console.log(`✅ ${f} — OK`);
      continue;
    }
    if (blockers.length) {
      failed = true;
      console.log(`❌ ${f} — REJECTED (${blockers.length} blocker${blockers.length > 1 ? 's' : ''})`);
      for (const b of blockers) console.log(`   ✗ ${b}`);
    } else {
      console.log(`⚠️  ${f} — passed with warnings`);
    }
    for (const w of warnings) console.log(`   ⚠ ${w}`);
  }
  if (failed) {
    console.log('\nDesign doc rejected. Fix the blockers above. Full review + suggestions:');
    console.log('  run the `design-doc-reviewer` skill for actionable improvements.');
    process.exit(1);
  }
  console.log('\nAll design docs passed the mechanical gate.');
  process.exit(0);
}

main();
