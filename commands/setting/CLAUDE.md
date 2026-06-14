# Setting Commands — Development Guide

## Interactive Scripts in Claude Code Commands

Claude's Bash tool does NOT have an interactive stdin. Any script that uses `Read-Host` (PowerShell) or `read -rp` (Bash) will fail silently or hang when Claude runs it directly.

### The Solution: Launch in a New Terminal Window

Use `Start-Process` (Windows) or `osascript` (macOS) to open the script in a **separate terminal window** where the user can interact with it directly.

**Windows (piped from remote):**
```bash
powershell -NoProfile -Command "Start-Process powershell -ArgumentList '-NoProfile -Command \"irm https://raw.githubusercontent.com/.../install.ps1 | iex\"'"
```

**macOS (piped from remote):**
```bash
osascript -e 'tell app "Terminal" to do script "curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash"'
```

Claude cannot see the output of these scripts. The `.md` command should tell the user to follow the prompts in the new terminal window.

### What Does NOT Work

- **Running interactive scripts directly via Bash tool.** `Read-Host` and `read -rp` get no input and either hang, return empty, or error.
- **Adding `-AutoAccept` flags to skip prompts.** Over-engineered. Loses the interactivity that makes the scripts useful. Don't do this.
- **Using `AskUserQuestion` to replace script prompts.** Over-engineered. Just open a new terminal.

## Piping Remote Scripts (`irm | iex` / `curl | bash`)

Piping works correctly when the script runs in its own terminal window. `Read-Host` reads from the console, NOT from stdin, so `irm | iex` does NOT break interactive prompts in PowerShell.

**Windows — correct:**
```powershell
irm $url | iex
```

**macOS — correct:**
```bash
curl -fsSL "$url" | bash
```

### Common Misconception

The assumption that "piping consumes stdin and breaks Read-Host" is **wrong** for PowerShell. `Read-Host` reads from the console directly, bypassing stdin entirely. `irm | iex` only pipes the script text into the PowerShell interpreter — it does not affect the console input stream.

Do NOT download scripts to temp files just to avoid piping. The download-to-temp approach introduces its own bugs:

- `$PSScriptRoot` resolves to the temp directory, causing sub-installers to think they are running locally and attempt to copy from the wrong parent directory (e.g., `C:\Users\...\AppData\Local\*` instead of the repo's `settings/` folder).
- Temp file cleanup adds complexity and failure modes.
- Isolated temp subdirectories are needed to work around the `$PSScriptRoot` issue, adding even more complexity.

Piping (`irm | iex`) avoids all of these problems because `$PSScriptRoot` is empty when piped, so the sub-installer correctly falls through to its remote download branch.

### `param()` Does NOT Work When Piped

PowerShell's `param()` block is ignored when a script is executed via `irm | iex`. To pass arguments, use environment variables instead:

```powershell
# In the script — read from env var instead of param()
$SettingName = if ($env:SETTING_NAME) { $env:SETTING_NAME } else { '' }
```

```powershell
# From the caller — set env var before piping
$env:SETTING_NAME='status-line'; irm $url | iex
```

For Bash, `bash -s -- arg1` works correctly with piped scripts.

## Platform Detection

Use the runtime environment variable to detect the platform:

- `win32` — Windows, use PowerShell (`.ps1`)
- `darwin` — macOS, use Bash (`.sh`)

Do NOT use non-Windows commands on Windows. Specifically:
- Do NOT use `curl` on Windows — use `Invoke-RestMethod` or `irm`
- Do NOT use `python3` on Windows — use PowerShell for JSON parsing
- Do NOT use `jq` unless confirmed available

## macOS Bash Compatibility

macOS ships with Bash 3.2 (due to GPL v3 licensing). Do NOT use Bash 4+ features:

- `mapfile` / `readarray` — use `while IFS= read -r` loop instead
- Associative arrays (`declare -A`) — not available in 3.2
- `&>>` redirect — use `>> file 2>&1` instead

## Config Variables

Keep repo, branch, and directory as variables at the top of scripts for easy customization:

```powershell
$REPO    = 'BenjaminKobjolke/claude-code'
$BRANCH  = 'main'
$DIR     = 'settings'
```

```bash
REPO='BenjaminKobjolke/claude-code'
BRANCH='main'
DIR='settings'
```

---

# Project Notes: QR Scavenger Hunt

> Unrelated to the setting-commands guide above — recorded here on request.

The QR scavenger hunt is **two repos**:

- **Frontend (React)**: `D:\GIT\qr-scavenger-hunt-app` — per-domain content folders under
  `public/<domain>/` (config.json, assets). Domain auto-resolves the folder.
- **Backend API (PHP Slim)**: `D:\wamp64\www\qr-scavenger-hunt-api` — serves questions via
  `POST /{project}/locations`. Questions live in `public/<project>.json`, registered in
  `src/Infrastructure/Persistence/Location/InMemoryLocationRepository.php`.

**Mapping**: frontend `apiEndpoint = https://<domain>/api/<project>` → the segment after
`/api/` is the backend **project key** → `public/<project>.json`. See
`D:\GIT\qr-scavenger-hunt-app\docs\CREATE_NEW_CONTEST.md` for the full new-contest guide.
