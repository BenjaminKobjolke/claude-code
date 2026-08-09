---
description: Set up tools/release_create.ini + tools/release_create.bat so one command runs the full release
---

Wire up the **`release-tool create`** subcommand for this project by writing two
files into the project's `tools/` folder:

- `tools/release_create.ini` — the per-project config (which bats, scope, platform).
- `tools/release_create.bat` — a launcher that runs the whole release in one command.

This is a **config + launcher** setup — do not modify project source code. The
subcommand itself lives in the `release-tool` package
(`D:\GIT\BenjaminKobjolke\release-tool`); this command only produces the two
per-project files that drive it.

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
names differ from the defaults, record the real paths.

### 2. Determine the scalars

- `scope` — the commit scope for `RELEASE (<scope>): <label>` (usually the app/tool short name).
- `publish_platform` — the human name of the publish target from the project doc
  (e.g. "Google Play Store", "Website"). If the project has **no** publish step,
  omit the `publish` bat entirely (the release then builds and stops — no commit/tag).
- `english_only` — `true` if the project ships English-only / has no translator bat.
- `notes_dir` / `en_file` / `label_format` — only set these if they differ from the
  defaults (`release_notes`, `en.json`, `{version}_{build}`).

### 3. Write `tools/release_create.ini`

Write it at `$CLAUDE_PROJECT_DIR/tools/release_create.ini`. List **only** values
that differ from the defaults — keep it minimal. Match the template at
`release-tool/examples/release_create.ini`. The `[Bats]` paths stay relative to
the **project root** (`tools/version_get.bat`, …), not to the `tools/` folder —
the launcher passes the project root as `--project-root`. Example:

```ini
[Release]
scope = myapp
publish_platform = Google Play Store

[Bats]
publish = tools/publish_release.bat
```

### 4. Write `tools/release_create.bat`

Write this launcher verbatim (match `release-tool/examples/release_create.bat`).
It cd's into the release-tool repo so `uv run` resolves that tool's venv (it is
not on `PATH`), then points `create` back at this project:

```bat
@echo off
cd /d D:\GIT\BenjaminKobjolke\release-tool
call uv run python -m release_tool create "%~dp0release_create.ini" --project-root "%~dp0.." %*
cd /d "%~dp0"
```

`%~dp0` is the bat's own folder (`…\tools\`): `"%~dp0release_create.ini"` is the
config from step 3 and `"%~dp0.."` is the project root. `%*` forwards
`--internal` / `--dry-run`. Do not rewrite this pattern — it matches every other
release/publish bat in these projects.

### 5. Verify

Run the launcher in dry-run mode:

```
tools\release_create.bat --dry-run
```

Confirm it prints the expected next label (current version + build + 1) and that
every configured bat path resolves without error. Fix the config if a path is wrong.

### 6. Document it

Add a short section to `$CLAUDE_PROJECT_DIR/docs/CREATE_NEW_RELEASE.md` stating that
the one-command release is `tools\release_create.bat` (add `--internal` for an
internal test build), and that `tools/release_create.ini` configures it.

## After setup

This command adds a new `commands/*.md`, so run
`claude-code/tools/sync_commands_to_codex.bat` afterward to make the skill available
in Codex too.
