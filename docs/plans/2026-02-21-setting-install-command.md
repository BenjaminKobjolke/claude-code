# /setting:install Command Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a `/setting:install` command that discovers available settings from the remote GitHub repo and streams the install script directly to execution, with install scripts enhanced to download companion files from GitHub when not found locally.

**Architecture:** The command file (`commands/setting/install.md`) instructs Claude to query the GitHub API for available settings, auto-detect the platform, and run the appropriate install script via pipe. The install scripts (`install.ps1` / `install.sh`) gain a remote fallback: when the source directory doesn't exist (piped execution), they download companion files from raw GitHub URLs directly to the target directory.

**Tech Stack:** Markdown (command), PowerShell (Windows installer), Bash + Python 3 (macOS installer), GitHub API + raw.githubusercontent.com

---

### Task 1: Create the command file

**Files:**
- Create: `commands/setting/install.md`

**Step 1: Create directory**

```bash
mkdir -p commands/setting
```

**Step 2: Write the command file**

Create `commands/setting/install.md` with this exact content:

```markdown
---
description: Install a setting from the remote repository
---

# Install Setting

Install a setting from the remote GitHub repository. Auto-discovers available settings, detects your platform, and runs the installer.

## Instructions

1. **Discover available settings** by listing the remote `settings/` directory:

   First try `gh`:
   ```bash
   gh api repos/BenjaminKobjolke/claude-code/contents/settings?ref=main --jq '.[].name'
   ```

   If `gh` is not available, fall back to `curl`:
   ```bash
   curl -fsSL "https://api.github.com/repos/BenjaminKobjolke/claude-code/contents/settings?ref=main" | python3 -c "import sys,json;[print(x['name']) for x in json.load(sys.stdin) if x['type']=='dir']"
   ```

   On Windows without python3, use PowerShell:
   ```bash
   powershell -NoProfile -Command "(Invoke-RestMethod 'https://api.github.com/repos/BenjaminKobjolke/claude-code/contents/settings?ref=main') | Where-Object { $_.type -eq 'dir' } | ForEach-Object { $_.name }"
   ```

   These return the names of available settings (e.g., `status-line`).

2. **Select the setting to install:**

   - If `$ARGUMENTS` is provided and matches one of the discovered setting names, select it.
   - If `$ARGUMENTS` is provided but does NOT match, tell the user it was not found and list available settings.
   - If no argument is provided, ask the user to pick from the list of discovered settings.

3. **Detect platform** from the runtime environment:
   - `win32` -> Windows (PowerShell)
   - `darwin` -> macOS (Bash)

4. **Run the install script** by streaming it directly to the shell:

   **Windows:**
   ```bash
   powershell -NoProfile -Command "irm 'https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/<name>/win/install.ps1' | iex"
   ```

   **macOS:**
   ```bash
   curl -fsSL 'https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/<name>/mac/install.sh' | bash
   ```

   Replace `<name>` with the selected setting name.

5. **Report the result** to the user.
```

**Step 3: Verify the file**

Read back the file and confirm it matches.

**Step 4: Commit**

```bash
git add commands/setting/install.md
git commit -m "ADD (settings): /setting:install command for remote installation"
```

---

### Task 2: Add remote fallback to Windows install script

**Files:**
- Modify: `settings/status-line/win/install.ps1`

The current script has a "Copy files" section (lines 26-32) that copies from a local `$sourceRoot` to `$targetRoot`. When run via `irm | iex`, `$PSScriptRoot` is empty and the source directory won't exist. We need to detect this and download files from GitHub instead.

**Step 1: Add remote base URL constant**

After the `Write-Host "Installing Claude Code status line..."` line (line 11), add:

```powershell
# ── Remote fallback URL ──────────────────────────────────────────
$REMOTE_BASE = 'https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/status-line/win'
```

**Step 2: Replace the copy section with local-or-remote logic**

Replace the current copy block (lines 26-32):

```powershell
# ── Copy files (skip if already inside .claude) ─────────────────────
if (-not $sourceRoot.TrimEnd('\','/').StartsWith($claudeDir.TrimEnd('\','/'), [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Host "  Copying files to $targetRoot"
    if (-not (Test-Path $targetRoot)) { New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null }
    Copy-Item -Path "$sourceRoot\*" -Destination $targetRoot -Recurse -Force
} else {
    Write-Host "  Files already in .claude directory, skipping copy."
}
```

With this new version that checks if the source exists, and if not, downloads from remote:

```powershell
# ── Copy or download files ───────────────────────────────────────
$companionFiles = @('status-line.ps1', 'setup.ps1', 'uninstall.ps1', 'settings.json')
$winTarget = Join-Path $targetRoot "win"

if ($sourceRoot -and (Test-Path $sourceRoot)) {
    if (-not $sourceRoot.TrimEnd('\','/').StartsWith($claudeDir.TrimEnd('\','/'), [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Host "  Copying files to $targetRoot"
        if (-not (Test-Path $targetRoot)) { New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null }
        Copy-Item -Path "$sourceRoot\*" -Destination $targetRoot -Recurse -Force
    } else {
        Write-Host "  Files already in .claude directory, skipping copy."
    }
} else {
    Write-Host "  Downloading files from remote repository..."
    if (-not (Test-Path $winTarget)) { New-Item -ItemType Directory -Path $winTarget -Force | Out-Null }
    foreach ($file in $companionFiles) {
        $url = "$REMOTE_BASE/$file"
        $dest = Join-Path $winTarget $file
        try {
            Invoke-RestMethod -Uri $url -OutFile $dest
            Write-Host "    Downloaded $file"
        } catch {
            Write-Host "    WARNING: Failed to download $file from $url"
        }
    }
}
```

**Step 3: Fix the paths section for piped execution**

The current `$scriptDir = $PSScriptRoot` will be empty when piped. Replace lines 14-15:

```powershell
$scriptDir   = $PSScriptRoot                                          # .../win/
$sourceRoot  = Split-Path $scriptDir -Parent                          # .../status-line/
```

With:

```powershell
$scriptDir   = $PSScriptRoot                                          # .../win/ (empty when piped)
$sourceRoot  = if ($scriptDir) { Split-Path $scriptDir -Parent } else { '' }  # .../status-line/
```

**Step 4: Fix the snippet file resolution for piped execution**

The current snippet resolution (lines 38-39) assumes local files. After the copy/download block, the snippet file should always be read from the target directory. The current code already tries `$targetRoot` first and falls back to `$scriptDir`, which is correct. But we need to handle the case where neither exists yet by ensuring we always check `$winTarget` too.

Replace lines 38-39:

```powershell
$snippetFile = Join-Path $targetRoot "win\settings.json"
if (-not (Test-Path $snippetFile)) { $snippetFile = Join-Path $scriptDir "settings.json" }
```

With:

```powershell
$snippetFile = Join-Path $targetRoot "win\settings.json"
if (-not (Test-Path $snippetFile) -and $scriptDir) { $snippetFile = Join-Path $scriptDir "settings.json" }
if (-not (Test-Path $snippetFile)) {
    Write-Host "  ERROR: settings.json not found locally or from download. Aborting."
    Pause-Exit 1
}
```

**Step 5: Test locally**

Run the install script locally to verify it still works in local mode:

```bash
powershell -NoProfile -File "C:/Programming_Files/Xida/claude-code/settings/status-line/win/install.ps1"
```

Verify: Should behave identically to before (copy from local source).

**Step 6: Commit**

```bash
git add settings/status-line/win/install.ps1
git commit -m "IMPROVE (settings): add remote fallback to Windows install script"
```

---

### Task 3: Add remote fallback to macOS install script

**Files:**
- Modify: `settings/status-line/mac/install.sh`

Same logic as Task 2, adapted for Bash.

**Step 1: Add remote base URL constant**

After the `echo "Installing Claude Code status line..."` line (line 11), add:

```bash
# ── Remote fallback URL ──────────────────────────────────────────
REMOTE_BASE='https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/status-line/mac'
```

**Step 2: Fix paths for piped execution**

Replace lines 22-23:

```bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"       # .../mac/
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"        # .../status-line/
```

With:

```bash
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)" || SCRIPT_DIR=""  # .../mac/ (empty when piped)
SOURCE_ROOT=""
if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/.." ]; then
    SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"    # .../status-line/
fi
```

**Step 3: Replace copy section with local-or-remote logic**

Replace lines 39-48:

```bash
case "$SOURCE_ROOT" in
    "$CLAUDE_DIR"/*)
        echo "  Files already in .claude directory, skipping copy."
        ;;
    *)
        echo "  Copying files to $TARGET_ROOT"
        mkdir -p "$TARGET_ROOT"
        cp -R "$SOURCE_ROOT/"* "$TARGET_ROOT/"
        ;;
esac
```

With:

```bash
COMPANION_FILES="status-line.sh setup.sh uninstall.sh settings.json"
MAC_TARGET="$TARGET_ROOT/mac"

if [ -n "$SOURCE_ROOT" ] && [ -d "$SOURCE_ROOT" ]; then
    case "$SOURCE_ROOT" in
        "$CLAUDE_DIR"/*)
            echo "  Files already in .claude directory, skipping copy."
            ;;
        *)
            echo "  Copying files to $TARGET_ROOT"
            mkdir -p "$TARGET_ROOT"
            cp -R "$SOURCE_ROOT/"* "$TARGET_ROOT/"
            ;;
    esac
else
    echo "  Downloading files from remote repository..."
    mkdir -p "$MAC_TARGET"
    for file in $COMPANION_FILES; do
        url="$REMOTE_BASE/$file"
        dest="$MAC_TARGET/$file"
        if curl -fsSL "$url" -o "$dest" 2>/dev/null; then
            echo "    Downloaded $file"
        else
            echo "    WARNING: Failed to download $file from $url"
        fi
    done
fi
```

**Step 4: Fix chmod line for flexibility**

Replace line 51:

```bash
chmod +x "$TARGET_ROOT/mac/status-line.sh" "$TARGET_ROOT/mac/setup.sh" "$TARGET_ROOT/mac/install.sh" "$TARGET_ROOT/mac/uninstall.sh" 2>/dev/null || true
```

With (same but referencing `$MAC_TARGET` for clarity):

```bash
chmod +x "$MAC_TARGET/status-line.sh" "$MAC_TARGET/setup.sh" "$MAC_TARGET/install.sh" "$MAC_TARGET/uninstall.sh" 2>/dev/null || true
```

**Step 5: Fix snippet file resolution for piped execution**

Replace lines 57-58:

```bash
SNIPPET_FILE="$TARGET_ROOT/mac/settings.json"
[ -f "$SNIPPET_FILE" ] || SNIPPET_FILE="$SCRIPT_DIR/settings.json"
```

With:

```bash
SNIPPET_FILE="$TARGET_ROOT/mac/settings.json"
[ -f "$SNIPPET_FILE" ] || { [ -n "$SCRIPT_DIR" ] && SNIPPET_FILE="$SCRIPT_DIR/settings.json"; }
if [ ! -f "$SNIPPET_FILE" ]; then
    echo "  ERROR: settings.json not found locally or from download. Aborting."
    pause_exit 1
fi
```

**Step 6: Commit**

```bash
git add settings/status-line/mac/install.sh
git commit -m "IMPROVE (settings): add remote fallback to macOS install script"
```

---

### Task 4: Update README with remote installation instructions

**Files:**
- Modify: `settings/status-line/README.md`

**Step 1: Add remote installation section**

After the current "Automated (recommended)" section (after line 60), add a new section:

```markdown
### Remote (one-liner)

Install directly from GitHub without cloning the repository:

**Windows:**

```powershell
powershell -NoProfile -Command "irm 'https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/status-line/win/install.ps1' | iex"
```

**macOS:**

```bash
curl -fsSL 'https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/status-line/mac/install.sh' | bash
```

Or use the Claude Code command:

```
/setting:install status-line
```
```

**Step 2: Commit**

```bash
git add settings/status-line/README.md
git commit -m "DOCS (settings): add remote installation instructions to README"
```

---

### Task 5: End-to-end verification

**Step 1: Verify command file exists and is well-formed**

Read `commands/setting/install.md` and confirm it has the frontmatter and all 5 instruction steps.

**Step 2: Verify Windows install script**

Read `settings/status-line/win/install.ps1` and confirm:
- `$REMOTE_BASE` constant is present
- Local-or-remote copy logic is present
- `$sourceRoot` handles empty `$PSScriptRoot`
- Snippet file resolution has the error fallback

**Step 3: Verify macOS install script**

Read `settings/status-line/mac/install.sh` and confirm:
- `REMOTE_BASE` constant is present
- `SCRIPT_DIR` handles piped execution gracefully
- Local-or-remote copy logic is present
- Snippet file resolution has the error fallback

**Step 4: Test local Windows installation**

Run the install script locally to verify no regressions:

```bash
powershell -NoProfile -File "C:/Programming_Files/Xida/claude-code/settings/status-line/win/install.ps1"
```

Expected: Same behavior as before -- copies from local, merges settings, offers customization wizard.

**Step 5: Confirm all changes committed**

```bash
git log --oneline -5
git status
```

Expected: Clean working tree, 4 new commits on `feat/settings`.
