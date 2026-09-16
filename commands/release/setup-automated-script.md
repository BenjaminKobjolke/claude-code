---
description: Set up tools/release_create.ini + tools/release_create.bat so one command runs the full release
---

Wire up the **`release-tool create`** subcommand for this project by writing two
files into the project's `tools/` folder:

- `tools/release_create.ini` — the per-project config (which bats, scope, platform).
- `tools/release_create.bat` — a launcher that runs the whole release in one command.

This is a **config + launcher** setup — it does not touch application source. It
also adjusts existing build/publish wrappers for the version handoff and exit
codes, and gitignores transient publish state (see step 5). The
subcommand itself lives in the `release-tool` package
(`D:\GIT\BenjaminKobjolke\release-tool`).

Prerequisite: the project must already have a release system documented in
`$CLAUDE_PROJECT_DIR/docs/CREATE_NEW_RELEASE.md`. If it is missing, stop and ask the
user to run `/release:setup` first.

## Steps

### 1. Discover the project's release bats

Read `$CLAUDE_PROJECT_DIR/docs/CREATE_NEW_RELEASE.md` (authoritative) and list
`$CLAUDE_PROJECT_DIR/tools/*.bat`. Map each of these to a real bat path (relative to
the project root). The conventional names / defaults are:

| Config key | Default | Purpose |
|---|---|---|
| `version_get` | `tools/version_get.bat` | prints the version (bare `1.0.0` or full `1.0.0_21`) |
| `build_get` | `tools/build_get.bat` | prints the current build integer |
| `build_increment` | `tools/build_increment.bat` | bumps the build counter |
| `build_decrement` | `tools/build_decrement.bat` | rolls the build counter back (used on build failure) |
| `translate` | `tools/translator_app-release-notes.bat` | generates non-English locales |
| `build` | `tools/build_release.bat` | builds + bundles the artifact |
| `publish` | *(none)* | publishes; **omit to build-and-stop** |

`version_get` must print the bare version or a full `<version>_<build>` label — the
subcommand strips a trailing `_<build>` either way. If the project's actual bat
names differ from the defaults, record the real paths. Read the mapped bats,
including their callers, to establish which script owns the version bump,
translation, rollback, and artifact selection; filenames alone do not establish
that contract.

### 2. Determine the scalars

- `scope` — the commit scope for `RELEASE (<scope>): <label>` (usually the app/tool short name).
- `publish_platform` — the human name of the publish target from the project doc
  (e.g. "Google Play Store", "Website"). If the project has **no** publish step,
  omit the `publish` bat — the release then just skips the publish gate; the
  commit/tag/push gate is still offered.
- `versioning` — `build` (default: `{version}_{build}` with a `build_get` counter)
  or `semver` (no counter; each release bumps the last version segment, e.g.
  `0.1.6` → `0.1.7`, driven by `build_increment`/`build_decrement`). Pick `semver`
  for projects whose release *is* a patch bump of `version.txt`/`pyproject.toml`.
- `build_self_contained` — set `true` when the build bat already owns the
  version bump, translation, and rollback. Then omit `build_increment`,
  `build_decrement`, and `translate`: `create` must not run them again. Otherwise
  `create` owns those steps and the build bat must use the version already set.
  There must be exactly one bump per release, shared by all platform artifacts.
- `english_only` — `true` if the project ships English-only / has no translator bat.
- `notes_dir` / `en_file` / `label_format` / `notes_label_format` /
  `previous_version_file` — only set
  these if they differ from the defaults (`release_notes`, `en.json`,
  `{version}_{build}`, notes defaulting to `label_format`,
  `tools/previous_version.txt`). For Flutter/Play notes keyed by build number,
  set `notes_label_format = {build}` and use the project's actual notes directory.

After the build, `create` **asks two independent questions**: run publish? and
commit + tag + push? It also records the previous (online) version to
`previous_version_file` so the publish bat can name its backup folder.

### 3. Write `tools/release_create.ini`

Write it at `$CLAUDE_PROJECT_DIR/tools/release_create.ini`. List **only** values
that differ from the defaults — keep it minimal. Match the template at
`release-tool/examples/release_create.ini`. The `[Bats]` paths stay relative to
the **project root** (`tools/version_get.bat`, …), not to the `tools/` folder —
the launcher passes the project root as `--project-root`. Put comments on
separate lines: configparser does not strip inline `;`/`#` comments. Example:

```ini
[Release]
scope = myapp
publish_platform = Google Play Store

[Bats]
publish = tools/publish_release.bat
```

### 4. Write `tools/release_create.bat`

Use this launcher. It cd's into the release-tool repo so `uv run` resolves
that tool's venv (it is not on `PATH`), then points `create` back at this project
and preserves its exit code when restoring the working directory:

```bat
@echo off
setlocal
cd /d D:\GIT\BenjaminKobjolke\release-tool
call uv run python -m release_tool create "%~dp0release_create.ini" --project-root "%~dp0.." %*
set "RELEASE_EXIT_CODE=%ERRORLEVEL%"
cd /d "%~dp0"
endlocal & exit /b %RELEASE_EXIT_CODE%
```

`%~dp0` is the bat's own folder (`…\tools\`): `"%~dp0release_create.ini"` is the
config from step 3 and `"%~dp0.."` is the project root. `%*` forwards
`--internal` / `--dry-run`. Do not rewrite this pattern — it matches every other
release/publish bat in these projects.

### 5. Wire publishing to the built version + previous online version

`create` writes the previous (online) version to `previous_version_file`
(default `tools/previous_version.txt`) and calls the publish bat with **no
arguments**. Make the existing `tools/publish_release.bat` read that file (prefer
an explicit `%1` if the user runs it by hand):

```bat
set "PREV=%~1"
if not defined PREV if exist "%~dp0previous_version.txt" set /p "PREV="<"%~dp0previous_version.txt"
... --previous-version "%PREV%" ...
```

The previous online version names the remote archive; it is separate from the
version of the artifact being shipped. Do not use it to select the new artifact.

Inspect every publish channel's artifact and release-note selection. If either
uses mutable source/build state (`pubspec.yaml`, `version.txt`, Android
`local.properties`, etc.), change that handoff. Later APK builds can overwrite
`local.properties` even while an older AAB is awaiting upload. Reuse existing
artifact metadata where available; otherwise have the release build record its label
next to the artifacts only after successful completion and artifact checks
(e.g. `releases/windows/release_version.txt`, already ignored if `releases/` is).
Publishing must use that completed-build label, or an explicit artifact label/path
for older builds, without bumping the version. Fail if the record or selected
artifact is missing; never guess from the current source version or silently
select another artifact. For an AAB uploader that already accepts a properties
file, save a version snapshot beside `app-release.aab` after the AAB build succeeds
and use that snapshot for release-note discovery. Never refresh it from current
`local.properties` during upload. For older bundles, recover `versionCode` from
the embedded manifest rather than inferring it from current source or notes folders.
Preserve a previous completed record only while its artifact still matches; when
a build overwrites an artifact in place, invalidate its old metadata before the
build so failures cannot leave a mismatched pair available for upload.

Keep the existing previous-version argument. If a manual artifact-label override
is needed, use a separate argument (e.g. `%2`) and document their distinct meanings.
Check copies before signing/uploading. Build/publish wrappers must capture the
child command's `%ERRORLEVEL%` immediately and return it after cleanup or `cd`,
as in the launcher above.

Replace any hardcoded `--previous-version <x>` with `--previous-version "%PREV%"`.
Then add the version file to `.gitignore` (it is transient local publish state):

```
tools/previous_version.txt
```

### 6. Copy the per-stack release-notes recipe into `tools/`

`create` authors missing release notes by having Codex follow the
`release-create-release-notes` skill, which reads the per-stack recipe from
`tools/CREATE_RELEASE_NOTES.md` (relative to the project root, so it resolves for
Codex, whose cwd is the project root). Put that file in place:

- Locate the shared recipe. Try
  `D:\GIT\BenjaminKobjolke\claude-coding-rules\plugins\coding-rules\rules\CREATE_RELEASE_NOTES.md`.
  If that path doesn't exist, **ask the user** where their
  `CREATE_RELEASE_NOTES.md` lives.
- Copy it to `$CLAUDE_PROJECT_DIR/tools/CREATE_RELEASE_NOTES.md`.
- Add it to `.gitignore` (it's a snapshot copy of a shared doc, not project
  source — same treatment as `tools/previous_version.txt` in step 5):

  ```
  tools/CREATE_RELEASE_NOTES.md
  ```

This copy is a **snapshot** — re-run this setup to refresh it if the shared recipe
changes. The project's `docs/CREATE_NEW_RELEASE.md` always wins over it, so if you
can't obtain the recipe, skip this step: notes still get created from the project
doc alone.

### 7. Verify

Run the launcher in dry-run mode:

```
tools\release_create.bat --dry-run
```

Confirm it prints the expected next label, logs writing `previous_version_file`,
shows both prompts (publish? / commit, tag and push?), and that every configured
bat path resolves without error. Fix the config if a path is wrong. A dry run
only previews orchestration; it does not execute the build/publish handoff.

For changed wrappers, leave one runnable isolated check using fake build/upload
commands and temporary artifacts. For Flutter projects with combined Android/AAB
and Windows releases, reuse
[setup_files/test_release_version.py.template](setup_files/test_release_version.py.template):
copy it to the project's `tools/test_release_version.py` and adapt the batch names,
installer name, external-tool paths, and metadata conventions to the discovered
release flow. It is a working Turbo Habits example, not a universal project layout.
Keep the fake commands and temporary workspace; never replace them with live builds
or uploads. Run `python tools/test_release_version.py` from the project root.
For other stacks, use a small check matching their actual flow.

Verify one bump across all platforms; then
build an artifact, advance the source version independently (e.g. build label
`1.0.0_504`, then source counter `505`), and confirm publishing still selects the
completed build without changing the source. Also verify failed builds keep the
previous record when its artifact survives, invalidate metadata for overwritten
artifacts, and stop before upload for missing records/artifacts. Check release-note
selection as well as artifact selection for every configured publish channel, and
verify child failures remain nonzero through publish and launcher. Do not build or publish a real release
just to validate setup.

### 8. Document it

Add a short section to `$CLAUDE_PROJECT_DIR/docs/CREATE_NEW_RELEASE.md` stating that
the one-command release is `tools\release_create.bat` (add `--internal` for an
internal test build), that it asks before publishing and before commit/tag/push,
and that `tools/release_create.ini` configures it. Document which script owns
the bump, where the completed artifact version is recorded, and how to retry
publishing an existing build without rebuilding or incrementing.

## After setup

After adding or editing this `commands/*.md`, run
`claude-code/tools/sync_commands_to_codex.bat` afterward to make the skill available
in Codex too.
