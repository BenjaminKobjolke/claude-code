# Publish Release (`tools/publish_release.bat`)

How the FTP publish system for single-artifact apps (Windows `.exe` / `.zip`) gets set up and used.
This is **Backend B** of the `/build-and-upload:setup` skill
([`commands/build-and-upload/setup.md`](../commands/build-and-upload/setup.md)) — see that skill for the
full guided install; this doc is the quick reference for a project that already has it.

## What it is

Publishes one built artifact over FTP via the
[release-tool](https://github.com/BenjaminKobjolke). On each publish it:

- backs up the previously uploaded file (rename) or deletes it,
- optionally code-signs the exe first,
- auto-uploads any new `release_notes/<version>_<build>/` folders alongside the artifact.

It is a **separate, explicit step that runs after the build** — never fold it into `build_release.bat`.

## The two files

Source templates live in `commands/build-and-upload/setup-files/`:

| File | Purpose |
|---|---|
| `tools/publish_release.bat` | Wrapper. `cd`s into the release-tool and runs `uv run python -m release_tool <ARTIFACT> <CONFIG> --previous-version <PREV_VERSION> --verbose`. |
| `tools/publish_settings.ini` | FTP + policy config. **Gitignored** (holds the FTP password). The tracked template is `publish_settings.ini.example`. |

## Setup

1. Run `/build-and-upload:setup`, pick **Backend B** — copies both templates into `tools/`.
2. Edit `tools/publish_release.bat`:
   - `RELEASE_TOOL_DIR` — release-tool checkout (default `D:\GIT\BenjaminKobjolke\release-tool`).
   - `ARTIFACT` — path to the built file, relative to `tools\` (e.g. `%~dp0..\release\<label>\app.exe`).
   - `PREV_VERSION` — previously released version (names the backup folder when `subfolder_naming = version`).
3. Copy `publish_settings.ini.example` → `publish_settings.ini`, fill in the values (below).

**Prereq:** the release-tool must be checked out and `uv sync` run in it (Python 3.11+ and
[uv](https://docs.astral.sh/uv/)). The bat aborts if `<RELEASE_TOOL_DIR>\pyproject.toml` is missing.

## `publish_settings.ini` sections

| Section | Keys |
|---|---|
| `[FTP]` | `host`, `port`, `username`, `password`, `remote_path` (remote folder the artifact lands in). |
| `[OldFileHandling]` | `policy` = `delete` \| `rename`; `subfolder_base` (where renamed backups go); `subfolder_naming` = `timestamp` \| `version` (`version` uses the bat's `--previous-version`). |
| `[PreSigning]` | `enabled = false` to skip. Else `network_path` / `network_path_signed` (signing service watch folders), `expected_signer` (cert CN guard), `poll_interval`, `timeout`. |
| `[ReleaseNotes]` | `path` (local `release_notes` folder) + `remote_path`. New `<version>_<build>` subfolders auto-upload; existing ones are skipped. |

## Usage

```bat
tools\publish_release.bat
```

Add `--dry-run` to the `uv run` line inside the bat to preview FTP operations without uploading.

## Gotchas

- **configparser `%`:** a literal `%` in any value (e.g. a password) must be doubled as `%%`.
- `tools/publish_settings.ini` is gitignored; only the `.ini.example` template is committed.
- Pairs with `/release:setup` — that command produces the `release_notes/<version>_<build>/` tree that
  `[ReleaseNotes]` uploads.
