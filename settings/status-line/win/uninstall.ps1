# uninstall.ps1 - Uninstall Claude Code custom status line
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Pause-Exit($code) {
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit $code
}

Write-Host "Uninstalling Claude Code status line..."

# ── Paths ───────────────────────────────────────────────────────────
$claudeDir     = Join-Path $env:USERPROFILE ".claude"
$settingsFile  = Join-Path $claudeDir "settings.json"
$backupFile    = "$settingsFile.bak"
$statusLineDir = Join-Path $claudeDir "settings\status-line"

# ── Detect installation ─────────────────────────────────────────────
$hasKey = $false
$hasDir = Test-Path $statusLineDir

if (Test-Path $settingsFile) {
    try {
        $rawObj = [System.IO.File]::ReadAllText($settingsFile, $utf8NoBom) | ConvertFrom-Json
        $hasKey = $null -ne $rawObj.statusLine
    } catch {}
}

if (-not $hasKey -and -not $hasDir) {
    Write-Host "  Status line is not installed. Nothing to do."
    Pause-Exit 0
}

# ── Show what will be removed ────────────────────────────────────────
Write-Host ""
Write-Host "  Found:"
if ($hasKey) { Write-Host "    - statusLine key in $settingsFile" }
if ($hasDir) { Write-Host "    - Directory $statusLineDir" }
Write-Host ""

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

# ── Remove status-line directory ─────────────────────────────────────
if ($hasDir) {
    Write-Host ""
    $answer = Read-Host "  Delete $statusLineDir ? [Y/n]"
    if ($answer -match '^[Nn]') {
        Write-Host "  Skipped. Directory was not removed."
    } else {
        try {
            Remove-Item $statusLineDir -Recurse -Force -ErrorAction Stop
            Write-Host "  Deleted $statusLineDir"
        } catch {
            Write-Host "  Could not delete $statusLineDir (files may be in use)."
            Write-Host "  Close all Claude Code sessions and try again, or delete it manually."
        }
    }
}

Write-Host ""
Write-Host "Status line uninstalled."

Pause-Exit 0
