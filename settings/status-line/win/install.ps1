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

# ── Read current config from status-line.ps1 ─────────────────────
$statusLineScript = Join-Path $targetRoot "win\status-line.ps1"
$cfgBarWidth = 10; $cfgColor = 'dynamic'; $cfgFormat = '{0} {1} | {2} | {3} | {4} | {5}'
$cfgFilledChar = '[char]0x2588'
if (Test-Path $statusLineScript) {
    $slContent = [System.IO.File]::ReadAllText($statusLineScript, $utf8NoBom)
    if ($slContent -match 'CFG_BAR_WIDTH\s*=\s*(\d+)')    { $cfgBarWidth = $Matches[1] }
    if ($slContent -match "CFG_FILLED_COLOR\s*=\s*'dynamic'") { $cfgColor = 'dynamic' }
    elseif ($slContent -match 'CFG_FILLED_COLOR\s*=\s*(\d+)')  { $cfgColor = $Matches[1] }
    if ($slContent -match "CFG_FORMAT\s*=\s*'([^']+)'")    { $cfgFormat = $Matches[1] }
    if ($slContent -match 'CFG_FILLED_CHAR\s*=\s*(.+)')    { $cfgFilledChar = $Matches[1].Trim() }
}

$colorName = switch ($cfgColor) { 'dynamic' { "Dynamic (green/yellow/red)" } 32 { "Green" } 36 { "Cyan" } 33 { "Yellow" } 37 { "White" } default { "ANSI $cfgColor" } }
$styleName = if ($cfgFilledChar -match '0x2588') { "Block" } elseif ($cfgFilledChar -match '0x2593') { "Shade" } elseif ($cfgFilledChar -match '"="') { "ASCII" } else { "Custom" }
$layoutName = switch ($cfgFormat) {
    '{0} {1} | {2} | {3} | {4} | {5}' { "Context Progress Bar, Context %, Tokens Used, Cost, Duration, Model" }
    '{0} {1} | {2} | {3} | {5}'       { "Context Progress Bar, Context %, Tokens Used, Cost, Model" }
    '{5} | {0} {1} | {2} | {3} | {4}' { "Model, Context Progress Bar, Context %, Tokens Used, Cost, Duration" }
    '{0} {1} | {3} | {5}'             { "Context Progress Bar, Context %, Cost, Model" }
    '{0} {1}'                          { "Context Progress Bar, Context %" }
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
