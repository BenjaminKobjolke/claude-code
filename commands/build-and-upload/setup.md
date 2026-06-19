---
description: Set up the ftp-sync based build + upload tooling (bats + INIs) in this project's tools folder
---

# Build & Upload Setup

Installs a reusable FTP publish system into the current project's `tools/` folder. There are **two
backends — pick by artifact type:**

- **Backend A — ftp-sync (Flutter Android APK).** Syncs APKs in **no-delete** mode with live
  single-line progress. Release APKs upload as `app_v<version>_<build>.apk` (version from
  `pubspec.yaml`), debug APKs as `kiosk-locker-debug.apk`. See "Backend A" below.
- **Backend B — release-tool (Windows `.exe` / single artifact).** Publishes one built file via the
  [release-tool](https://github.com/BenjaminKobjolke), with previous-version backup, optional code
  signing, and automatic release-notes upload. See "Backend B" below. Use this for desktop apps and
  anything set up by `/release:setup`.

The reusable template files live next to this command in `setup-files/`, reachable at
`~/.claude/commands/build-and-upload/setup-files/` (symlink to
`D:\GIT\BenjaminKobjolke\claude-code\commands\build-and-upload\setup-files`).

---

# Backend A — ftp-sync (Flutter Android APK)

## Step 1: Gather inputs

Ask the user (use sensible defaults, only ask what you can't infer):

1. **ftp-sync directory** — path to the ftp-sync tool checkout. Default `D:\GIT\BenjaminKobjolke\ftp-sync`.
   Verify `<dir>\main.py` exists; if not, tell the user to check out the repo and run its `install.bat`
   (needs Python 3.11+ and [uv](https://docs.astral.sh/uv/)).
2. **FTP host**, **FTP user**, **FTP password**.
3. **FTP target directory** — where APKs land on the server. Default `/` (most accounts are chrooted to
   the right folder). Ends up as `FTP_DIRECTORY` in the INI.
4. **Public link base** (`APK_LINK_DIR`) — the URL the APKs are served from, e.g.
   `https://yourserver.com/apps`. Used only for the printed download link.

Whether release and debug should use the same FTP or different ones: default same values for both INIs;
only ask if the user hints they differ.

## Step 2: Copy the template files into `tools/`

Copy these from `~/.claude/commands/build-and-upload/setup-files/` into `$CLAUDE_PROJECT_DIR/tools/`
(create `tools/` if missing). Do not overwrite an existing file without confirming with the user first:

| File | Purpose |
|---|---|
| `ftpsync_upload.bat` | Shared helper: reads the INI, runs ftp-sync with hash-cache + no-delete, single-line progress. |
| `upload_release-apk-to-ftp.bat` | Stages `app-release.apk` as `app_v<version>_<build>.apk`, syncs via the helper. |
| `upload_debug-apk-to-ftp.bat` | Stages `app-debug.apk` as `kiosk-locker-debug.apk`, syncs via the helper. |
| `build_android.bat` | `call build_android.bat [debug\|release]` — increments build number, builds, verifies. |
| `build_and_upload_android.bat` | One-shot build + upload (release by default, `debug` arg for debug). |
| `build_and_upload_android_debug.bat` | Convenience wrapper for the debug flow. |
| `release.ini.example` | Template for `release.ini`. |
| `debug.ini.example` | Template for `debug.ini`. |

## Step 3: Create the real INIs

From the examples, create `$CLAUDE_PROJECT_DIR/tools/release.ini` and `tools/debug.ini`, filling in the
values from Step 1. Both follow this shape (the `[KIOSK]` section is ignored by ftp-sync and read by the
bats):

```ini
[FTP]
FTP_HOST=<host>
FTP_USER=<user>
FTP_PASS=<password>
FTP_DIRECTORY=<target dir, e.g. />
DIRECTION=up
NO_DELETE=true

[KIOSK]
APK_LINK_DIR=<public link base>
FTPSYNC_DIR=<ftp-sync directory from Step 1>
```

**Important:** values are parsed by Python `configparser` — a literal `%` in any value (e.g. a password)
must be written as `%%`. Warn the user if their password contains `%`.

## Step 4: Gitignore the secrets

Ensure `$CLAUDE_PROJECT_DIR/.gitignore` ignores the credential files (they hold the FTP password). Add if
missing:

```
tools/release.ini
tools/debug.ini
```

The `*.ini.example` templates stay tracked.

## Step 5: Check dependencies

- `build_android.bat` calls `build_number_increment.bat` and reads `pubspec.yaml`. If the build-number
  bats are missing, tell the user to run `/release:setup` (or create them) — the upload bats themselves
  work without them as long as an APK already exists in `build\app\outputs\flutter-apk\`.
- Confirm `<ftp-sync dir>\main.py` exists and ftp-sync's `install.bat` has been run.

## Step 6: Confirm

Summarize what was created/copied and how to use it:

- `tools\build_and_upload_android.bat` — build + upload release.
- `tools\build_and_upload_android_debug.bat` — build + upload debug.
- `tools\upload_release-apk-to-ftp.bat` / `upload_debug-apk-to-ftp.bat` — upload an already-built APK.

Remind the user the release name accumulates versioned APKs on the FTP (no-delete), and that
`tools\release.ini` / `tools\debug.ini` are gitignored.

---

# Backend B — release-tool (Windows `.exe` / single artifact)

Publishes one built file (exe/zip) over FTP via the
[release-tool](https://github.com/BenjaminKobjolke). On each publish it backs up the previously
uploaded file, optionally code-signs, and **auto-uploads any new release-notes folders** — pairs
directly with `/release:setup` (the `release_notes/<version>_<build>/` tree).

## Step 1: Gather inputs

Ask the user (sensible defaults; only ask what you can't infer):

1. **release-tool directory** — checkout of the release-tool. Default
   `D:\GIT\BenjaminKobjolke\release-tool`. Verify `<dir>\pyproject.toml` exists; if not, tell the user
   to check it out and run `uv sync` in it (needs Python 3.11+ and [uv](https://docs.astral.sh/uv/)).
2. **FTP host / port / user / password**.
3. **Remote artifact path** (`[FTP] remote_path`) — where the exe lands, e.g. `/downloads/your-app/`.
4. **Old-file policy** — `rename` (keep backups under `subfolder_base`) or `delete`; and naming
   (`version` uses `--previous-version`, or `timestamp`).
5. **Code signing?** — if yes, the `[PreSigning]` network paths + `expected_signer`; else `enabled = false`.
6. **Release notes?** — if the project has a `release_notes/` folder, the local `path` and the remote
   `remote_path` so notes upload alongside the exe.

## Step 2: Copy the template files into `tools/`

Copy from `~/.claude/commands/build-and-upload/setup-files/` into `$CLAUDE_PROJECT_DIR/tools/` (don't
overwrite without confirming):

| File | Purpose |
|---|---|
| `publish_release.bat` | Runs the release-tool against the built artifact + `publish_settings.ini`. Edit `ARTIFACT` (the exe path, e.g. `..\release\<label>\app.exe` or `..\dist\app.exe`) and `PREV_VERSION`. |
| `publish_settings.ini.example` | Template for `publish_settings.ini`. |

## Step 3: Create the real INI

From the example create `$CLAUDE_PROJECT_DIR/tools/publish_settings.ini`, filling Step 1 values. The
four sections (`[FTP]`, `[OldFileHandling]`, `[PreSigning]`, `[ReleaseNotes]`) are documented inline in
the example. **configparser note:** a literal `%` in any value (e.g. a password) must be doubled as
`%%` — warn the user if their password contains `%`.

## Step 4: Gitignore the secret

The INI holds the FTP password. Ensure `$CLAUDE_PROJECT_DIR/.gitignore` ignores it (the
`*.ini.example` template stays tracked):

```
tools/publish_settings.ini
```

## Step 5: Confirm

- Usage: `tools\publish_release.bat` publishes the configured artifact. Add `--dry-run` to the command
  inside the bat to preview FTP operations without uploading.
- It runs **after** the build (e.g. `tools\build_release.bat`) — keep publish a separate, explicit
  step; do not fold it into the build.
- If `[ReleaseNotes]` is set, new `release_notes/<label>/` folders upload automatically with the exe.
- Remind the user `tools\publish_settings.ini` is gitignored.
