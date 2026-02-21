# Interactive Setting Installer — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the prompt-driven `install.md` with self-contained platform scripts that run interactively in the user's terminal.

**Architecture:** A minimal `install.md` dispatches to platform-specific launcher scripts (`install.ps1` / `install.sh`) that live alongside it in `commands/setting/`. Each launcher discovers available settings from GitHub API, presents an interactive menu, downloads the chosen setting's installer to a temp file, and runs it as a file to preserve interactivity.

**Tech Stack:** PowerShell (Windows), Bash + python3 (macOS), GitHub REST API

---

### Task 1: Create install.ps1 — Windows launcher

**Files:**
- Create: `commands/setting/install.ps1`

**Step 1: Write the PowerShell launcher script**

Create `commands/setting/install.ps1` with this exact content:

```powershell
# install.ps1 - Interactive setting installer launcher (Windows)
# Discovers available settings from remote repo, presents selection menu,
# downloads and runs the chosen setting's installer interactively.
param([string]$SettingName)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$REPO_API = 'https://api.github.com/repos/BenjaminKobjolke/claude-code/contents/settings?ref=main'
$REPO_RAW = 'https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings'

# ── Discover available settings ──────────────────────────────────
Write-Host "Discovering available settings..."
try {
    $entries = Invoke-RestMethod -Uri $REPO_API
} catch {
    Write-Host "ERROR: Failed to fetch settings list from GitHub API."
    Write-Host "  $_"
    exit 1
}

$settings = @($entries | Where-Object { $_.type -eq 'dir' } | ForEach-Object { $_.name })
if ($settings.Count -eq 0) {
    Write-Host "No settings found in the remote repository."
    exit 1
}

# ── Select setting ───────────────────────────────────────────────
$selected = $null

if ($SettingName) {
    if ($settings -contains $SettingName) {
        $selected = $SettingName
    } else {
        Write-Host "ERROR: Setting '$SettingName' not found."
        Write-Host ""
        Write-Host "Available settings:"
        foreach ($s in $settings) { Write-Host "  - $s" }
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "Available settings:"
    for ($i = 0; $i -lt $settings.Count; $i++) {
        Write-Host "  [$($i + 1)] $($settings[$i])"
    }
    Write-Host ""
    $choice = Read-Host "Select a setting to install (1-$($settings.Count))"
    $idx = 0
    if (-not [int]::TryParse($choice, [ref]$idx) -or $idx -lt 1 -or $idx -gt $settings.Count) {
        Write-Host "Invalid selection."
        exit 1
    }
    $selected = $settings[$idx - 1]
}

Write-Host ""
Write-Host "Installing '$selected'..."

# ── Download installer to temp ───────────────────────────────────
$url = "$REPO_RAW/$selected/win/install.ps1"
$tempFile = Join-Path $env:TEMP "claude-setting-install-$selected.ps1"

try {
    Invoke-RestMethod -Uri $url -OutFile $tempFile
} catch {
    Write-Host "ERROR: Failed to download installer from:"
    Write-Host "  $url"
    Write-Host "  $_"
    exit 1
}

# ── Run interactively ────────────────────────────────────────────
try {
    & powershell -NoProfile -File $tempFile
    $exitCode = $LASTEXITCODE
} finally {
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
}

exit $exitCode
```

**Step 2: Verify the script parses without errors**

Run: `powershell -NoProfile -Command "Get-Content 'C:\Programming_Files\Xida\claude-code\commands\setting\install.ps1' | Out-Null; Write-Host 'Parse OK'"`
Expected: `Parse OK`

**Step 3: Commit**

```bash
git add commands/setting/install.ps1
git commit -m "FEATURE (settings): add Windows interactive setting installer launcher"
```

---

### Task 2: Create install.sh — macOS launcher

**Files:**
- Create: `commands/setting/install.sh`

**Step 1: Write the Bash launcher script**

Create `commands/setting/install.sh` with this exact content:

```bash
#!/bin/bash
# install.sh - Interactive setting installer launcher (macOS)
# Discovers available settings from remote repo, presents selection menu,
# downloads and runs the chosen setting's installer interactively.
set -euo pipefail

SETTING_NAME="${1:-}"
REPO_API='https://api.github.com/repos/BenjaminKobjolke/claude-code/contents/settings?ref=main'
REPO_RAW='https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings'

# ── Check dependencies ───────────────────────────────────────────
if ! command -v curl &>/dev/null; then
    echo "ERROR: curl is required but not installed."
    exit 1
fi
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 is required but not installed."
    echo "  Install via: xcode-select --install  or  brew install python3"
    exit 1
fi

# ── Discover available settings ──────────────────────────────────
echo "Discovering available settings..."
API_RESPONSE=$(curl -fsSL "$REPO_API") || {
    echo "ERROR: Failed to fetch settings list from GitHub API."
    exit 1
}

SETTINGS=$(echo "$API_RESPONSE" | python3 -c "
import sys, json
entries = json.load(sys.stdin)
dirs = [e['name'] for e in entries if e['type'] == 'dir']
for d in dirs:
    print(d)
") || {
    echo "ERROR: Failed to parse API response."
    exit 1
}

if [ -z "$SETTINGS" ]; then
    echo "No settings found in the remote repository."
    exit 1
fi

# Convert to array
mapfile -t SETTINGS_ARR <<< "$SETTINGS"

# ── Select setting ───────────────────────────────────────────────
SELECTED=""

if [ -n "$SETTING_NAME" ]; then
    FOUND=false
    for s in "${SETTINGS_ARR[@]}"; do
        if [ "$s" = "$SETTING_NAME" ]; then
            FOUND=true
            break
        fi
    done
    if $FOUND; then
        SELECTED="$SETTING_NAME"
    else
        echo "ERROR: Setting '$SETTING_NAME' not found."
        echo ""
        echo "Available settings:"
        for s in "${SETTINGS_ARR[@]}"; do
            echo "  - $s"
        done
        exit 1
    fi
else
    echo ""
    echo "Available settings:"
    for i in "${!SETTINGS_ARR[@]}"; do
        echo "  [$((i + 1))] ${SETTINGS_ARR[$i]}"
    done
    echo ""
    read -rp "Select a setting to install (1-${#SETTINGS_ARR[@]}): " CHOICE
    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#SETTINGS_ARR[@]}" ]; then
        echo "Invalid selection."
        exit 1
    fi
    SELECTED="${SETTINGS_ARR[$((CHOICE - 1))]}"
fi

echo ""
echo "Installing '$SELECTED'..."

# ── Download installer to temp ───────────────────────────────────
URL="$REPO_RAW/$SELECTED/mac/install.sh"
TEMP_FILE="/tmp/claude-setting-install-$SELECTED.sh"

cleanup() { rm -f "$TEMP_FILE"; }
trap cleanup EXIT

curl -fsSL "$URL" -o "$TEMP_FILE" || {
    echo "ERROR: Failed to download installer from:"
    echo "  $URL"
    exit 1
}

chmod +x "$TEMP_FILE"

# ── Run interactively ────────────────────────────────────────────
bash "$TEMP_FILE"
```

**Step 2: Commit**

```bash
git add commands/setting/install.sh
git commit -m "FEATURE (settings): add macOS interactive setting installer launcher"
```

---

### Task 3: Rewrite install.md — minimal dispatcher

**Files:**
- Modify: `commands/setting/install.md`

**Step 1: Replace install.md contents**

Replace the entire file with:

```markdown
---
description: Install a setting from the remote repository
---

# Install Setting

Run the platform-specific interactive installer script located next to this file.

## Instructions

1. **Detect platform** from the runtime environment and run the correct script:

   **Windows (`win32`):**
   ```bash
   powershell -NoProfile -File "<path-to-this-directory>/install.ps1" $ARGUMENTS
   ```

   **macOS (`darwin`):**
   ```bash
   bash "<path-to-this-directory>/install.sh" $ARGUMENTS
   ```

   Replace `<path-to-this-directory>` with the absolute path to the directory containing this file (same directory as `install.md`).

2. **Let the user interact** with the script. Do NOT run it in the background. The script handles all discovery, selection, downloading, and installation interactively.

3. **Unsupported platforms:** If the platform is neither `win32` nor `darwin`, tell the user that remote installation is not yet supported for their platform.

4. **Report the result** based on the script's exit code. Exit code 0 means success; anything else means failure.
```

**Step 2: Commit**

```bash
git add commands/setting/install.md
git commit -m "IMPROVE (settings): simplify install.md to dispatch to interactive platform scripts"
```

---

### Task 4: Manual test on Windows

**Step 1: Run the launcher without arguments to test the interactive menu**

Run: `powershell -NoProfile -File "C:\Programming_Files\Xida\claude-code\commands\setting\install.ps1"`

Expected:
- Shows "Discovering available settings..."
- Lists available settings with numbered menu (e.g., `[1] status-line`)
- Waits for user input via `Read-Host`
- After selection, downloads the setting's installer
- Runs the installer interactively (user sees all prompts from the setting installer)

**Step 2: Run the launcher with an argument**

Run: `powershell -NoProfile -File "C:\Programming_Files\Xida\claude-code\commands\setting\install.ps1" status-line`

Expected:
- Shows "Discovering available settings..."
- Auto-selects `status-line` (skips menu)
- Downloads and runs installer interactively

**Step 3: Run with invalid argument**

Run: `powershell -NoProfile -File "C:\Programming_Files\Xida\claude-code\commands\setting\install.ps1" nonexistent`

Expected:
- Shows "ERROR: Setting 'nonexistent' not found."
- Lists available settings
- Exits with code 1

**Step 4: Commit all changes together if any fixes were needed**

```bash
git add -A
git commit -m "FIX (settings): address issues found during manual testing"
```
