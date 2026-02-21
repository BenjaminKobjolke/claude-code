# JSON-Native Install/Uninstall Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace regex-based settings.json patching with pure JSON parse/modify/serialize in all four install/uninstall scripts.

**Architecture:** Each script reads settings.json as a JSON object, merges or removes the `statusLine` key, serializes back to 2-space indented JSON, validates by re-reading, and shows a `diff -w` preview before applying. No regex, no fallback paths.

**Tech Stack:** PowerShell `ConvertFrom-Json`/`ConvertTo-Json` (Windows), Python `json` module (macOS), `git diff -w` for diff preview.

---

### Task 0: Gate — Verify `diff -w` suppresses whitespace-only changes

**Why:** Before any code changes, confirm that `diff -w` and `git diff -w` only show visible character changes and suppress indentation/whitespace-only differences. If this fails, STOP — the entire approach depends on it.

**Step 1: Create test files**

Create two temp JSON files with identical content but different indentation:

```bash
# File A: 2-space indent
cat > /tmp/gate_a.json << 'EOF'
{
  "foo": "bar",
  "nested": {
    "key": "value"
  }
}
EOF

# File B: 4-space indent (same content)
cat > /tmp/gate_b.json << 'EOF'
{
    "foo": "bar",
    "nested": {
        "key": "value"
    }
}
EOF
```

**Step 2: Run `diff -w` — must show zero output**

Run: `diff -w /tmp/gate_a.json /tmp/gate_b.json; echo "exit: $?"`
Expected: no output, `exit: 0`

**Step 3: Run `git diff -w` — must show zero output**

Run: `git diff --no-index --no-color -w -U2 /tmp/gate_a.json /tmp/gate_b.json; echo "exit: $?"`
Expected: no output, `exit: 0`

**Step 4: Add a real content change, verify it shows up**

```bash
cat > /tmp/gate_c.json << 'EOF'
{
    "foo": "bar",
    "nested": {
        "key": "value"
    },
    "statusLine": {
        "type": "command",
        "command": "test"
    }
}
EOF
```

Run: `diff -w /tmp/gate_b.json /tmp/gate_c.json`
Expected: shows ONLY the `statusLine` addition (3 lines: `"statusLine"`, `"type"`, `"command"`), NOT indentation changes.

Run: `git diff --no-index --no-color -w -U2 /tmp/gate_b.json /tmp/gate_c.json`
Expected: same — only the statusLine content addition.

**Step 5: Clean up**

Run: `rm -f /tmp/gate_a.json /tmp/gate_b.json /tmp/gate_c.json`

**If any test fails:** STOP. Do not proceed with implementation. Report the failure.

**Step 6: Commit**

No code changes — this is a verification-only task. No commit needed.

---

### Task 1: Rewrite `win/install.ps1` — JSON-native merge

**Files:**
- Modify: `settings/status-line/win/install.ps1:37-114` (replace lines 37-114 with new JSON merge logic)

**Step 1: Replace the snippet extraction + regex patching + validation + fallback (lines 37-114)**

Replace lines 37-114 (from `# ── Read statusLine block from bundled settings.json` through the end of the `if (-not $valid)` block) with:

```powershell
# ── Read statusLine value from bundled settings.json ────────────────
$snippetFile = Join-Path $targetRoot "win\settings.json"
if (-not (Test-Path $snippetFile)) { $snippetFile = Join-Path $scriptDir "settings.json" }
$snippetRaw = [System.IO.File]::ReadAllText($snippetFile, $utf8NoBom)
try { $snippetObj = $snippetRaw | ConvertFrom-Json } catch {
    Write-Host "  ERROR: settings.json snippet is not valid JSON. Aborting."
    Pause-Exit 1
}

# ── Read or initialize settings.json ────────────────────────────────
if (Test-Path $settingsFile) {
    $raw = [System.IO.File]::ReadAllText($settingsFile, $utf8NoBom)
    try { $rawObj = $raw | ConvertFrom-Json } catch {
        Write-Host "  ERROR: settings.json is not valid JSON. Aborting."
        Pause-Exit 1
    }
} else {
    Write-Host "  Creating new settings.json"
    $raw = "{}"
    $rawObj = $raw | ConvertFrom-Json
}

# ── Check if already up to date ───────────────────────────────────
$alreadySet = $rawObj.statusLine.type -eq $snippetObj.statusLine.type -and
              $rawObj.statusLine.command -eq $snippetObj.statusLine.command
if ($alreadySet) {
    Write-Host "  $settingsFile already up to date."
} else {
    # ── Merge: set statusLine key ──────────────────────────────────
    $mergedHash = [ordered]@{}
    $rawObj.PSObject.Properties | ForEach-Object {
        if ($_.Name -ne 'statusLine') { $mergedHash[$_.Name] = $_.Value }
    }
    $mergedHash['statusLine'] = $snippetObj.statusLine
    $patched = ([PSCustomObject]$mergedHash) | ConvertTo-Json -Depth 10

    # ── Write to temp and validate ─────────────────────────────────
    $tmpFile = "$settingsFile.tmp"
    [System.IO.File]::WriteAllText($tmpFile, $patched, $utf8NoBom)

    $tmpRaw = [System.IO.File]::ReadAllText($tmpFile, $utf8NoBom)
    try { $tmpObj = $tmpRaw | ConvertFrom-Json } catch { $tmpObj = $null }
    if (-not $tmpObj -or
        $tmpObj.statusLine.type -ne $snippetObj.statusLine.type -or
        $tmpObj.statusLine.command -ne $snippetObj.statusLine.command) {
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
        Write-Host "  ERROR: validation failed after writing temp file. Aborting."
        Pause-Exit 1
    }
```

**Step 2: Replace the diff section (lines 122-189)**

Replace lines 122-189 (from `} else {` after `$alreadySet` through the `Write-Host "  Done!"` line) with:

```powershell
    # ── Show diff and confirm ──────────────────────────────────────
    $esc = [char]27
    $red   = "$esc[31m"
    $green = "$esc[32m"
    $dim   = "$esc[90m"
    $reset = "$esc[0m"

    Write-Host ""
    Write-Host "  $dim$settingsFile$reset"
    Write-Host ""

    # Write original to temp file for diff comparison
    $tmpOld = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tmpOld, $raw, $utf8NoBom)

    $diffOutput = $null
    try {
        $diffOutput = & git diff --no-index --no-color -w -U2 $tmpOld $tmpFile 2>$null
    } catch {}

    if ($diffOutput) {
        foreach ($line in ($diffOutput -split "`n")) {
            $l = $line.TrimEnd("`r")
            if ($l.StartsWith('---') -or $l.StartsWith('+++') -or $l.StartsWith('diff') -or $l.StartsWith('index')) { continue }
            if ($l.StartsWith('@@')) {
                Write-Host "  $dim$l$reset"
            } elseif ($l.StartsWith('-')) {
                Write-Host "  $red$l$reset"
            } elseif ($l.StartsWith('+')) {
                Write-Host "  $green$l$reset"
            } else {
                Write-Host "  $dim$l$reset"
            }
        }
    } else {
        Write-Host "  Setting statusLine in settings.json"
    }

    Remove-Item $tmpOld -Force -ErrorAction SilentlyContinue

    Write-Host ""
    $answer = Read-Host "  Apply changes? [Y/n]"
    if ($answer -match '^[Nn]') {
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
        Write-Host "  Skipped. No changes made to settings.json."
        Pause-Exit 0
    }

    # ── Backup (2-revision rotation) ────────────────────────────────
    if (Test-Path $settingsFile) {
        if (Test-Path "$backupFile.1") { Remove-Item "$backupFile.1" -Force }
        if (Test-Path $backupFile) { Rename-Item $backupFile "$backupFile.1" -Force }
        Copy-Item $settingsFile $backupFile -Force
        Write-Host "  Backing up settings.json -> settings.json.bak"
    }

    # ── Apply atomically ─────────────────────────────────────────────
    Move-Item $tmpFile $settingsFile -Force
    Write-Host "  Done!"
}
```

Note: The rest of the file (lines 192-231: config reading, setup wizard prompt) stays exactly the same.

**Step 3: Review the full file**

Read the entire `win/install.ps1` and verify:
- No regex patterns remain for settings.json patching
- No fallback merge logic remains
- No line ending normalization remains
- `diff -w` flag is present in the git diff command
- Post-write validation reads back the `.tmp` file
- Backup rotation and atomic write are preserved

**Step 4: Commit**

```bash
git add settings/status-line/win/install.ps1
git commit -m "IMPROVE (settings): JSON-native merge in win/install.ps1

Replace regex-based patching with pure JSON parse/modify/serialize.
Add diff -w for whitespace-agnostic preview. Post-write validation."
```

---

### Task 2: Rewrite `win/uninstall.ps1` — JSON-native remove

**Files:**
- Modify: `settings/status-line/win/uninstall.ps1:42-146` (replace lines 42-146)

**Step 1: Replace the regex removal + validation + fallback + diff + apply (lines 42-147)**

Replace lines 42-147 (from `# ── Remove statusLine key from settings.json` through the closing `}` of the `if ($hasKey)` block) with:

```powershell
# ── Remove statusLine key from settings.json ─────────────────────────
if ($hasKey) {
    $raw = [System.IO.File]::ReadAllText($settingsFile, $utf8NoBom)
    $rawObj = $raw | ConvertFrom-Json

    # ── Remove statusLine key ──────────────────────────────────────
    $mergedHash = [ordered]@{}
    $rawObj.PSObject.Properties | ForEach-Object {
        if ($_.Name -ne 'statusLine') { $mergedHash[$_.Name] = $_.Value }
    }
    $patched = ([PSCustomObject]$mergedHash) | ConvertTo-Json -Depth 10

    # ── Write to temp and validate ─────────────────────────────────
    $tmpFile = "$settingsFile.tmp"
    [System.IO.File]::WriteAllText($tmpFile, $patched, $utf8NoBom)

    $tmpRaw = [System.IO.File]::ReadAllText($tmpFile, $utf8NoBom)
    try { $tmpObj = $tmpRaw | ConvertFrom-Json } catch { $tmpObj = $null }
    $origKeyCount = $rawObj.PSObject.Properties.Name.Count
    if (-not $tmpObj -or
        $null -ne $tmpObj.statusLine -or
        $tmpObj.PSObject.Properties.Name.Count -ne ($origKeyCount - 1)) {
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
        Write-Host "  ERROR: validation failed after writing temp file. Aborting."
        Pause-Exit 1
    }

    # ── Show diff ────────────────────────────────────────────────────
    $esc = [char]27
    $red   = "$esc[31m"
    $green = "$esc[32m"
    $dim   = "$esc[90m"
    $reset = "$esc[0m"

    Write-Host ""
    Write-Host "  $dim$settingsFile$reset"
    Write-Host ""

    $tmpOld = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tmpOld, $raw, $utf8NoBom)

    $diffOutput = $null
    try {
        $diffOutput = & git diff --no-index --no-color -w -U2 $tmpOld $tmpFile 2>$null
    } catch {}

    if ($diffOutput) {
        foreach ($line in ($diffOutput -split "`n")) {
            $l = $line.TrimEnd("`r")
            if ($l.StartsWith('---') -or $l.StartsWith('+++') -or $l.StartsWith('diff') -or $l.StartsWith('index')) { continue }
            if ($l.StartsWith('@@')) {
                Write-Host "  $dim$l$reset"
            } elseif ($l.StartsWith('-')) {
                Write-Host "  $red$l$reset"
            } elseif ($l.StartsWith('+')) {
                Write-Host "  $green$l$reset"
            } else {
                Write-Host "  $dim$l$reset"
            }
        }
    } else {
        Write-Host "  Removing statusLine key from settings.json"
    }

    Remove-Item $tmpOld -Force -ErrorAction SilentlyContinue

    Write-Host ""
    $answer = Read-Host "  Remove statusLine from settings.json? [Y/n]"
    if ($answer -match '^[Nn]') {
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
        Write-Host "  Skipped. statusLine key was not removed."
    } else {
        # ── Backup (2-revision rotation) ─────────────────────────────
        if (Test-Path $settingsFile) {
            if (Test-Path "$backupFile.1") { Remove-Item "$backupFile.1" -Force }
            if (Test-Path $backupFile) { Rename-Item $backupFile "$backupFile.1" -Force }
            Copy-Item $settingsFile $backupFile -Force
            Write-Host "  Backing up settings.json -> settings.json.bak"
        }

        # ── Apply atomically ─────────────────────────────────────────
        Move-Item $tmpFile $settingsFile -Force
        Write-Host "  Removed statusLine from settings.json."
    }
}
```

Note: The rest of the file (lines 149-170: directory removal, final message) stays exactly the same.

**Step 2: Review the full file**

Read the entire `win/uninstall.ps1` and verify:
- No regex patterns remain
- No fallback merge logic remains
- `diff -w` flag is present
- Post-write validation reads back the `.tmp` file
- Cleanup of `.tmp` on skip/error

**Step 3: Commit**

```bash
git add settings/status-line/win/uninstall.ps1
git commit -m "IMPROVE (settings): JSON-native remove in win/uninstall.ps1

Replace regex-based patching with pure JSON parse/modify/serialize.
Add diff -w for whitespace-agnostic preview. Post-write validation."
```

---

### Task 3: Rewrite `mac/install.sh` — JSON-native merge

**Files:**
- Modify: `settings/status-line/mac/install.sh:56-200` (replace lines 56-200)

**Step 1: Replace snippet extraction + regex patching + validation + already-set check + diff + apply (lines 56-200)**

Replace lines 56-200 (from `# ── Read statusLine block from bundled settings.json` through `echo "  Done!"` / `fi`) with:

```bash
# ── Read statusLine value from bundled settings.json ────────────────
SNIPPET_FILE="$TARGET_ROOT/mac/settings.json"
[ -f "$SNIPPET_FILE" ] || SNIPPET_FILE="$SCRIPT_DIR/settings.json"
if ! python3 -c "import json,sys; json.load(open(sys.argv[1],encoding='utf-8'))" "$SNIPPET_FILE" 2>/dev/null; then
    echo "  ERROR: settings.json snippet is not valid JSON. Aborting."
    pause_exit 1
fi

# ── Read or initialize settings.json ────────────────────────────────
if [ -f "$SETTINGS_FILE" ]; then
    if ! python3 -c "import json,sys; json.load(open(sys.argv[1],encoding='utf-8'))" "$SETTINGS_FILE" 2>/dev/null; then
        echo "  ERROR: settings.json is not valid JSON. Aborting."
        pause_exit 1
    fi
else
    echo "  Creating new settings.json"
    printf '{}\n' > "$SETTINGS_FILE"
fi

# ── Check if already up to date ───────────────────────────────────
ALREADY_SET=$(python3 -c "
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    data = json.load(f)
with open(sys.argv[2], encoding='utf-8') as f:
    snippet = json.load(f)
sl = data.get('statusLine', {})
expected = snippet.get('statusLine', {})
print('yes' if sl == expected else 'no')
" "$SETTINGS_FILE" "$SNIPPET_FILE" 2>/dev/null || echo "no")

if [ "$ALREADY_SET" = "yes" ]; then
    echo "  $SETTINGS_FILE already up to date."
else
    # ── Merge: set statusLine key ──────────────────────────────────
    python3 -c "
import json, sys

settings_path = sys.argv[1]
tmp_path = sys.argv[2]
snippet_path = sys.argv[3]

with open(settings_path, encoding='utf-8') as f:
    data = json.load(f)
with open(snippet_path, encoding='utf-8') as f:
    snippet = json.load(f)

data['statusLine'] = snippet['statusLine']
patched = json.dumps(data, indent=2) + '\n'

with open(tmp_path, 'w', encoding='utf-8') as f:
    f.write(patched)
" "$SETTINGS_FILE" "$TMP_FILE" "$SNIPPET_FILE"

    # ── Validate temp file ─────────────────────────────────────────
    VALID=$(python3 -c "
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    data = json.load(f)
with open(sys.argv[2], encoding='utf-8') as f:
    snippet = json.load(f)
sl = data.get('statusLine', {})
expected = snippet.get('statusLine', {})
print('yes' if sl == expected else 'no')
" "$TMP_FILE" "$SNIPPET_FILE" 2>/dev/null || echo "no")

    if [ "$VALID" != "yes" ]; then
        echo "  ERROR: validation failed after writing temp file. Aborting."
        pause_exit 1
    fi

    # ── Show diff and confirm ──────────────────────────────────────
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    DIM=$'\033[90m'
    RESET=$'\033[0m'

    echo ""
    echo "  ${DIM}${SETTINGS_FILE}${RESET}"
    echo ""

    if command -v git &>/dev/null; then
        git diff --no-index --no-color -w -U2 "$SETTINGS_FILE" "$TMP_FILE" 2>/dev/null | while IFS= read -r line; do
            case "$line" in
                ---*|+++*|diff*|index*) continue ;;
                @@*)  printf '  %s%s%s\n' "$DIM"   "$line" "$RESET" ;;
                -*)   printf '  %s%s%s\n' "$RED"   "$line" "$RESET" ;;
                +*)   printf '  %s%s%s\n' "$GREEN" "$line" "$RESET" ;;
                *)    printf '  %s%s%s\n' "$DIM"   "$line" "$RESET" ;;
            esac
        done
    else
        diff -w --old-line-format="  ${RED}-%l${RESET}
" --new-line-format="  ${GREEN}+%l${RESET}
" --unchanged-line-format="" "$SETTINGS_FILE" "$TMP_FILE" || true
    fi

    echo ""
    read -rp "  Apply changes? [Y/n]: " answer
    if [[ "$answer" =~ ^[Nn] ]]; then
        echo "  Skipped. No changes made to settings.json."
        pause_exit 0
    fi

    # ── Backup (2-revision rotation) ────────────────────────────────
    rm -f "$BACKUP_FILE.1"
    [ -f "$BACKUP_FILE" ] && mv "$BACKUP_FILE" "$BACKUP_FILE.1"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo "  Backing up settings.json -> settings.json.bak"

    # ── Apply ───────────────────────────────────────────────────────
    mv "$TMP_FILE" "$SETTINGS_FILE"
    echo "  Done!"
fi
```

Note: The rest of the file (lines 202-255: config reading, setup wizard) stays exactly the same.

**Step 2: Review the full file**

Read the entire `mac/install.sh` and verify:
- No regex patterns remain (no `import re`, no `re.search`)
- No fallback merge logic remains
- `diff -w` flag is present in both `git diff` and fallback `diff`
- Post-write validation via python3 re-read
- The `$NEW_VALUE` variable and its extraction are completely gone

**Step 3: Commit**

```bash
git add settings/status-line/mac/install.sh
git commit -m "IMPROVE (settings): JSON-native merge in mac/install.sh

Replace regex-based patching with pure JSON parse/modify/serialize.
Add diff -w for whitespace-agnostic preview. Post-write validation."
```

---

### Task 4: Rewrite `mac/uninstall.sh` — JSON-native remove

**Files:**
- Modify: `settings/status-line/mac/uninstall.sh:60-149` (replace lines 60-149)

**Step 1: Replace regex removal + validation + diff + apply (lines 60-149)**

Replace lines 60-149 (from `# ── Remove statusLine key from settings.json` through the closing `fi` of the `if [ "$HAS_KEY" = "yes" ]` block) with:

```bash
# ── Remove statusLine key from settings.json ─────────────────────────
if [ "$HAS_KEY" = "yes" ]; then
    # ── Remove statusLine key via JSON ─────────────────────────────
    python3 -c "
import json, sys

settings_path = sys.argv[1]
tmp_path = sys.argv[2]

with open(settings_path, encoding='utf-8') as f:
    data = json.load(f)

orig_count = len(data)
data.pop('statusLine', None)
patched = json.dumps(data, indent=2) + '\n'

with open(tmp_path, 'w', encoding='utf-8') as f:
    f.write(patched)
" "$SETTINGS_FILE" "$TMP_FILE"

    # ── Validate temp file ─────────────────────────────────────────
    VALID=$(python3 -c "
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    data = json.load(f)
with open(sys.argv[2], encoding='utf-8') as f:
    orig = json.load(f)
print('yes' if 'statusLine' not in data and len(data) == len(orig) - 1 else 'no')
" "$TMP_FILE" "$SETTINGS_FILE" 2>/dev/null || echo "no")

    if [ "$VALID" != "yes" ]; then
        echo "  ERROR: validation failed after writing temp file. Aborting."
        pause_exit 1
    fi

    # ── Show diff ────────────────────────────────────────────────────
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    DIM=$'\033[90m'
    RESET=$'\033[0m'

    echo "  ${DIM}${SETTINGS_FILE}${RESET}"
    echo ""

    if command -v git &>/dev/null; then
        git diff --no-index --no-color -w -U2 "$SETTINGS_FILE" "$TMP_FILE" 2>/dev/null | while IFS= read -r line; do
            case "$line" in
                ---*|+++*|diff*|index*) continue ;;
                @@*)  printf '  %s%s%s\n' "$DIM"   "$line" "$RESET" ;;
                -*)   printf '  %s%s%s\n' "$RED"   "$line" "$RESET" ;;
                +*)   printf '  %s%s%s\n' "$GREEN" "$line" "$RESET" ;;
                *)    printf '  %s%s%s\n' "$DIM"   "$line" "$RESET" ;;
            esac
        done
    else
        diff -w --old-line-format="  ${RED}-%l${RESET}
" --new-line-format="  ${GREEN}+%l${RESET}
" --unchanged-line-format="" "$SETTINGS_FILE" "$TMP_FILE" || true
    fi

    echo ""
    read -rp "  Remove statusLine from settings.json? [Y/n]: " answer
    if [[ "$answer" =~ ^[Nn] ]]; then
        echo "  Skipped. statusLine key was not removed."
    else
        # ── Backup (2-revision rotation) ─────────────────────────────
        rm -f "$BACKUP_FILE.1"
        [ -f "$BACKUP_FILE" ] && mv "$BACKUP_FILE" "$BACKUP_FILE.1"
        cp "$SETTINGS_FILE" "$BACKUP_FILE"
        echo "  Backing up settings.json -> settings.json.bak"

        # ── Apply atomically ─────────────────────────────────────────
        mv "$TMP_FILE" "$SETTINGS_FILE"
        echo "  Removed statusLine from settings.json."
    fi
fi
```

Note: The rest of the file (lines 151-171: directory removal, final message) stays exactly the same.

**Step 2: Review the full file**

Read the entire `mac/uninstall.sh` and verify:
- No regex patterns remain (no `import re`, no `re.search`)
- No fallback merge logic remains
- `diff -w` flag is present in both `git diff` and fallback `diff`
- Post-write validation via python3 re-read

**Step 3: Commit**

```bash
git add settings/status-line/mac/uninstall.sh
git commit -m "IMPROVE (settings): JSON-native remove in mac/uninstall.sh

Replace regex-based patching with pure JSON parse/modify/serialize.
Add diff -w for whitespace-agnostic preview. Post-write validation."
```

---

### Task 5: Final review — verify no regex remains across all four files

**Step 1: Search for leftover regex patterns**

Run: `grep -n "regex\|re\.search\|re\.match\|\[regex\]\|pattern.*statusLine\|fallback merge" settings/status-line/win/install.ps1 settings/status-line/win/uninstall.ps1 settings/status-line/mac/install.sh settings/status-line/mac/uninstall.sh`

Expected: zero matches

**Step 2: Search for leftover imports**

Run: `grep -n "import re" settings/status-line/mac/install.sh settings/status-line/mac/uninstall.sh`

Expected: zero matches

**Step 3: Verify diff -w flag present in all four scripts**

Run: `grep -n "\-w" settings/status-line/win/install.ps1 settings/status-line/win/uninstall.ps1 settings/status-line/mac/install.sh settings/status-line/mac/uninstall.sh`

Expected: 4 matches (one per file), all in `git diff` commands

**Step 4: Commit (if any cleanup was needed)**

Only if Step 1-3 revealed issues that needed fixing. Otherwise, no commit.
