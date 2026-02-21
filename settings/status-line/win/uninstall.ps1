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

    # ── Patch: remove statusLine block (regex, preserves formatting) ──
    # Regex matches the "statusLine": { ... } block with optional trailing comma
    $pattern = '[ \t]*"statusLine"\s*:\s*\{[^{}]*\}\s*,?[ \t]*\r?\n?'
    $m = [regex]::Match($raw, $pattern)

    if ($m.Success) {
        $before = $raw.Substring(0, $m.Index)
        $after  = $raw.Substring($m.Index + $m.Length)
        # If the previous non-whitespace char is a comma and next non-whitespace is '}', remove trailing comma
        $beforeTrimmed = $before.TrimEnd()
        $afterTrimmed  = $after.TrimStart("`r", "`n")
        if ($beforeTrimmed.Length -gt 0 -and $beforeTrimmed[-1] -eq ',' -and $afterTrimmed.Length -gt 0 -and $afterTrimmed[0] -eq '}') {
            $before = $beforeTrimmed.Substring(0, $beforeTrimmed.Length - 1)
            $eol = if ($raw.Contains("`r`n")) { "`r`n" } else { "`n" }
            $patched = $before + $eol + $after.TrimStart("`r", "`n")
        } else {
            $patched = $before + $after
        }
    } else {
        $patched = $raw
    }

    # ── Validate patched result ───────────────────────────────────────
    $patchedObj = $null
    try { $patchedObj = $patched | ConvertFrom-Json } catch {}

    $origObj = $raw | ConvertFrom-Json
    $origKeyCount = $origObj.PSObject.Properties.Name.Count
    $valid = $patchedObj -and
             $null -eq $patchedObj.statusLine -and
             $patchedObj.PSObject.Properties.Name.Count -eq ($origKeyCount - 1)

    if (-not $valid) {
        Write-Host "  Using fallback merge method."
        $fHash = [ordered]@{}
        $origObj.PSObject.Properties | ForEach-Object {
            if ($_.Name -ne 'statusLine') { $fHash[$_.Name] = $_.Value }
        }
        $patched = ([PSCustomObject]$fHash) | ConvertTo-Json -Depth 10
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
    $tmpNew = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tmpOld, $raw, $utf8NoBom)
    [System.IO.File]::WriteAllText($tmpNew, $patched, $utf8NoBom)

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
        Write-Host "  Removing statusLine key from settings.json"
    }

    Remove-Item $tmpOld, $tmpNew -Force -ErrorAction SilentlyContinue

    Write-Host ""
    $answer = Read-Host "  Remove statusLine from settings.json? [Y/n]"
    if ($answer -match '^[Nn]') {
        Write-Host "  Skipped. statusLine key was not removed."
    } else {
        # ── Backup (2-revision rotation) ─────────────────────────────
        if (Test-Path $settingsFile) {
            if (Test-Path "$backupFile.1") { Remove-Item "$backupFile.1" -Force }
            if (Test-Path $backupFile) { Rename-Item $backupFile "$backupFile.1" -Force }
            Copy-Item $settingsFile $backupFile -Force
            Write-Host "  Backing up settings.json -> settings.json.bak"
        }

        # ── Write atomically ─────────────────────────────────────────
        $tmpFile = "$settingsFile.tmp"
        [System.IO.File]::WriteAllText($tmpFile, $patched, $utf8NoBom)
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
