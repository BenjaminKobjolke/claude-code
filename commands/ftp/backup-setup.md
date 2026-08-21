---
description: Set up an ftp-sync based FTP backup for this project — backup bat (download mirror + zip revisions) and INI config in deploy/
---

# FTP Backup Setup (ftp-sync download + zip revisions)

Installs an FTP **backup** into the current project: a `deploy/ftp-backup-<slug>.bat` that
mirrors a remote FTP directory into `<backup root>\current` via
[ftp-sync](D:\GIT\BenjaminKobjolke\ftp-sync) in **download mode** (`DIRECTION = down`), then
zips a timestamped snapshot into `<backup root>\revisions\` and keeps the newest N (default 30).

Reference implementation: `D:\GIT\Intern\nutriniche-website\deploy\ftp-backup-nutriniche.bat`.

Related: `/deploy:setup` is the upload (deploy) variant of the same tool. If the project already
has a `deploy/config_<slug>.ini` from it, reuse its FTP credentials.

## Step 1: Gather inputs

Ask only what you can't infer:

1. **ftp-sync directory** — ask the user where the ftp-sync tool is installed; default
   `D:\GIT\BenjaminKobjolke\ftp-sync`. Verify `<dir>\main.py` exists; if not, tell the user to
   clone the repo and run its `install.bat` (Python 3.11+ + uv).
   Download mode needs the fixes from 2026-08-21 (recursive listing, `TYPE I` before `SIZE`,
   `handle_old_files` vs remote list, thread-safe mkdir). Symptom of a stale checkout: a run
   that downloads 0 files with many `Couldn't get size` warnings, or unchanged files migrating
   into `current\old\` on every run — update the ftp-sync repo.
2. **Backup target directory** — ask the user; becomes `BACKUP_ROOT` (e.g.
   `E:\Backups\<site>\ftp`). The bat derives `current\` (mirror) and `revisions\` (zips) from it.
3. **FTP host / user / password / remote directory** — check `deploy/config_*.ini` of this
   project (and sibling projects for the same host) before asking. Remote directory becomes
   `FTP_DIRECTORY` — the folder on the server to back up.
4. **Config name** — short site slug for filenames, e.g. `nutriniche` →
   `config_nutriniche_backup.ini`, `ftp-backup-nutriniche.bat`.
5. **Revisions to keep** — default 30 (`KEEP` variable in the bat).

## Step 2: Create `deploy/` files from templates

Templates live next to this command in `setup_files/`, reachable at
`~/.claude/commands/ftp/setup_files/` (symlink to
`D:\GIT\BenjaminKobjolke\claude-code\commands\ftp\setup_files`).

Copy into `<project>/deploy/` (create the folder; don't overwrite existing files without
confirming), replacing the placeholders in both filename and file content:

| Placeholder | Replace with |
|---|---|
| `SLUG` | slug from Step 1.4 |
| `FTPSYNCDIR` | ftp-sync directory from Step 1.1 |
| `BACKUPROOT` | backup target directory from Step 1.2 |

| Template | Destination | Purpose |
|---|---|---|
| `ftp-backup-SLUG.bat` | `deploy/ftp-backup-<slug>.bat` | Sync down + zip snapshot + prune. |
| `config_SLUG_backup.ini.example` | `deploy/config_<slug>_backup.ini.example` | Tracked placeholder template. |
| `config_SLUG_backup.ini.example` | `deploy/config_<slug>_backup.ini` | The real config — fill in Step 1 values. |

Set `KEEP` in the bat if the user chose something other than 30.

configparser note: a literal `%` in any value (passwords!) must be doubled as `%%`.

`IGNORE_DIRS` in the config skips whole remote trees during listing AND download — keep
`node_modules, .git, vendor` unless the user wants them; remote dirs often hold stale copies
from pre-`.deployignore` deploys, and traversing them over FTP is very slow.

## Step 3: Gitignore the secrets

In the project's `.gitignore`:

```
deploy/config_<slug>_backup.ini
```

The `.ini.example` and the bat stay tracked.

## Step 4: Verify

1. Run `deploy\ftp-backup-<slug>.bat` — files land in `<BACKUP_ROOT>\current`, one
   `revisions\<timestamp>.zip` appears.
2. Run again — unchanged files log `Skipping ... (already exists with same size)`, a second zip
   appears, and NOTHING moves into `current\old\` (if it does, the ftp-sync checkout is stale —
   see Step 1.1).
3. Prune: drop 31+ dummy `*.zip` into `revisions\`, run again, confirm only the newest `KEEP`
   remain; delete the dummies.

## Step 5: Confirm

Summarize for the user:

- `deploy\ftp-backup-<slug>.bat` — one command: download changed files, zip snapshot, prune to
  `KEEP` revisions. Safe to run repeatedly / from Task Scheduler.
- Change detection on download is **size-only** — a same-size content change is not re-fetched.
- Files deleted on the server are stashed in `current\old\` (flat, not versioned) and are
  included in later snapshots.
- The config INI is gitignored (holds the FTP password).

## Bat gotchas (why the template looks the way it does)

- `tar` is called as `%SystemRoot%\System32\tar.exe` (bsdtar): under Git Bash, GNU `tar` parses
  `E:\...` as `host:file` and fails with `Cannot connect to E: resolve failed`.
- The prune uses PowerShell `-LiteralPath`: backup paths containing `[ ]` (e.g. Syncthing
  folders) are wildcard patterns to `-Path` and silently match nothing.
- The sync exit code is captured before `cd /d "%~dp0"`, because a successful `cd` resets
  `%ERRORLEVEL%`.
- Timestamp comes from PowerShell `Get-Date -Format yyyy-MM-dd_HHmmss`, not `%date%` — locale-safe.
