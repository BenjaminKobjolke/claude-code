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

if (-not (Test-Path $tempFile) -or (Get-Item $tempFile).Length -eq 0) {
    Write-Host "ERROR: Downloaded installer is empty or missing."
    exit 1
}

# ── Run interactively ────────────────────────────────────────────
$exitCode = 1
try {
    & powershell -NoProfile -File $tempFile
    $exitCode = $LASTEXITCODE
} finally {
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
}

exit $exitCode
