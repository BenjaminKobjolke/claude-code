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
2. **`coding-rules/CREATE_RELEASE_NOTES.md`** — one file, one section per stack,
   used to fill gaps the project doc leaves open. (Kept out of `commands/` so it
   does not register as its own slash-command.) Pick the section by detecting the
   stack from a root marker:
   - `pubspec.yaml` (Flutter SDK dependency) → `## Flutter`
   - `pyproject.toml` → `## Python / uv`
   - `package.json` → `## JavaScript / npm (+ Android)`
   - any other stack → see "Missing stack recipe" below.

Read **both** before starting: the project doc for specifics, the matching section
for the stack defaults.

### Missing stack recipe

If `coding-rules/CREATE_RELEASE_NOTES.md` has no section for the detected stack, the
file's own "Adding a new stack" section at the bottom says what to do: ask the user
whether to add one, and if so append a new section there (not a new file) filled in
from this project's `docs/CREATE_NEW_RELEASE.md`. Follow that section directly.

Either way the release notes still get created — the recipe is just a reusable
default for next time.

## Workflow

### 1. Determine the next release label

Read the version + build number and form the folder label (commonly
`<version>_<build>`) per the project doc / language file. Confirm whether this
release bumps the build (most stacks) or reuses the current one (first release,
or an explicit no-bump build).

### 2. Find changes since the last release

- Establish the **anchor** = the last release actually shipped **to end users** (a
  `RELEASE` git tag/commit, store metadata, or the newest existing notes folder — see
  the matching stack section). Skip `INTERNAL` commits and internal-only builds when
  locating the anchor: an internal test build (TestFlight, Play internal/beta, dev/test
  exe) never reached end users, so it must not shrink the window of covered changes.
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
- Respect any length cap the stack imposes (see the stack section's schema).

### 4. Create the folder + `en.json`

- Create the release-notes subdirectory at the path + name from the project doc /
  stack section.
- Write **`en.json` only**, using the project's schema. Put the actual note in the
  schema's text key (e.g. a `notes[]` array, or a single `text` field — varies by
  stack; the stack section states which).

### 5. Translate

After `en.json` is written, run the project's translator bat (named in the project
doc / stack section) to generate the other human languages from the English
source. **Never hand-author non-English files.** Make sure this step is not
skipped.
