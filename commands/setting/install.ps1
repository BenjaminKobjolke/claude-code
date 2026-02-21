# install.ps1 - Interactive setting installer launcher (Windows)
# Discovers available settings from remote repo, presents selection menu,
# downloads and runs the chosen setting's installer interactively.
param([string]$SettingName)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$REPO    = 'BenjaminKobjolke/claude-code'
$BRANCH  = 'main'
$DIR     = 'settings'
$REPO_API = "https://api.github.com/repos/$REPO/contents/$DIR`?ref=$BRANCH"
$REPO_RAW = "https://raw.githubusercontent.com/$REPO/$BRANCH/$DIR"

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

# ── Download installer to isolated temp dir ──────────────────────
# The sub-installer uses $PSScriptRoot to detect local vs remote mode.
# By placing it inside an isolated temp directory (not next to real
# setting files), $sourceRoot won't contain win/settings.json and the
# sub-installer falls through to its remote download branch.
$url = "$REPO_RAW/$selected/win/install.ps1"
$tempDir = Join-Path $env:TEMP "claude-setting-launcher-$selected"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
$tempFile = Join-Path $tempDir "install.ps1"

try {
    Invoke-RestMethod -Uri $url -OutFile $tempFile
} catch {
    Write-Host "ERROR: Failed to download installer from:"
    Write-Host "  $url"
    Write-Host "  $_"
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

if (-not (Test-Path $tempFile) -or (Get-Item $tempFile).Length -eq 0) {
    Write-Host "ERROR: Downloaded installer is empty or missing."
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# ── Run interactively ────────────────────────────────────────────
$exitCode = 1
try {
    & powershell -NoProfile -File $tempFile
    $exitCode = $LASTEXITCODE
} finally {
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

exit $exitCode
