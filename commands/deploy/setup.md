---
description: Set up ftp-sync FTP deploy for this project — deploy/ folder with sync bat, watcher bat and INI config (ax-suite-contest pattern)
---

# Deploy Setup (ftp-sync mirror)

Installs an FTP deploy into the current project: a `deploy/` folder holding two bats and an INI
config, plus a `.deployignore` in the synced directory. Uses
[ftp-sync](D:\GIT\BenjaminKobjolke\ftp-sync) in **mirror mode** — remote files absent locally are
deleted in the target directory.

Reference implementations: `D:\wamp64\www\ax-suite-contest\deploy\` and
`D:\GIT\next-reality\appcentrics-webseite\deploy\`.

Related: `/build-and-upload:setup` Backend C is the same mechanism but installs into `tools/`
for build+publish flows. This command is the plain "sync this folder to FTP" variant with a
watcher. The "Shared ftp-sync notes" section of `build-and-upload/setup.md` applies here too.

## Step 1: Gather inputs

Ask only what you can't infer:

1. **ftp-sync directory** — default `D:\GIT\BenjaminKobjolke\ftp-sync`. Verify `<dir>\main.py`
   exists; if not, tell the user to clone the repo and run its `install.bat` (Python 3.11+ + uv).
2. **Local directory to deploy** — the folder whose contents ship (project root or a subfolder
   like `click-dummy/`). Becomes `LOCAL_DIRECTORY` (absolute path).
3. **FTP host / user / password** — check sibling projects' `deploy/config_*.php|ini` for
   existing credentials to the same host before asking.
4. **FTP target directory** — `FTP_DIRECTORY`. **DANGER:** mirror mode deletes remote files not
   present locally. Always confirm the target dir with the user explicitly; uploading to `/` of a
   host that serves a live site will destroy it. Prefer a subdirectory for anything experimental.
5. **Config name** — short site slug for filenames, e.g. `appcentrics_de` →
   `config_appcentrics_de.ini`, `ftp-sync-appcentrics.bat`.

## Step 2: Create `deploy/` files from templates

Templates live next to this command in `setup_files/`, reachable at
`~/.claude/commands/deploy/setup_files/` (symlink to
`D:\GIT\BenjaminKobjolke\claude-code\commands\deploy\setup_files`).

Copy into `<project>/deploy/` (create the folder; don't overwrite existing files without
confirming), replacing `SLUG` in both filename and file content with the slug from Step 1.5:

| Template | Destination | Purpose |
|---|---|---|
| `ftp-sync-SLUG.bat` | `deploy/ftp-sync-<slug>.bat` | One-shot sync via ftp-sync. |
| `ftp-sync-SLUG-watcher.bat` | `deploy/ftp-sync-<slug>-watcher.bat` | Watches local files, auto-syncs on change (2s debounce). |
| `config_SLUG.ini.example` | `deploy/config_<slug>.ini.example` | Tracked placeholder template. |
| `config_SLUG.ini.example` | `deploy/config_<slug>.ini` | The real config — fill in Step 1 values. |

configparser note: a literal `%` in any value (passwords!) must be doubled as `%%`.

## Step 3: `.deployignore`

Copy `setup_files/deployignore.example` to the **root of `LOCAL_DIRECTORY`** (not necessarily
the repo root) as `.deployignore` and **trim to the project** — gitignore syntax, paths relative
to that directory. Typical excludes: `docs/`, `logs/`, `tools/`, `tests/`, build sources
(`scss/`, `ts/` — built output still ships), `README.md`, `CLAUDE.md`, `composer.json`,
`composer.lock`, `.gitignore`, dev-only files (`router.php`). If a `.deployignore` already
exists there, merge instead of overwrite.

Always exclude `.ftp_sync_cache.db` — the hash cache lives in `LOCAL_DIRECTORY` root
(ax-suite pattern) and must not upload itself.
Do NOT exclude `vendor/` for PHP projects — it is gitignored but must ship.
Excluded paths are invisible to deletion too, so server-owned files (runtime config, uploads)
stay safe when excluded.

## Step 4: Gitignore the secrets

In the project's `.gitignore`:

```
deploy/config_<slug>.ini
```

And in `LOCAL_DIRECTORY`'s `.gitignore` (or the same one if identical): `.ftp_sync_cache.db`.

The `.ini.example`, bats and `.deployignore` stay tracked.

## Step 5: Verify BEFORE first upload

Offline dry-run — prints the exact file list without connecting to FTP:

```powershell
Set-Location D:\GIT\BenjaminKobjolke\ftp-sync; uv run python -c "import sys; sys.path.insert(0, r'D:\GIT\BenjaminKobjolke\ftp-sync'); from sync import build_merged_file_map as b; p=sorted(b((r'<LOCAL_DIRECTORY>',))); print(len(p),'files'); [print(x) for x in p if x.startswith(('docs/','logs/','tools/','tests/'))]"
```

Sane file count, zero excluded paths printed → good. Then let the user run the first sync
themselves (it uploads with real credentials).

## Step 6: Confirm

Summarize for the user:

- `deploy\ftp-sync-<slug>.bat` — one-shot sync (first run uploads everything + builds hash cache;
  later runs upload only changed files).
- `deploy\ftp-sync-<slug>-watcher.bat` — keep running while editing; auto-syncs on save.
- Hash-cache caveat: deletion is tracked via the local cache, so pre-existing remote files from
  before the first run are never auto-pruned — clean them manually once if the target dir wasn't
  empty. `--resync` clears the cache for a full re-upload.
- The config INI is gitignored (holds the FTP password).
