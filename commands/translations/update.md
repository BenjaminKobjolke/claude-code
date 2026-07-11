---
description: Re-translate stale locale strings — validate reference languages against English, remove wrong keys, re-run the GPT-json-translator
---

Fix translations that drifted. The GPT-json-translator only fills keys **missing** from a target
file, so when an English source *value* changes but the key stays the same, the old/wrong
translation lives forever. Fix = **remove** the stale key from every locale, then re-run the
translator so it re-fills it.

Reference languages to validate come from `$ARGUMENTS` (space- or comma-separated, e.g. `de it`).
Default when empty: `de it`. A key judged wrong in ANY reference language is treated as stale in
every locale and removed everywhere (they were all translated from the same English).

## 0. Locate the pieces (read the project first)

Read the project `CLAUDE.md` / `tools/CLAUDE.md`. Identify:
- source of truth `en.json` under the locales folder (usually `static/locales/`),
- the remover bat + translator bat in `tools/` (names like
  `translator_app_remove_json_attribute_*.bat`, `translator_app_texts.bat`),
- the `attributes_to_remove.json` the remover bat passes as its **2nd** arg.

**Verify the remover bat passes the attributes file as its 2nd argument.** If it calls the remover
with only `en.json`, fix it to append the absolute path to `tools/attributes_to_remove.json` —
otherwise the remover ignores the file and launches an interactive picker (hangs unattended).

## 1. Build aligned triples

Run the helper next to this command (zero-dep Node):

```
node "<this-command-dir>/build_aligned.mjs" "<absolute/localesDir>" de,it "<scratch>/aligned.json"
```

It writes a JSON array of `{ k, en, de, it, ... }` for every en key (skips `_hint_*` meta keys) and
prints, per language, how many keys are **missing**. Missing keys need NO action here — the
translator fills them automatically; they are not defects. If Node is unavailable, read `en.json`
and each `<lang>.json` directly and align by key yourself.

## 2. Judge each key (parallel subagents)

Read the `_hint_*` keys in `en.json` first — they carry project rules (proper nouns, register, app
genre). Split the aligned rows into chunks (~50 rows/agent) by array index and dispatch subagents in
parallel. Each agent, as a native speaker of the reference languages, flags a key when a reference
translation is:
- still English when it should be translated,
- mistranslated / wrong meaning,
- wrong **register** — this is a casual consumer app, use the **informal** form (German du, Italian
  tu, …); formal Sie/Lei is a defect,
- clearly **stale** (matches older/different English than the current value),
- has a broken `{0}`/`{1}`/`{SYS_LANG}` placeholder.

Do NOT flag proper/brand names (SUMMERA AI, XIDA, Google), theme names, or terms conventionally kept
untranslated (Tokens, Feedback, Premium). Be conservative — only defects a native speaker would
notice. Each agent returns a JSON array of `{key, langs, reason}`; `[]` if clean.

## 3. Write the attributes file

Union of all flagged keys → overwrite `tools/attributes_to_remove.json` as a **flat** object
(this project's locales are flat):

```json
{ "flagged_key_a": true, "flagged_key_b": true }
```

If nothing was flagged, STOP and report "no stale translations found" — do not run the bats.

## 4. Remove → Translate

The bats end with `pause`; feed stdin from `nul` so they auto-continue. Run from Windows:

```
cmd /c '<absolute>\translator_app_remove_json_attribute_*.bat < nul'   # strips flagged keys from every locale except en.json
cmd /c '<absolute>\translator_app_texts.bat < nul'                     # re-fills the now-missing keys (needs OpenAI API key; use a long timeout)
```

The remover prints a per-file removal summary. The translator prints `N keys to translate` per
language and `Output file saved as …` — expect only the flagged keys (plus any genuinely missing
keys) per file.

## 5. Verify before committing

If the locales folder is a git repo/submodule:

```
git -C <locales> status --porcelain    # count changed files; look for untracked files
git -C <locales> diff -- de.json it.json | grep flagged-keys
```

- Confirm the reference files (and others) changed and each flagged key now reads correctly.
- **Known-good:** the translator's `settings.ini` may configure full language codes (`de-DE`) yet it
  **saves to bare filenames** (`de.json`) — that is correct; the existing bare files get updated.
- **Fail-stop:** if NEW full-code files appear (`de-DE.json`, `it-IT.json`, …) as *untracked*, the
  re-translations landed in the wrong files and the removed keys are now LOST from the real ones.
  Revert (`git -C <locales> checkout .`, delete the junk files) and re-run the translator with
  `--languages` set to the bare codes (or fix `settings.ini [Languages]`).

Do not commit automatically — leave the diff for the user to review.

---
_Files beside this command: `build_aligned.mjs` (step 1 helper)._
_Maintainer note: after editing this command or its script, run `tools/sync_commands_to_codex.bat`
in the claude-code repo to propagate to Codex as `~/.codex/skills/translations-update/SKILL.md`._
