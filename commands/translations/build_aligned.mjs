#!/usr/bin/env node
// Build aligned en/<ref-lang> translation triples for /translations:update.
// Zero deps (Node stdlib only). Flat locale JSON assumed (this is the ai-chat shape).
//
// Usage:
//   node build_aligned.mjs <localesDir> [refLangsCsv] [outPath] [--en=en.json]
// Examples:
//   node build_aligned.mjs static/locales de,it
//   node build_aligned.mjs D:/GIT/Intern/ai-chat/static/locales de,it aligned.json
//
// Output: JSON array of { k, en, <lang>: value|null, ... } for every en key
// (minus _hint_* meta keys), plus a summary line on stderr listing, per ref
// language, how many keys are MISSING (translator fills those automatically —
// they are NOT translation defects, so exclude them from judging).

import { readFileSync, writeFileSync } from 'node:fs';
import { join, isAbsolute } from 'node:path';

const [, , localesDir, refCsv = 'de,it', outArg] = process.argv;
if (!localesDir) {
  console.error('usage: node build_aligned.mjs <localesDir> [refLangsCsv] [outPath] [--en=en.json]');
  process.exit(1);
}
const enName = (process.argv.find((a) => a.startsWith('--en=')) || '--en=en.json').slice(5);
const refs = refCsv.split(',').map((s) => s.trim()).filter(Boolean);
const out = outArg && !outArg.startsWith('--') ? outArg : 'aligned.json';

const load = (name) => JSON.parse(readFileSync(join(localesDir, name), 'utf8'));
const en = load(enName);
const langs = Object.fromEntries(refs.map((l) => [l, load(`${l}.json`)]));

const rows = [];
const missing = Object.fromEntries(refs.map((l) => [l, []]));
for (const [k, v] of Object.entries(en)) {
  if (k.startsWith('_hint_')) continue;
  const row = { k, en: v };
  for (const l of refs) {
    const has = Object.prototype.hasOwnProperty.call(langs[l], k);
    row[l] = has ? langs[l][k] : null;
    if (!has) missing[l].push(k);
  }
  rows.push(row);
}

const outPath = isAbsolute(out) ? out : join(process.cwd(), out);
writeFileSync(outPath, JSON.stringify(rows, null, 2));
console.error(`wrote ${rows.length} rows -> ${outPath}`);
for (const l of refs) console.error(`  ${l}: ${missing[l].length} missing (skip when judging)`);
