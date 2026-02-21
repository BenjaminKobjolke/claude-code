# Design: /setting:install Command

## Problem

Installing settings from this repo requires manually running platform-specific install scripts. There's no unified command to discover available settings and install them, and no way to install remotely without cloning the repo first.

## Solution

A Claude Code custom command (`/setting:install`) that:
1. Discovers available settings from the remote GitHub repo
2. Auto-detects the platform
3. Streams the install script directly to execution via pipe (`irm | iex` on Windows, `curl | bash` on macOS)
4. Install scripts have a remote fallback for companion files when running from a pipe

## Design Decisions

- **Auto-discover over hardcoded:** Scans the remote `settings/` directory via GitHub API so new settings appear automatically
- **Argument or picker:** `$ARGUMENTS` selects directly; no argument triggers a picker
- **Platform auto-detect:** Uses runtime platform detection (win32/darwin), no user prompt needed
- **Stream to execution:** No temp download needed for the install script itself (`irm <url> | iex` / `curl -fsSL <url> | bash`)
- **Remote fallback in install scripts:** When companion files aren't found locally, download them from GitHub raw URLs
- **API method:** `gh api` with `curl` fallback for listing remote settings

## Architecture

### Part 1: Command File (`commands/setting/install.md`)

Flow:
```
/setting:install [name]
        |
        v
  Query GitHub API for settings/ directory contents
  (gh api -> curl fallback)
        |
        v
  Filter for directories containing install scripts
        |
        v
  Argument given?
  ├─ Yes: match to discovered setting (error if not found)
  └─ No:  ask user to pick from list
        |
        v
  Detect platform (win32 -> PowerShell, darwin -> Bash)
        |
        v
  Stream install script to execution:
    win32:  powershell -Command "irm '<raw-url>' | iex"
    darwin: curl -fsSL '<raw-url>' | bash
```

Remote URLs:
- `https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/<name>/win/install.ps1`
- `https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/<name>/mac/install.sh`

### Part 2: Install Script Remote Fallback

Both `win/install.ps1` and `mac/install.sh` enhanced with:
- A remote base URL constant pointing to the raw GitHub content
- When copying companion files to `~/.claude/settings/<name>/`: check local path first, if not found download from remote
- Downloaded files go directly to the target directory (`~/.claude/settings/<name>/`)

## File Changes

| File | Change |
|------|--------|
| `commands/setting/install.md` | **New** -- command definition |
| `settings/status-line/win/install.ps1` | **Modified** -- add remote fallback |
| `settings/status-line/mac/install.sh` | **Modified** -- add remote fallback |

## Convention for Future Settings

```
settings/<name>/
  win/install.ps1   (with remote fallback)
  mac/install.sh    (with remote fallback)
  win/*.ps1, *.json (companion files)
  mac/*.sh, *.json  (companion files)
```
