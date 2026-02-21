# install.ps1 - Install Claude Code custom status line
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Pause-Exit($code) {
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit $code
}

Write-Host "Installing Claude Code status line..."

# ── Paths ───────────────────────────────────────────────────────────
$scriptDir   = $PSScriptRoot                                          # .../win/
$sourceRoot  = Split-Path $scriptDir -Parent                          # .../status-line/
$claudeDir   = Join-Path $env:USERPROFILE ".claude"
$settingsDir = Join-Path $claudeDir "settings"
$targetRoot  = Join-Path $settingsDir "status-line"
$settingsFile = Join-Path $claudeDir "settings.json"
$backupFile  = "$settingsFile.bak"

# ── Ensure .claude directory exists ─────────────────────────────────
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }

# ── Copy files (skip if already inside .claude) ─────────────────────
if (-not $sourceRoot.TrimEnd('\','/').StartsWith($claudeDir.TrimEnd('\','/'), [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Host "  Copying files to $targetRoot"
    if (-not (Test-Path $targetRoot)) { New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null }
    Copy-Item -Path "$sourceRoot\*" -Destination $targetRoot -Recurse -Force
} else {
    Write-Host "  Files already in .claude directory, skipping copy."
}

# ── Resolve target setup.ps1 path (for wizard prompt later) ────────
$targetSetup = Join-Path $targetRoot "win\setup.ps1"

# ── Read statusLine block from bundled settings.json ──────────────
$snippetFile = Join-Path $targetRoot "win\settings.json"
if (-not (Test-Path $snippetFile)) { $snippetFile = Join-Path $scriptDir "settings.json" }
$snippetRaw = [System.IO.File]::ReadAllText($snippetFile, $utf8NoBom)
try { $snippetObj = $snippetRaw | ConvertFrom-Json } catch {
    Write-Host "  ERROR: settings.json snippet is not valid JSON. Aborting."
    Pause-Exit 1
}
# Extract the raw "statusLine": { ... } text from the snippet file (preserves formatting)
$snippetClean = $snippetRaw.Replace("`r`n", "`n").TrimEnd()
$startIdx = $snippetClean.IndexOf('"statusLine"')
$endIdx   = $snippetClean.LastIndexOf('}', $snippetClean.LastIndexOf('}') - 1)
$newValue = $snippetClean.Substring($startIdx, $endIdx - $startIdx + 1)
# Add 2-space indent to match top-level key placement
$newValue = "  " + ($newValue -replace "`n", "`n  ")

# ── Read or initialize settings.json ────────────────────────────────
if (Test-Path $settingsFile) {
    $raw = [System.IO.File]::ReadAllText($settingsFile, $utf8NoBom)
    try { $raw | ConvertFrom-Json | Out-Null } catch {
        Write-Host "  ERROR: settings.json is not valid JSON. Aborting."
        Pause-Exit 1
    }
} else {
    Write-Host "  Creating new settings.json"
    $raw = "{`n}"
}

# ── Normalize newValue line endings to match settings.json ────────
$crlf = "`r`n"; $lf = "`n"
if ($raw.Contains($crlf)) {
    $newValue = $newValue.Replace($crlf, $lf).Replace($lf, $crlf)
} else {
    $newValue = $newValue.Replace($crlf, $lf)
}

# ── Patch: replace or insert statusLine block ──────────────────────
# Regex matches the "statusLine": { ... } block with optional trailing comma
$pattern = '[ \t]*"statusLine"\s*:\s*\{[^{}]*\}\s*,?[ \t]*\r?\n?'
$m = [regex]::Match($raw, $pattern)

if ($m.Success) {
    # Determine trailing comma: needed if content follows that isn't '}'
    $after = $raw.Substring($m.Index + $m.Length).TrimStart("`r", "`n")
    $comma = if ($after.Length -gt 0 -and $after[0] -ne '}') { "," } else { "" }
    $eol = if ($raw.Contains("`r`n")) { "`r`n" } else { "`n" }
    $patched = $raw.Substring(0, $m.Index) + $newValue + $comma + $eol + $raw.Substring($m.Index + $m.Length)
} else {
    # Insert before closing brace
    $lastBrace = $raw.LastIndexOf('}')
    $before = $raw.Substring(0, $lastBrace).TrimEnd()
    if ($before.Length -gt 0 -and $before[-1] -ne ',' -and $before[-1] -ne '{') {
        $before += ","
    }
    $eol = if ($raw.Contains("`r`n")) { "`r`n" } else { "`n" }
    $patched = $before + $eol + $newValue + $eol + "}"
}

# ── Validate patched result ───────────────────────────────────────
$patchedObj = $null
try { $patchedObj = $patched | ConvertFrom-Json } catch {}

$origKeyCount = ($raw | ConvertFrom-Json).PSObject.Properties.Name.Count
$valid = $patchedObj -and
         $patchedObj.statusLine.type -eq $snippetObj.statusLine.type -and
         $patchedObj.statusLine.command -eq $snippetObj.statusLine.command -and
         $patchedObj.PSObject.Properties.Name.Count -ge $origKeyCount

if (-not $valid) {
    Write-Host "  Using fallback merge method."
    $fallback = $raw | ConvertFrom-Json
    $fHash = [ordered]@{}
    $fallback.PSObject.Properties | ForEach-Object {
        if ($_.Name -ne 'statusLine') { $fHash[$_.Name] = $_.Value }
    }
    $fHash['statusLine'] = $snippetObj.statusLine
    $patched = ([PSCustomObject]$fHash) | ConvertTo-Json -Depth 10
}

# ── Check if already up to date ───────────────────────────────────
$rawObj = $raw | ConvertFrom-Json
$alreadySet = $rawObj.statusLine.type -eq $snippetObj.statusLine.type -and
              $rawObj.statusLine.command -eq $snippetObj.statusLine.command
if ($alreadySet) {
    Write-Host "  $settingsFile already up to date."
} else {
    # ── Show diff and confirm ──────────────────────────────────────
    $esc = [char]27
    $red   = "$esc[31m"
    $green = "$esc[32m"
    $dim   = "$esc[90m"
    $reset = "$esc[0m"

    Write-Host ""
    Write-Host "  $dim$settingsFile$reset"
    Write-Host ""

    # Write both to temp files for diff
    $tmpOld = [System.IO.Path]::GetTempFileName()
    $tmpNew = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tmpOld, $raw, $utf8NoBom)
    [System.IO.File]::WriteAllText($tmpNew, $patched, $utf8NoBom)

    # Use git diff if available, otherwise fall back to showing new value
    $diffOutput = $null
    try {
        $diffOutput = & git diff --no-index --no-color -U2 $tmpOld $tmpNew 2>$null
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
        # Fallback: show what will be set
        Write-Host "  Setting statusLine to:"
        foreach ($line in ($newValue -split "`n")) {
            Write-Host "  $green+ $($line.TrimEnd("`r"))$reset"
        }
    }

    Remove-Item $tmpOld, $tmpNew -Force -ErrorAction SilentlyContinue

    Write-Host ""
    $answer = Read-Host "  Apply changes? [Y/n]"
    if ($answer -match '^[Nn]') {
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

    # ── Write atomically ─────────────────────────────────────────────
    $tmpFile = "$settingsFile.tmp"
    [System.IO.File]::WriteAllText($tmpFile, $patched, $utf8NoBom)
    Move-Item $tmpFile $settingsFile -Force
    Write-Host "  Done!"
}

# ── Read current config from status-line.ps1 ─────────────────────
$statusLineScript = Join-Path $targetRoot "win\status-line.ps1"
$cfgBarWidth = 15; $cfgColor = 32; $cfgFormat = '{0} {1} | {2} | {3} | {4} | {5}'
$cfgFilledChar = '[char]0x2588'
if (Test-Path $statusLineScript) {
    $slContent = [System.IO.File]::ReadAllText($statusLineScript, $utf8NoBom)
    if ($slContent -match 'CFG_BAR_WIDTH\s*=\s*(\d+)')    { $cfgBarWidth = $Matches[1] }
    if ($slContent -match 'CFG_FILLED_COLOR\s*=\s*(\d+)')  { $cfgColor = $Matches[1] }
    if ($slContent -match "CFG_FORMAT\s*=\s*'([^']+)'")    { $cfgFormat = $Matches[1] }
    if ($slContent -match 'CFG_FILLED_CHAR\s*=\s*(.+)')    { $cfgFilledChar = $Matches[1].Trim() }
}

$colorName = switch ($cfgColor) { 32 { "Green" } 36 { "Cyan" } 33 { "Yellow" } 37 { "White" } default { "ANSI $cfgColor" } }
$styleName = if ($cfgFilledChar -match '0x2588') { "Block" } elseif ($cfgFilledChar -match '0x2593') { "Shade" } elseif ($cfgFilledChar -match '"="') { "ASCII" } else { "Custom" }
$layoutName = switch ($cfgFormat) {
    '{0} {1} | {2} | {3} | {4} | {5}' { "Context Progress Bar, Context %, Tokens Used, Cost, Duration, Model" }
    '{0} {1} | {2} | {3} | {5}'       { "Context Progress Bar, Context %, Tokens Used, Cost, Model" }
    '{5} | {0} {1} | {2} | {3} | {4}' { "Model, Context Progress Bar, Context %, Tokens Used, Cost, Duration" }
    '{0} {1} | {3} | {5}'             { "Context Progress Bar, Context %, Cost, Model" }
    default                            { $cfgFormat }
}

# ── Optional: run setup wizard ─────────────────────────────────────
Write-Host ""
Write-Host "  Current settings:"
Write-Host "    Layout:    $layoutName"
Write-Host "    Bar width: $cfgBarWidth"
Write-Host "    Bar style: $styleName"
Write-Host "    Bar color: $colorName"
Write-Host ""
$runSetup = Read-Host "  Customize these settings? [y/N]"
if ($runSetup -match '^[Yy]') {
    & powershell -NoProfile -File $targetSetup -FromInstall
}

Write-Host ""
Write-Host "Status line installed. Open a new Claude Code session to see it."

Pause-Exit 0
