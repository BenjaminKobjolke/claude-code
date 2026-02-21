# setup.ps1 - Customize status-line.ps1 via interactive prompts
# Replaces only the config block between :config-start and :config-end

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Prompt-Choice($title, $options, $default) {
    Write-Host ""
    Write-Host "${title}:"
    for ($i = 0; $i -lt $options.Count; $i++) {
        $num = $i + 1
        $suffix = if ($num -eq $default) { "  (default)" } else { "" }
        Write-Host "  ${num}) $($options[$i])${suffix}"
    }
    $input = Read-Host "Choose [$default]"
    if ([string]::IsNullOrWhiteSpace($input)) { return $default }
    $parsed = 0
    if ([int]::TryParse($input, [ref]$parsed) -and $parsed -ge 1 -and $parsed -le $options.Count) {
        return $parsed
    }
    Write-Host "  Invalid choice, using default ($default)."
    return $default
}

$layoutChoice = Prompt-Choice "Layout" @(
    "Progress bar, Percentage, Tokens, Cost, Duration, Model"
    "Progress bar, Percentage, Tokens, Cost, Model"
    "Model, Progress bar, Percentage, Tokens, Cost, Duration"
    "Progress bar, Percentage, Cost, Model"
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
Write-Host "Updated $targetPath"
