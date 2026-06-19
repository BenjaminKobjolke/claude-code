# Release-notes recipe — Python / uv

Per-stack recipe read by the `/release:create-release-notes` command (defined in
`claude-code/commands/release/create-release-notes.md`). It fills in the concrete
commands for a Python (uv) project set up by `/release:setup`. **The project's own
`docs/CREATE_NEW_RELEASE.md` always wins** where it disagrees with this default.

Lives here (next to the Python setup templates) rather than under `commands/` so it
does not register as a slash-command. See `CREATE_NEW_RELEASE.template.md` in this
folder for the full release process this recipe is the notes-only slice of.

**Detect this stack:** a `pyproject.toml` at the project root.

---

## 1. Next version & build number

Label = `<version>_<build>`. `version` is semver in `pyproject.toml` (bumped by
hand); `build` is an integer in `build_version.txt` = the **last shipped** build
(`0` = nothing shipped yet). Model is **bump first, ship next**: `/release:create-release`
increments the counter and ships that number.

```
tools\build_get.bat         :: current (last shipped) build, e.g. 21
tools\version_get.bat       :: <version>_<lastShippedBuild>
```

Author these notes for the **next** label = `<version>_<build_get + 1>` (e.g. if
`build_get` is `21`, the folder is `<version>_22`). `/release:create-release` does
the actual `build_increment` at build time. Edit `pyproject.toml` `version` by hand
for a semver bump.

## 2. Find changes since last release

Single repo by default. The anchor is the **last shipped release** — usually the
newest folder under `release_notes/` (or a `RELEASE`-tagged commit if the project
uses them). To list commits since then:

```
git log --oneline <last-release-sha>..HEAD
git status --short
git diff --stat
```

If the project doc lists extra repos (backend, data server), gather their commits
too with `git -C <repo> log --oneline --since="<last-release-date>"` and fold
user-visible behavior into the same note.

## 3. Release-notes subdirectory

`release_notes/<version>_<build>/`, e.g. `release_notes/0.1.0_22/`.

## 4. `en.json` schema

The actual note is the **`notes`** array (one user-facing bullet per item):

```json
{
  "version": "0.1.0",
  "build": 22,
  "date": "YYYY-MM-DD",
  "title": "Short headline",
  "notes": [
    "First user-facing change",
    "Second user-facing change"
  ]
}
```

Keys are defined once in `app/release/schema.py` — don't hardcode them elsewhere.

## 5. Reminders

- **Only create `en.json`** — other languages come from `tools\translator_release_notes.bat`
  (runs the shared `GPT-json-translator` recursively over every `<label>/en.json`).
- The in-app view is **File → Release notes…** (+ command palette, + the `pdft`
  wizard). It shows releases newest-first with Older/Newer navigation and falls
  back to `en.json` when a locale is missing.
- Doc reference: `docs/CREATE_NEW_RELEASE.md`.
