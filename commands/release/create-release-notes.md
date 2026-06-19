---
description: create release notes based on docs/CREATE_NEW_RELEASE.md
---

Create new release notes for the project.

This workflow is **stack-agnostic**. The concrete commands (how to read the
version/build, where the notes folder lives, the `en.json` schema, the translator
bat) differ per coding language and per project, and live in two places:

1. **`$CLAUDE_PROJECT_DIR/docs/CREATE_NEW_RELEASE.md`** — the project's own,
   authoritative recipe (produced by `/release:setup`). **This always wins.**
   If it is missing, stop and ask the user to run `/release:setup`.
2. **`coding-rules/<lang>_setup_files/CREATE_RELEASE_NOTES.md`** — the per-coding-
   language default, used to fill gaps the project doc leaves open. (Kept out of
   `commands/` so it does not register as its own slash-command.) Pick the file by
   detecting the stack from a root marker:
   - `pyproject.toml` → `coding-rules/python_setup_files/CREATE_RELEASE_NOTES.md`
   - `package.json` → `coding-rules/javascript_setup_files/CREATE_RELEASE_NOTES.md`
   - any other stack → see "Missing stack recipe" below.

Read **both** before starting: the project doc for specifics, the language file
for the stack defaults.

### Missing stack recipe

If no `coding-rules/<lang>_setup_files/CREATE_RELEASE_NOTES.md` exists for the
detected stack, **ask the user**: *"There's no reusable release-notes recipe for
`<lang>` yet. Add one so future projects in this stack inherit it?"*

- **Yes** → copy `coding-rules/RELEASE_NOTES_RECIPE.template.md` to
  `coding-rules/<lang>_setup_files/CREATE_RELEASE_NOTES.md`, fill it in from this
  project's `docs/CREATE_NEW_RELEASE.md` (version/build commands, folder path,
  `en.json` schema, translator bat, in-app view), show it to the user to confirm,
  then continue using it. Create the `<lang>_setup_files/` folder if absent.
- **No** → proceed with **only** the project's `docs/CREATE_NEW_RELEASE.md`; do not
  save a recipe.

Either way the release notes still get created — the recipe is just a reusable
default for next time.

## Workflow

### 1. Determine the next release label

Read the version + build number and form the folder label (commonly
`<version>_<build>`) per the project doc / language file. Confirm whether this
release bumps the build (most stacks) or reuses the current one (first release,
or an explicit no-bump build).

### 2. Find changes since the last release

- Establish the **anchor** = the last release actually shipped (a git tag/commit,
  store metadata, or the newest existing notes folder — see the language file).
- List commits since the anchor, plus uncommitted work (`git log`, `git status
  --short`, `git diff --stat`). If the project ships from **multiple repos**, do
  this for each repo listed in the project doc.

### 3. Synthesize ONE user-facing note

- Translate internal changes into user language (e.g. "transcription is faster",
  not "switched to whisper-large-v3"). Map backend/data changes to the behavior
  users see.
- **Drop** pure refactors, lint/format fixes, version bumps, dependency churn,
  and internal infra.
- **Dedup:** read the release notes *immediately before* this one and don't
  re-announce features already shipped.
- If there are zero meaningful user-facing changes, ask the user whether to ship a
  minor "Improvements and bug fixes" note or hold the release.

Writing guidelines:
- Informal, friendly tone; write for end users, no technical jargon.
- Focus on user benefit. Be brief and clear.
- When there are several changes, group them: `New:` / `Improved:` / `Fixed:`.
- Respect any length cap the stack imposes (see the language file's schema).

### 4. Create the folder + `en.json`

- Create the release-notes subdirectory at the path + name from the project doc /
  language file.
- Write **`en.json` only**, using the project's schema. Put the actual note in the
  schema's text key (e.g. a `notes[]` array, or a single `text` field — varies by
  stack; the language file states which).

### 5. Translate

After `en.json` is written, run the project's translator bat (named in the project
doc / language file) to generate the other human languages from the English
source. **Never hand-author non-English files.** Make sure this step is not
skipped.
