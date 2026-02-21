# Interactive Setting Installer

## Problem

The current `commands/setting/install.md` is a prompt-based instruction file that Claude interprets at runtime. This causes three bugs:

1. Claude uses non-Windows commands on Windows (e.g., `curl` instead of PowerShell)
2. When only one setting exists, Claude auto-installs it instead of prompting the user
3. Claude pipes the install script (`irm ... | iex`) which prevents interactive prompts (`Read-Host`) from working

## Solution

Replace the prompt-driven approach with self-contained platform scripts that run interactively. The `.md` file becomes a minimal dispatcher that tells Claude to run the correct script.

## File Structure

```
commands/setting/
├── install.md          # Minimal — tells Claude which script to run
├── install.ps1         # Windows launcher (PowerShell)
└── install.sh          # macOS launcher (Bash)
```

## install.md (Rewritten)

Simplified to:

1. Detect platform from environment (`win32` → `.ps1`, `darwin` → `.sh`)
2. Run the script as a file with `$ARGUMENTS` passed through
3. Let the user interact — do not interfere with terminal output
4. Report the result based on exit code

## install.ps1 — Windows Launcher

### Parameters

```powershell
param([string]$SettingName)
```

### Flow

1. **Discover settings** — call GitHub API:
   ```powershell
   Invoke-RestMethod 'https://api.github.com/repos/BenjaminKobjolke/claude-code/contents/settings?ref=main'
   ```
   Filter for `type -eq 'dir'` to get setting names.

2. **Select setting:**
   - If `$SettingName` matches a discovered setting → auto-select
   - If `$SettingName` provided but no match → show error + list available settings, exit
   - If no argument → show numbered menu, user picks via `Read-Host`

3. **Download installer to temp:**
   ```powershell
   $url = "https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/$name/win/install.ps1"
   $tempFile = Join-Path $env:TEMP "claude-setting-install-$name.ps1"
   Invoke-RestMethod -Uri $url -OutFile $tempFile
   ```

4. **Run interactively:**
   ```powershell
   & powershell -NoProfile -File $tempFile
   ```

5. **Clean up** temp file.

6. **Exit** with the installer's exit code.

## install.sh — macOS Launcher

Same logic, Bash equivalents:

1. **Discover:** `curl` + `python3` to parse GitHub API JSON
2. **Menu:** numbered list, `read -p` for selection
3. **Download:** `curl -fsSL $url -o $tempFile`
4. **Run:** `bash "$tempFile"`
5. **Clean up** and exit

## Why Download-to-Temp Instead of Pipe

Piping (`irm ... | iex` / `curl ... | bash`) consumes stdin, which breaks interactive prompts like `Read-Host` and `read -p`. The individual setting installers (e.g., `status-line/win/install.ps1`) use interactive prompts for:

- Confirmation before applying settings changes
- Setup wizard for customization
- Press-enter-to-exit

Running as a file preserves full interactivity.

## Argument Passthrough

`/setting:install status-line` → passes `status-line` as `$SettingName`, skipping the menu.
`/setting:install` → no argument, shows the interactive menu.
