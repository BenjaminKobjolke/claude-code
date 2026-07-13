---
description: Stand up the GPT-json-translator translation system in a project — en.json source of truth, de.json reference, machine-generated rest, wired via two tools/*.bat wrappers
---

Set up localization for a project. You author `en.json` (and a `de.json` reference); the
**GPT-json-translator** fans out every other language. This command explains the system and wires
the two `.bat` files a project needs.

## How it works

- **`en.json` is the single source of truth.** It lives in the locales folder, e.g.
  `assets\i18n\01_core\en.json`. All keys/values start here.
- **`de.json` is a hand-verified reference.** The translator takes it as `--second-input` so every
  *other* language is translated from English **and** a good German rendering — noticeably better
  output. It is also excluded from removal (`--exclude-source de.json`).
- **Every other locale (`fr.json`, `es.json`, `ja.json`, …) is machine-generated.** Never hand-edit
  them — the next translator run is the only thing that should touch them.
- **`_hint_` keys** in `en.json` carry genre guidance for the translator, e.g.
  `"_hint_": "File explorer app — translate Home→Start in German, not Zuhause"`. Keep them; they
  steer translation quality and are treated as meta, not UI strings.

### The rule for AI

> **Claude/AI creates and edits ONLY `en.json` and `de.json`.** Do not create or edit any other
> locale file — those are generated.

## Locales layout

Two shapes both work (recursive mode handles both):

- **Modular** (preferred for big apps): `assets\i18n\<module>\en.json` — one folder per module
  (`01_core`, `02_search`, …), each with its own `en.json` + `de.json`.
- **Flat**: a single folder with `en.json`, `de.json`, and the generated locales beside them.

## Prerequisites (one-time, machine-wide)

- Clone **GPT-json-translator** at `D:\GIT\BenjaminKobjolke\GPT-json-translator`, run its
  `install.bat` to create the `.venv`.
- Put a valid OpenAI API key + model in that repo's `settings.ini`.
  **Never copy the API key into a project or into these bats** — it stays in `settings.ini`.

## Wire the project (per project)

1. Copy both templates from this command's `setup-files/` folder into the project's `tools/`:
   - `translator_app_texts.bat`
   - `translator_remove_json_attribute_app-texts.bat`
2. In **each** bat, edit the `REM <<< EDIT` line — set the i18n/locales absolute path for this
   project. The `GPT-json-translator` repo path is stable; leave it.
3. In the remover bat, keep `--exclude-source de.json`. Drop `--exclude-source modules.json` unless
   the project actually uses a `modules.json` manifest.
4. Create `tools\attributes_to_remove.json` with `{}` (the remover reads it as its 2nd arg).
5. Author `en.json` (+ optional `_hint_` keys) and a `de.json` reference.

## Daily use

- **Added new keys to `en.json`/`de.json`?** Run `tools\translator_app_texts.bat`. It fills only the
  keys **missing** from each locale — existing translations are left untouched.
- **Changed a value under an existing key?** The translator will *not* re-do it (the key isn't
  "missing"), so the old translation lingers. Fix = remove the key from every locale, then
  re-translate:
  1. list the changed keys in `tools\attributes_to_remove.json`
     (nested `{ "menu": { "help": true } }` or flat `{ "menu.help": true }` per your files),
  2. run `tools\translator_remove_json_attribute_app-texts.bat` (strips them everywhere except
     `de.json`),
  3. run `tools\translator_app_texts.bat` (re-fills them fresh).
- For a **bulk drift audit** (validate reference languages, auto-detect stale keys, remove +
  re-translate), use the companion command **`/translations:update`** — it drives these same two bats.

## Notes

- After editing this command, run `tools/sync_commands_to_codex.bat` in the claude-code repo to
  propagate it to Codex as `~/.codex/skills/translations-setup/SKILL.md`.
- The bats end with `pause`/prompts; when running unattended feed stdin from `nul`
  (`cmd /c '...\translator_app_texts.bat < nul'`).
