# Universal Setting Installer — Design Document

**Date:** 2026-02-22
**Branch:** `feature/universal-setting-installer`
**Status:** Approved

## Overview

Rework the settings install system into a universal, remote-first plugin manager. A single `install.ps1` / `install.sh` script (per platform) replaces the current two-tier launcher + per-plugin installer architecture. Plugins use a flat directory structure with platform filtering by file extension.

## Goals

- **Universal:** One installer handles any plugin layout — no per-plugin install scripts required for basic install/uninstall
- **Remote-first:** Only platform-relevant runtime files are stored locally. Everything else (settings merge, post-install hooks, README) is handled remotely
- **Smart:** Detects if a plugin is installed and offers Update/Uninstall choice
- **Safe:** Deep merge with diff preview, user confirmation, backup rotation, atomic writes, post-write validation

## Plugin Directory Structure

Plugins live in `settings/<plugin>/` with a flat layout:

```
settings/<plugin>/
    *.ps1               # Windows shell scripts (downloaded on Windows)
    *.bat               # Windows batch files (downloaded on Windows)
    *.cmd               # Windows command scripts (downloaded on Windows)
    *.sh                # macOS/Linux shell scripts (downloaded on macOS)
    *.zsh               # macOS/Linux zsh scripts (downloaded on macOS)
    *.command           # macOS double-clickable scripts (downloaded on macOS)
    settings.json       # Merged into ~/.claude/settings.json (never downloaded)
    install.[ps1|sh]    # Post-install hook, run remotely (never downloaded)
    uninstall.[ps1|sh]  # Pre-uninstall hook, run remotely (never downloaded)
    README.md           # Opened in browser after install (never downloaded)
    *.*                 # Any other files downloaded as shared dependencies
```

### File Classification Rules

| Pattern | Action |
|---|---|
| `settings.json` | Deep merge into `~/.claude/settings.json` (fetched remotely) |
| `install.ps1` (Windows) / `install.sh` (macOS) | Execute remotely after file downloads and settings merge |
| `uninstall.ps1` (Windows) / `uninstall.sh` (macOS) | Execute remotely during uninstall, before un-merge |
| `README.md` | Open in default browser after install completes |
| `*.ps1`, `*.bat`, `*.cmd` | Download on Windows only, skip on macOS |
| `*.sh`, `*.zsh`, `*.command` | Download on macOS only, skip on Windows |
| Everything else | Download on all platforms (shared dependency) |

### Local Filesystem After Install

```
~/.claude/
    settings.json                          # Has plugin keys merged in
    settings/<plugin>/
        <platform-relevant files only>     # e.g., status-line.ps1 on Windows
        <shared dependency files>          # e.g., .json configs, data files
```

## Universal Installer Location

```
commands/setting/
    install.md          # Claude command entry point (updated)
    uninstall.md        # Shorthand entry point (NEW)
    install.ps1         # Universal installer — Windows (NEW)
    install.sh          # Universal installer — macOS (NEW)
    CLAUDE.md           # Development guide (updated)
```

Replaces and deletes:
- `settings/install.ps1` (old launcher)
- `settings/install.sh` (old launcher)

## Command Entry Points

| Command | Behavior |
|---|---|
| `/setting:install` | GitHub API discovery → list all plugins → user selects → if installed: Update/Uninstall choice (Update default); if new: install |
| `/setting:install <name>` | Skip discovery → if installed: Update/Uninstall choice; if new: install |
| `/setting:install --uninstall <name>` | Explicit uninstall, no choice prompt |
| `/setting:install --uninstall` | List installed plugins only → user selects → uninstall |
| `/setting:uninstall` | Shorthand for `--uninstall` (no argument) |
| `/setting:uninstall <name>` | Shorthand for `--uninstall <name>` |

### install.md

Detects platform, sets environment variables, launches the universal installer in a new terminal window via `Start-Process` (Windows) or `osascript` (macOS).

- `$env:SETTING_NAME` — plugin name (may be empty for discovery)
- `$env:UNINSTALL` — set to `"true"` for uninstall mode

### uninstall.md

Same as install.md but always sets `$env:UNINSTALL="true"`.

## Install/Update Flow

1. **Resolve plugin name**
   - If `$env:SETTING_NAME` is set → use it
   - Else → GitHub API: `GET /repos/{owner}/{repo}/contents/settings`
   - Filter to directories (type == "dir")
   - Present numbered list, user selects via `Read-Host` / `read -rp`

2. **Detect if installed**
   - Check if `~/.claude/settings/<plugin>/` exists locally

3. **If installed → prompt choice**
   - "Plugin is already installed. [U]pdate (default) / [R]emove?"
   - Update → continue with install flow (full reinstall)
   - Remove → switch to uninstall flow

4. **Enumerate plugin files**
   - GitHub API: `GET /repos/{owner}/{repo}/contents/settings/{plugin}`
   - Single API call returns flat file list
   - Classify each file per the rules above

5. **Download files**
   - Create `~/.claude/settings/<plugin>/` if needed
   - Download each DOWNLOAD-classified file from `raw.githubusercontent.com`
   - Report progress per file

6. **Deep merge settings.json** (if plugin has one)
   - Fetch plugin's `settings.json` from raw URL
   - Read `~/.claude/settings.json` (create `{}` if missing)
   - Deep merge (see algorithm below)
   - Show colored diff preview
   - User confirms (Y/n)
   - Backup rotation (`.bak` → `.bak.1`, current → `.bak`)
   - Atomic write (write `.tmp`, rename to target)
   - Post-write validation (re-read and verify JSON parses)

7. **Run plugin's install hook** (if `install.[ps1|sh]` exists remotely)
   - Fetch script from raw URL
   - Execute via `iex` (Windows) / `bash -s` (macOS)
   - This handles plugin-specific post-install (e.g., customization wizard)

8. **Open README.md** (if exists remotely)
   - Open GitHub raw URL in default browser
   - `Start-Process $url` (Windows) / `open $url` (macOS)

## Uninstall Flow

1. **Resolve plugin name**
   - If provided → use it
   - Else → scan `~/.claude/settings/` for installed plugin directories
   - Present list, user selects

2. **Run plugin's uninstall hook** (if `uninstall.[ps1|sh]` exists remotely)
   - Fetch from raw URL, execute remotely

3. **Deep un-merge settings.json** (if plugin has `settings.json` remotely)
   - Fetch plugin's `settings.json` from raw URL
   - Read `~/.claude/settings.json`
   - Deep un-merge (see algorithm below)
   - Show colored diff preview
   - User confirms
   - Backup rotation + atomic write + validation

4. **Delete local files**
   - Remove `~/.claude/settings/<plugin>/` entirely

## Deep Merge Algorithm

### Merge (Install/Update)

```
function deepMerge(target, source):
    for each key in source:
        if key not in target:
            target[key] = source[key]              # New key → add
        else if both values are objects:
            deepMerge(target[key], source[key])     # Recurse
        else if both values are arrays:
            for each item in source[key]:
                if item not in target[key]:
                    append item to target[key]      # Append unique
        else:
            target[key] = source[key]               # Scalar → overwrite
```

### Un-Merge (Uninstall)

```
function deepUnmerge(target, source):
    for each key in source:
        if key not in target:
            continue                                 # Nothing to remove
        else if both values are objects:
            deepUnmerge(target[key], source[key])    # Recurse
            if target[key] is empty:
                delete target[key]                   # Clean up empty
        else if both values are arrays:
            for each item in source[key]:
                remove item from target[key]         # Remove matches
            if target[key] is empty:
                delete target[key]                   # Clean up empty
        else if target[key] == source[key]:
            delete target[key]                       # Matching scalar → remove
        # else: value differs → user modified it → leave it
```

## Safety Features

- **Diff preview:** Colored diff shown before any settings.json modification
- **User confirmation:** Must confirm (Y/n) before write proceeds
- **Backup rotation:** Two revisions kept (`.bak` and `.bak.1`)
- **Atomic write:** Write to `.tmp` file first, then rename
- **Post-write validation:** Re-read file and verify valid JSON
- **Installed detection:** Prevents accidental double-install without user choice

## Status-Line Migration

The `status-line` plugin is migrated from the old `win/` + `mac/` structure to the new flat structure:

### Files Moved/Renamed

| Old Path | New Path |
|---|---|
| `settings/status-line/win/status-line.ps1` | `settings/status-line/status-line.ps1` |
| `settings/status-line/mac/status-line.sh` | `settings/status-line/status-line.sh` |
| `settings/status-line/win/setup.ps1` | `settings/status-line/install.ps1` (renamed) |
| `settings/status-line/mac/setup.sh` | `settings/status-line/install.sh` (renamed) |
| `settings/status-line/win/uninstall.ps1` | `settings/status-line/uninstall.ps1` |
| `settings/status-line/mac/uninstall.sh` | `settings/status-line/uninstall.sh` |
| `settings/status-line/win/settings.json` | `settings/status-line/settings.json` (one shared copy) |
| `settings/status-line/mac/settings.json` | (deleted, merged into shared) |
| `settings/status-line/win/install.ps1` | (deleted, replaced by universal installer) |
| `settings/status-line/mac/install.sh` | (deleted, replaced by universal installer) |
| `settings/status-line/README.md` | `settings/status-line/README.md` (stays) |

### Refactoring Notes

- `setup.ps1` / `setup.sh` → renamed to `install.ps1` / `install.sh` and refactored to work as post-install hooks (customization wizard) called by the universal installer
- Old per-plugin `install.ps1` / `install.sh` logic (file copying, settings merge) is removed — the universal installer handles all of that now
- `uninstall.ps1` / `uninstall.sh` refactored to only contain plugin-specific cleanup logic (the universal installer handles settings un-merge and file deletion)

## Files Deleted

- `settings/install.ps1` — replaced by `commands/setting/install.ps1`
- `settings/install.sh` — replaced by `commands/setting/install.sh`
- `settings/status-line/win/` — entire directory (flattened)
- `settings/status-line/mac/` — entire directory (flattened)

## Technical Notes

- **PowerShell piping:** `irm | iex` does NOT break `Read-Host` — it reads from console, not stdin
- **`param()` bypass:** Use `$env:SETTING_NAME` and `$env:UNINSTALL` instead of `param()` (doesn't work when piped)
- **macOS Bash 3.2 compatibility:** No `mapfile`, no associative arrays, no `&>>`
- **GitHub API rate limiting:** Unauthenticated limit is 60 req/hr. Two API calls per install (list settings dir + list plugin dir). Graceful error message if rate-limited.
- **Config variables:** `$REPO`, `$BRANCH`, `$DIR` at top of scripts for easy customization
