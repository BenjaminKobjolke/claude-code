# install.ps1 - Interactive setting installer launcher (Windows)
# Discovers available settings from remote repo, presents selection menu,
# downloads and runs the chosen setting's installer interactively.
# When piped (irm | iex), param() blocks don't work.
# Pass setting name via $env:SETTING_NAME or $SettingName variable.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$SettingName = if ($env:SETTING_NAME) { $env:SETTING_NAME } else { '' }

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

# ── Pipe and execute the sub-installer ───────────────────────────
$url = "$REPO_RAW/$selected/win/install.ps1"
irm $url | iex
