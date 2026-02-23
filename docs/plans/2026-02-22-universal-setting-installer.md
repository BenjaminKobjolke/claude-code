# Universal Setting Installer — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the two-tier settings install system with a universal, remote-first plugin manager that handles any plugin layout via a single installer script per platform.

**Architecture:** A single `install.ps1` (Windows) and `install.sh` (macOS) in `commands/setting/` replaces both the old launcher scripts and per-plugin installers. Plugins use a flat directory structure with platform filtering by file extension. Deep merge/un-merge handles `settings.json` with template substitution for platform-specific values.

**Tech Stack:** PowerShell 5.1+ (Windows), Bash 3.2+ (macOS), GitHub REST API, JSON manipulation (ConvertFrom-Json / python3)

---

### Task 1: Create Branch and Migrate status-line to Flat Structure

**Files:**
- Delete: `settings/status-line/win/` (entire directory)
- Delete: `settings/status-line/mac/` (entire directory)
- Create: `settings/status-line/status-line.ps1` (moved from `win/status-line.ps1`)
- Create: `settings/status-line/status-line.sh` (moved from `mac/status-line.sh`)
- Create: `settings/status-line/install.ps1` (refactored from `win/setup.ps1`)
- Create: `settings/status-line/install.sh` (refactored from `mac/setup.sh`)
- Create: `settings/status-line/uninstall.ps1` (refactored from `win/uninstall.ps1`)
- Create: `settings/status-line/uninstall.sh` (refactored from `mac/uninstall.sh`)
- Create: `settings/status-line/settings.json` (merged, with platform templates)
- Keep: `settings/status-line/README.md` (unchanged)

**Step 1: Move runtime scripts to flat structure**

```bash
cd /c/Programming_Files/Xida/claude-code
# Copy runtime scripts up from win/mac into flat structure
cp settings/status-line/win/status-line.ps1 settings/status-line/status-line.ps1
cp settings/status-line/mac/status-line.sh settings/status-line/status-line.sh
```

**Step 2: Create unified settings.json with platform templates**

The new `settings/status-line/settings.json` uses `{{PS1:...}}` and `{{SH:...}}` platform-conditional templates:

```json
{
    "statusLine": {
        "type": "command",
        "command": "{{PS1:powershell -NoProfile -File \"$USERPROFILE/.claude/settings/status-line/status-line.ps1\"}}{{SH:bash \"$HOME/.claude/settings/status-line/status-line.sh\"}}"
    }
}
```

**Step 3: Refactor setup.ps1 → install.ps1 (post-install hook)**

Copy `win/setup.ps1` to `settings/status-line/install.ps1` and modify:
- Remove the `$PSScriptRoot` path resolution logic — replace with hardcoded installed path `~/.claude/settings/status-line/status-line.ps1`
- The script is a post-install hook: it runs AFTER the universal installer has already downloaded files and merged settings.json
- Keep all customization wizard logic (layout, bar width, bar style, bar color prompts)
- Update the target path from `$env:USERPROFILE\.claude\settings\status-line\win\status-line.ps1` to `$env:USERPROFILE\.claude\settings\status-line\status-line.ps1`
- Remove `param([switch]$FromInstall)` — when piped via `irm | iex`, `param()` doesn't work. Instead check `$env:FROM_INSTALL`
- Always show current settings and ask if user wants to customize (the universal installer will set `$env:FROM_INSTALL='true'`)

**Step 4: Refactor setup.sh → install.sh (post-install hook)**

Copy `mac/setup.sh` to `settings/status-line/install.sh` and modify:
- Same changes as PS1 version but for Bash
- Update target path from `$HOME/.claude/settings/status-line/mac/status-line.sh` to `$HOME/.claude/settings/status-line/status-line.sh`
- Accept `--from-install` via positional arg (works with `bash -s -- --from-install`)
- Keep all customization wizard logic
- Ensure Bash 3.2 compatibility (no `mapfile`, no associative arrays)

**Step 5: Refactor uninstall.ps1 (plugin-specific cleanup only)**

Copy `win/uninstall.ps1` to `settings/status-line/uninstall.ps1` and modify:
- Remove ALL settings.json manipulation (the universal installer handles un-merge now)
- Remove ALL file deletion logic (the universal installer handles that too)
- Remove the re-launch-from-temp-copy hack (not needed when run remotely via `iex`)
- This script now only contains plugin-specific cleanup if any is needed
- For status-line, this can be essentially empty (just a message) since the universal installer handles everything
- Or it can contain any plugin-specific teardown logic that doesn't fit the universal pattern

**Step 6: Refactor uninstall.sh (plugin-specific cleanup only)**

Same as PS1 version but for Bash. Minimal — just plugin-specific cleanup.

**Step 7: Delete old win/mac directories**

```bash
cd /c/Programming_Files/Xida/claude-code
rm -rf settings/status-line/win
rm -rf settings/status-line/mac
```

**Step 8: Delete old launcher scripts**

```bash
rm settings/install.ps1
rm settings/install.sh
```

**Step 9: Commit**

```bash
git add -A settings/
git commit -m "REFACTOR (settings): migrate status-line to flat structure and delete old launchers"
```

---

### Task 2: Write Universal Installer — PowerShell (`commands/setting/install.ps1`)

**Files:**
- Create: `commands/setting/install.ps1`

**Step 1: Write the universal installer script**

Create `commands/setting/install.ps1` with the following structure. This is the core of the rework — a single script that handles discovery, install, update, and uninstall for any plugin.

```powershell
# install.ps1 - Universal setting plugin installer (Windows)
# Handles: discovery, install, update, uninstall for any plugin layout
# Pass plugin name via $env:SETTING_NAME, uninstall mode via $env:UNINSTALL
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

# ── Config ───────────────────────────────────────────────────────────
$REPO      = 'BenjaminKobjolke/claude-code'
$BRANCH    = 'main'
$DIR       = 'settings'
$REPO_API  = "https://api.github.com/repos/$REPO/contents/$DIR"
$REPO_RAW  = "https://raw.githubusercontent.com/$REPO/$BRANCH/$DIR"
$CLAUDE_DIR    = Join-Path $env:USERPROFILE ".claude"
$SETTINGS_FILE = Join-Path $CLAUDE_DIR "settings.json"
$SETTINGS_DIR  = Join-Path $CLAUDE_DIR "settings"
$BACKUP_FILE   = "$SETTINGS_FILE.bak"

# ── Platform extensions ──────────────────────────────────────────────
$THIS_PLATFORM_EXT  = @('.ps1', '.bat', '.cmd')
$OTHER_PLATFORM_EXT = @('.sh', '.zsh', '.command')
$SPECIAL_FILES      = @('settings.json', 'install.ps1', 'install.sh', 'uninstall.ps1', 'uninstall.sh', 'README.md')

$SettingName = if ($env:SETTING_NAME) { $env:SETTING_NAME.Trim() } else { '' }
$Uninstall   = $env:UNINSTALL -eq 'true'
```

The script sections (implement each as described in the design doc):

1. **`function Pause-Exit($code)`** — Read-Host "Press Enter to exit" + exit
2. **`function Invoke-GithubApi($url)`** — wraps `Invoke-RestMethod` with error handling for rate limiting
3. **`function Resolve-PluginName`** — discovery via GitHub API or use `$SettingName`, validate it exists
4. **`function Test-PluginInstalled($name)`** — checks `~/.claude/settings/<name>/` exists
5. **`function Get-FileClassification($files)`** — classifies each file from GitHub API response into: download, merge, run-hook, open-readme, skip
6. **`function Invoke-DeepMerge($target, $source)`** — recursive deep merge with array dedup

   PowerShell implementation of deep merge:
   ```powershell
   function Invoke-DeepMerge($target, $source) {
       # Convert PSCustomObject to ordered hashtable for mutation
       $result = [ordered]@{}
       $target.PSObject.Properties | ForEach-Object { $result[$_.Name] = $_.Value }

       foreach ($prop in $source.PSObject.Properties) {
           $key = $prop.Name
           $srcVal = $prop.Value

           if (-not $result.ContainsKey($key)) {
               $result[$key] = $srcVal
           }
           elseif ($result[$key] -is [PSCustomObject] -and $srcVal -is [PSCustomObject]) {
               $result[$key] = Invoke-DeepMerge $result[$key] $srcVal
           }
           elseif ($result[$key] -is [System.Collections.IEnumerable] -and $result[$key] -isnot [string] -and
                   $srcVal -is [System.Collections.IEnumerable] -and $srcVal -isnot [string]) {
               $existing = @($result[$key])
               foreach ($item in $srcVal) {
                   if ($existing -notcontains $item) { $existing += $item }
               }
               $result[$key] = $existing
           }
           else {
               $result[$key] = $srcVal
           }
       }
       return [PSCustomObject]$result
   }
   ```

7. **`function Invoke-DeepUnmerge($target, $source)`** — recursive deep un-merge

   ```powershell
   function Invoke-DeepUnmerge($target, $source) {
       $result = [ordered]@{}
       $target.PSObject.Properties | ForEach-Object { $result[$_.Name] = $_.Value }

       foreach ($prop in $source.PSObject.Properties) {
           $key = $prop.Name
           if (-not $result.ContainsKey($key)) { continue }

           $tgtVal = $result[$key]
           $srcVal = $prop.Value

           if ($tgtVal -is [PSCustomObject] -and $srcVal -is [PSCustomObject]) {
               $merged = Invoke-DeepUnmerge $tgtVal $srcVal
               if (($merged.PSObject.Properties | Measure-Object).Count -eq 0) {
                   $result.Remove($key)
               } else {
                   $result[$key] = $merged
               }
           }
           elseif ($tgtVal -is [System.Collections.IEnumerable] -and $tgtVal -isnot [string] -and
                   $srcVal -is [System.Collections.IEnumerable] -and $srcVal -isnot [string]) {
               $filtered = @($tgtVal | Where-Object { $srcVal -notcontains $_ })
               if ($filtered.Count -eq 0) {
                   $result.Remove($key)
               } else {
                   $result[$key] = $filtered
               }
           }
           elseif ($tgtVal -eq $srcVal) {
               $result.Remove($key)
           }
           # else: value differs from what plugin set → user modified → leave it
       }
       return [PSCustomObject]$result
   }
   ```

8. **`function Resolve-Templates($jsonText)`** — replace `{{PS1:...}}` with contents, remove `{{SH:...}}` on Windows

   ```powershell
   function Resolve-Templates($jsonText) {
       # On Windows: extract PS1 content, remove SH tags
       $resolved = $jsonText -replace '\{\{PS1:(.*?)\}\}', '$1'
       $resolved = $resolved -replace '\{\{SH:.*?\}\}', ''
       return $resolved
   }
   ```

9. **`function Show-DiffAndConfirm($oldText, $newText, $filePath)`** — colored diff preview, returns $true if confirmed

   Reuse the existing diff logic from current `install.ps1`:
   - Write old/new to temp files
   - `git diff --no-index --no-color -w -U2`
   - Colorize output (red for -, green for +, dim for context)
   - `Read-Host "Apply changes? [Y/n]"`
   - Return `$true` unless user types N/n

10. **`function Invoke-SettingsMerge($pluginName, $mode)`** — orchestrates merge or un-merge

    - Fetch plugin's `settings.json` from `$REPO_RAW/$pluginName/settings.json`
    - Resolve templates
    - Parse into object
    - Read local `~/.claude/settings.json` (or create `{}`)
    - Call `Invoke-DeepMerge` or `Invoke-DeepUnmerge` based on `$mode`
    - Serialize to JSON
    - Call `Show-DiffAndConfirm`
    - If confirmed: backup rotation → atomic write (.tmp → rename) → post-write validate

11. **`function Invoke-DownloadFiles($pluginName, $files)`** — downloads classified files

    - Create target directory
    - For each file classified as DOWNLOAD:
      - `Invoke-RestMethod -Uri $rawUrl -OutFile $destPath`
      - Report progress

12. **`function Invoke-RemoteHook($pluginName, $hookName)`** — fetch and execute hook script

    - Build URL: `$REPO_RAW/$pluginName/$hookName`
    - Try `irm $url`, if 404 → skip silently
    - If found: `$scriptContent | iex`

13. **`function Open-Readme($pluginName)`** — open README in browser

    - URL: `https://github.com/$REPO/blob/$BRANCH/$DIR/$pluginName/README.md`
    - `Start-Process $url`

14. **Main flow:**

    ```powershell
    # ── Resolve plugin name ──────────────────────────────
    $pluginName = Resolve-PluginName

    if ($Uninstall) {
        # ── Uninstall flow ───────────────────────────────
        Write-Host "Uninstalling '$pluginName'..."
        Invoke-RemoteHook $pluginName 'uninstall.ps1'
        Invoke-SettingsMerge $pluginName 'unmerge'
        $pluginDir = Join-Path $SETTINGS_DIR $pluginName
        if (Test-Path $pluginDir) {
            Remove-Item $pluginDir -Recurse -Force
            Write-Host "  Deleted $pluginDir"
        }
        Write-Host ""
        Write-Host "Plugin '$pluginName' uninstalled."
    }
    else {
        # ── Install/Update flow ──────────────────────────
        $isInstalled = Test-PluginInstalled $pluginName
        if ($isInstalled) {
            Write-Host ""
            Write-Host "Plugin '$pluginName' is already installed."
            $choice = Read-Host "  [U]pdate (default) / [R]emove"
            if ($choice -match '^[Rr]') {
                $Uninstall = $true
                # Re-run uninstall flow (same as above)
                # ... (or restructure as function calls)
            }
        }

        if (-not $Uninstall) {
            Write-Host "Installing '$pluginName'..."

            # Enumerate and classify files
            $apiUrl = "$REPO_API/$pluginName`?ref=$BRANCH"
            $files = Invoke-GithubApi $apiUrl
            $classified = Get-FileClassification $files

            # Download files
            Invoke-DownloadFiles $pluginName $classified.download

            # Merge settings.json
            if ($classified.hasSettings) {
                Invoke-SettingsMerge $pluginName 'merge'
            }

            # Run post-install hook
            Invoke-RemoteHook $pluginName 'install.ps1'

            # Open README
            if ($classified.hasReadme) {
                Open-Readme $pluginName
            }

            Write-Host ""
            Write-Host "Plugin '$pluginName' installed."
        }
    }

    Pause-Exit 0
    ```

**Step 2: Commit**

```bash
git add commands/setting/install.ps1
git commit -m "feat (settings): add universal installer for Windows"
```

---

### Task 3: Write Universal Installer — Bash (`commands/setting/install.sh`)

**Files:**
- Create: `commands/setting/install.sh`

**Step 1: Write the universal installer script**

Port the PowerShell installer to Bash, maintaining the same structure and behavior. Key differences:

- Use `curl -fsSL` instead of `Invoke-RestMethod`
- Use `python3` for JSON parsing (ConvertFrom-Json equivalent)
- Use `read -rp` instead of `Read-Host`
- Template resolution: `{{SH:...}}` → contents, `{{PS1:...}}` → removed (opposite of Windows)
- Deep merge/un-merge via inline `python3 -c` scripts
- All arrays via `while IFS= read -r` (no `mapfile`, Bash 3.2 compatible)
- Check `python3` and `curl` availability at start

The deep merge/un-merge in Bash will use `python3 -c` inline:

```bash
merge_settings_json() {
    local plugin_json="$1"
    local settings_file="$2"
    local mode="$3"  # "merge" or "unmerge"
    local tmp_file="$settings_file.tmp"

    python3 -c "
import json, sys

def deep_merge(target, source):
    for key, src_val in source.items():
        if key not in target:
            target[key] = src_val
        elif isinstance(target[key], dict) and isinstance(src_val, dict):
            deep_merge(target[key], src_val)
        elif isinstance(target[key], list) and isinstance(src_val, list):
            for item in src_val:
                if item not in target[key]:
                    target[key].append(item)
        else:
            target[key] = src_val

def deep_unmerge(target, source):
    keys_to_delete = []
    for key, src_val in source.items():
        if key not in target:
            continue
        tgt_val = target[key]
        if isinstance(tgt_val, dict) and isinstance(src_val, dict):
            deep_unmerge(tgt_val, src_val)
            if not tgt_val:
                keys_to_delete.append(key)
        elif isinstance(tgt_val, list) and isinstance(src_val, list):
            target[key] = [x for x in tgt_val if x not in src_val]
            if not target[key]:
                keys_to_delete.append(key)
        elif tgt_val == src_val:
            keys_to_delete.append(key)
    for key in keys_to_delete:
        del target[key]

plugin = json.loads(sys.argv[1])
mode = sys.argv[2]
settings_path = sys.argv[3]
tmp_path = sys.argv[4]

with open(settings_path, encoding='utf-8') as f:
    settings = json.load(f)

if mode == 'merge':
    deep_merge(settings, plugin)
else:
    deep_unmerge(settings, plugin)

with open(tmp_path, 'w', encoding='utf-8') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
" "$plugin_json" "$mode" "$settings_file" "$tmp_file"
}
```

Template resolution for macOS:
```bash
resolve_templates() {
    local text="$1"
    # On macOS: extract SH content, remove PS1 tags
    text=$(echo "$text" | sed 's/{{SH:\([^}]*\)}}/\1/g')
    text=$(echo "$text" | sed 's/{{PS1:[^}]*}}//g')
    echo "$text"
}
```

**Step 2: Commit**

```bash
git add commands/setting/install.sh
git commit -m "feat (settings): add universal installer for macOS"
```

---

### Task 4: Update Command Entry Points

**Files:**
- Modify: `commands/setting/install.md`
- Create: `commands/setting/uninstall.md`

**Step 1: Update install.md**

Replace the current content with:

```markdown
---
description: Install, update, or uninstall a setting plugin
---

Run the command matching the detected `Platform` environment variable. No text output before or after, only the command.

- win32:
    - if $ARGUMENTS is empty: `powershell -NoProfile -Command 'Start-Process powershell -ArgumentList "-NoProfile -Command try { irm https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/commands/setting/install.ps1 | iex } finally { pause }"'`
    - if $ARGUMENTS starts with "--uninstall" or "-u": `powershell -NoProfile -Command '$env:UNINSTALL=\"true\"; $env:SETTING_NAME='"'"'$ARGUMENTS'"'"' -replace \"^(--uninstall|-u)\s*\",\"\"; Start-Process powershell -ArgumentList \"-NoProfile -Command try { irm https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/commands/setting/install.ps1 | iex } finally { pause }\"'`
    - else: `powershell -NoProfile -Command '$env:SETTING_NAME='"'"'$ARGUMENTS'"'"'.Trim(); Start-Process powershell -ArgumentList \"-NoProfile -Command try { irm https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/commands/setting/install.ps1 | iex } finally { pause }\"'`
- darwin:
    - if $ARGUMENTS is empty: `osascript -e 'tell app "Terminal" to do script "curl -fsSL https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/commands/setting/install.sh | bash"'`
    - if $ARGUMENTS starts with "--uninstall" or "-u": `osascript -e 'tell app "Terminal" to do script "export UNINSTALL=true; curl -fsSL https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/commands/setting/install.sh | bash -s -- $ARGUMENTS"'`
    - else: `osascript -e 'tell app "Terminal" to do script "curl -fsSL https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/commands/setting/install.sh | bash -s -- $ARGUMENTS"'`
- Else: Say "Unsupported platform: {Platform}"
```

**Step 2: Create uninstall.md**

```markdown
---
description: Uninstall a setting plugin (shorthand for /setting:install --uninstall)
---

Run the command matching the detected `Platform` environment variable. No text output before or after, only the command.

- win32:
    - if $ARGUMENTS is empty: `powershell -NoProfile -Command '$env:UNINSTALL=\"true\"; Start-Process powershell -ArgumentList \"-NoProfile -Command try { irm https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/commands/setting/install.ps1 | iex } finally { pause }\"'`
    - else: `powershell -NoProfile -Command '$env:UNINSTALL=\"true\"; $env:SETTING_NAME='"'"'$ARGUMENTS'"'"'.Trim(); Start-Process powershell -ArgumentList \"-NoProfile -Command try { irm https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/commands/setting/install.ps1 | iex } finally { pause }\"'`
- darwin:
    - if $ARGUMENTS is empty: `osascript -e 'tell app "Terminal" to do script "export UNINSTALL=true; curl -fsSL https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/commands/setting/install.sh | bash"'`
    - else: `osascript -e 'tell app "Terminal" to do script "export UNINSTALL=true; curl -fsSL https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/commands/setting/install.sh | bash -s -- $ARGUMENTS"'`
- Else: Say "Unsupported platform: {Platform}"
```

**Step 3: Commit**

```bash
git add commands/setting/install.md commands/setting/uninstall.md
git commit -m "feat (settings): update install.md and add uninstall.md entry points"
```

---

### Task 5: Update CLAUDE.md Development Guide

**Files:**
- Modify: `commands/setting/CLAUDE.md`

**Step 1: Update CLAUDE.md**

Add the following sections to the existing dev guide:

- **Universal Installer Architecture** — explain the single-script approach, file classification, template system
- **Plugin Development Guide** — how to create a new plugin for this system
- **Template Syntax** — `{{PS1:...}}` and `{{SH:...}}` placeholders
- **Deep Merge/Un-Merge** — explain the algorithm and edge cases
- Update any existing sections that reference the old `win/` `mac/` structure

**Step 2: Commit**

```bash
git add commands/setting/CLAUDE.md
git commit -m "docs (settings): update development guide for universal installer"
```

---

### Task 6: Update status-line README.md

**Files:**
- Modify: `settings/status-line/README.md`

**Step 1: Update README**

Update the README to reflect:
- New flat directory structure (no `win/` `mac/` subfolders)
- New installation method via `/setting:install status-line`
- New uninstallation via `/setting:uninstall status-line`
- Updated file paths (e.g., `~/.claude/settings/status-line/status-line.ps1` instead of `~/.claude/settings/status-line/win/status-line.ps1`)
- Remove references to manual installation with `win/install.ps1` or `mac/install.sh`

**Step 2: Commit**

```bash
git add settings/status-line/README.md
git commit -m "docs (settings): update status-line README for flat structure"
```

---

### Task 7: End-to-End Verification

**Step 1: Verify repository structure is correct**

```bash
# Should show flat structure
ls settings/status-line/
# Expected: install.ps1  install.sh  README.md  settings.json  status-line.ps1  status-line.sh  uninstall.ps1  uninstall.sh

# Old directories should be gone
ls settings/status-line/win 2>/dev/null  # Should fail
ls settings/status-line/mac 2>/dev/null  # Should fail

# Old launcher scripts should be gone
ls settings/install.ps1 2>/dev/null  # Should fail
ls settings/install.sh 2>/dev/null   # Should fail

# New universal installer should exist
ls commands/setting/install.ps1  # Should succeed
ls commands/setting/install.sh   # Should succeed

# Uninstall command should exist
ls commands/setting/uninstall.md  # Should succeed
```

**Step 2: Verify settings.json template is valid JSON**

```bash
python3 -c "import json; json.load(open('settings/status-line/settings.json'))"
```

**Step 3: Dry-run the installer locally (Windows)**

Test the universal installer by running it directly (not via irm|iex) to verify:
- Discovery works (lists available plugins)
- File classification is correct
- Template resolution produces valid JSON
- Deep merge produces expected output

```powershell
# Set env vars to simulate
$env:SETTING_NAME = 'status-line'
# Run the installer
& powershell -NoProfile -File commands/setting/install.ps1
```

**Step 4: Commit any fixes**

```bash
git add -A
git commit -m "fix (settings): address issues found during verification"
```

---

### Task 8: Final Commit and Design Doc Update

**Step 1: Update design doc status**

In `docs/plans/2026-02-22-universal-setting-installer-design.md`, change:
```
**Status:** Approved
```
to:
```
**Status:** Implemented
```

**Step 2: Final commit**

```bash
git add -A
git commit -m "REFACTOR (settings): universal setting installer - complete rework"
```
