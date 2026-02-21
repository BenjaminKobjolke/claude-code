# setup.ps1 - Customize status-line.ps1 via interactive prompts
# Replaces only the config block between :config-start and :config-end
param([switch]$FromInstall)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Prompt-Choice($title, $options, $default) {
    Write-Host ""
    Write-Host "  ${title}:"
    for ($i = 0; $i -lt $options.Count; $i++) {
        $num = $i + 1
        $suffix = if ($num -eq $default) { "  (default)" } else { "" }
        Write-Host "    ${num}) $($options[$i])${suffix}"
    }
    $input = Read-Host "  Choose [$default]"
    if ([string]::IsNullOrWhiteSpace($input)) { return $default }
    $parsed = 0
    if ([int]::TryParse($input, [ref]$parsed) -and $parsed -ge 1 -and $parsed -le $options.Count) {
        return $parsed
    }
    Write-Host "    Invalid choice, using default ($default)."
    return $default
}

Write-Host "Customizing status line..."

# ── Show current settings when run standalone ─────────────────────
if (-not $FromInstall) {
    $targetPath = Join-Path $PSScriptRoot "status-line.ps1"
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $curBarWidth = 15; $curColor = 32; $curFormat = '{0} {1} | {2} | {3} | {4} | {5}'
    $curFilledChar = '[char]0x2588'
    if (Test-Path $targetPath) {
        $slContent = [System.IO.File]::ReadAllText($targetPath, $utf8NoBom)
        if ($slContent -match 'CFG_BAR_WIDTH\s*=\s*(\d+)')    { $curBarWidth = $Matches[1] }
        if ($slContent -match 'CFG_FILLED_COLOR\s*=\s*(\d+)')  { $curColor = $Matches[1] }
        if ($slContent -match "CFG_FORMAT\s*=\s*'([^']+)'")    { $curFormat = $Matches[1] }
        if ($slContent -match 'CFG_FILLED_CHAR\s*=\s*(.+)')    { $curFilledChar = $Matches[1].Trim() }
    }
    $curColorName = switch ($curColor) { 32 { "Green" } 36 { "Cyan" } 33 { "Yellow" } 37 { "White" } default { "ANSI $curColor" } }
    $curStyleName = if ($curFilledChar -match '0x2588') { "Block" } elseif ($curFilledChar -match '0x2593') { "Shade" } elseif ($curFilledChar -match '"="') { "ASCII" } else { "Custom" }
    $curLayoutName = switch ($curFormat) {
        '{0} {1} | {2} | {3} | {4} | {5}' { "Context Progress Bar, Context %, Tokens Used, Cost, Duration, Model" }
        '{0} {1} | {2} | {3} | {5}'       { "Context Progress Bar, Context %, Tokens Used, Cost, Model" }
        '{5} | {0} {1} | {2} | {3} | {4}' { "Model, Context Progress Bar, Context %, Tokens Used, Cost, Duration" }
        '{0} {1} | {3} | {5}'             { "Context Progress Bar, Context %, Cost, Model" }
        default                            { $curFormat }
    }
    Write-Host ""
    Write-Host "  Current settings:"
    Write-Host "    Layout:    $curLayoutName"
    Write-Host "    Bar width: $curBarWidth"
    Write-Host "    Bar style: $curStyleName"
    Write-Host "    Bar color: $curColorName"
}

$layoutChoice = Prompt-Choice "Layout" @(
    "Context Progress Bar, Context %, Tokens Used, Cost, Duration, Model"
    "Context Progress Bar, Context %, Tokens Used, Cost, Model"
    "Model, Context Progress Bar, Context %, Tokens Used, Cost, Duration"
    "Context Progress Bar, Context %, Cost, Model"
) 1

$cfgFormat = @{
    1 = '{0} {1} | {2} | {3} | {4} | {5}'
    2 = '{0} {1} | {2} | {3} | {5}'
    3 = '{5} | {0} {1} | {2} | {3} | {4}'
    4 = '{0} {1} | {3} | {5}'
}[$layoutChoice]

$cfgBarWidth = @{ 1 = 10; 2 = 15; 3 = 20 }[(Prompt-Choice "Bar width" @( "10"; "15"; "20" ) 2)]

$styleChoice = Prompt-Choice "Bar style" @(
    "Block: unicode blocks"
    "Shade: light/dark shade"
    "ASCII: equals/dashes"
) 1

$style = @{
    1 = @{ filled = '[char]0x2588'; half = '[char]0x258C'; empty = '[char]0x2588' }
    2 = @{ filled = '[char]0x2593'; half = '[char]0x2592'; empty = '[char]0x2591' }
    3 = @{ filled = '"="';          half = '"-"';          empty = '"-"'          }
}[$styleChoice]

$cfgFilledColor = @{ 1 = 32; 2 = 36; 3 = 33; 4 = 37 }[(Prompt-Choice "Bar color" @(
    "Green / Dim gray"
    "Cyan / Dim gray"
    "Yellow / Dim gray"
    "White / Dim gray"
) 1)]

# --- Replace config block ---

$targetPath = Join-Path $PSScriptRoot "status-line.ps1"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$content = [System.IO.File]::ReadAllText($targetPath, $utf8NoBom)

$configBlock = @"
# :config-start
`$CFG_BAR_WIDTH    = $cfgBarWidth
`$CFG_FILLED_COLOR = $cfgFilledColor
`$CFG_EMPTY_COLOR  = 90
`$CFG_FILLED_CHAR  = $($style.filled)
`$CFG_HALF_CHAR    = $($style.half)
`$CFG_EMPTY_CHAR   = $($style.empty)
`$CFG_FORMAT       = '$cfgFormat'
# :config-end
"@

$replaced = $content -replace '(?ms)^# :config-start\r?\n.*?^# :config-end', $configBlock
[System.IO.File]::WriteAllText($targetPath, $replaced, $utf8NoBom)

$colorName = switch ($cfgFilledColor) { 32 { "Green" } 36 { "Cyan" } 33 { "Yellow" } 37 { "White" } default { "ANSI $cfgFilledColor" } }
$styleName = switch ($styleChoice) { 1 { "Block" } 2 { "Shade" } 3 { "ASCII" } }
$layoutName = switch ($cfgFormat) {
    '{0} {1} | {2} | {3} | {4} | {5}' { "Context Progress Bar, Context %, Tokens Used, Cost, Duration, Model" }
    '{0} {1} | {2} | {3} | {5}'       { "Context Progress Bar, Context %, Tokens Used, Cost, Model" }
    '{5} | {0} {1} | {2} | {3} | {4}' { "Model, Context Progress Bar, Context %, Tokens Used, Cost, Duration" }
    '{0} {1} | {3} | {5}'             { "Context Progress Bar, Context %, Cost, Model" }
}

Write-Host ""
Write-Host "  New settings:"
Write-Host "    Layout:    $layoutName"
Write-Host "    Bar width: $cfgBarWidth"
Write-Host "    Bar style: $styleName"
Write-Host "    Bar color: $colorName"

if (-not $FromInstall) {
    Write-Host ""
    Write-Host "Customization complete. Open a new Claude Code session to see changes."
    Write-Host ""
    Read-Host "Press Enter to exit"
}
