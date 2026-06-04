---
description: Set up the ftp-sync based build + upload tooling (bats + INIs) in this project's tools folder
---

# Build & Upload Setup

Installs a reusable APK build + FTP upload system into the current project's `tools/` folder. Uploads
use the [ftp-sync](https://github.com/BenjaminKobjolke) tool in **no-delete** mode (existing remote
files are kept) with live single-line upload progress.

This targets **Flutter Android** projects: release APKs are uploaded as `app_v<version>_<build>.apk`
(version read from `pubspec.yaml`), debug APKs as `kiosk-locker-debug.apk` (fixed name).

The reusable template files live next to this command in `setup-files/`, reachable at
`~/.claude/commands/build-and-upload/setup-files/` (symlink to
`D:\GIT\BenjaminKobjolke\claude-code\commands\build-and-upload\setup-files`).

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
