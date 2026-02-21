# generate.ps1 - Interactive generator for status-line.ps1
# Prompts for layout, bar width, bar style, and bar color,
# then writes a customized status-line.ps1 in the same directory.

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

# --- Prompt 1: Layout ---

$layoutChoice = Prompt-Choice "Layout" @(
    "Progress bar, Percentage, Tokens, Cost, Duration, Model"
    "Progress bar, Percentage, Tokens, Cost, Model"
    "Model, Progress bar, Percentage, Tokens, Cost, Duration"
    "Progress bar, Percentage, Cost, Model"
) 1

# Format strings use -f positional args: {0}=bar {1}=pct {2}=tokens {3}=cost {4}=duration {5}=model
$formats = @{
    1 = '{0} {1} | {2} | {3} | {4} | {5}'
    2 = '{0} {1} | {2} | {3} | {5}'
    3 = '{5} | {0} {1} | {2} | {3} | {4}'
    4 = '{0} {1} | {3} | {5}'
}
$cfgFormat = $formats[$layoutChoice]

# --- Prompt 2: Bar width ---

$widthChoice = Prompt-Choice "Bar width" @( "10"; "15"; "20" ) 2
$cfgBarWidth = @{ 1 = 10; 2 = 15; 3 = 20 }[$widthChoice]

# --- Prompt 3: Bar style ---

$styleChoice = Prompt-Choice "Bar style" @(
    "Block: filled/half/empty using unicode blocks"
    "Shade: light shade / dark shade"
    "ASCII: equals / dashes"
) 1

$styles = @{
    1 = @{ filled = '[char]0x2588'; half = '[char]0x258C'; empty = '[char]0x2588';
           fc = ([char]0x2588); hc = ([char]0x258C); ec = ([char]0x2588) }
    2 = @{ filled = '[char]0x2593'; half = '[char]0x2592'; empty = '[char]0x2591';
           fc = ([char]0x2593); hc = ([char]0x2592); ec = ([char]0x2591) }
    3 = @{ filled = '"="';          half = '"-"';          empty = '"-"';
           fc = '=';               hc = '-';              ec = '-'            }
}
$style = $styles[$styleChoice]

# --- Prompt 4: Bar color ---

$colorChoice = Prompt-Choice "Bar color" @(
    "Green / Dim gray"
    "Cyan / Dim gray"
    "Yellow / Dim gray"
    "White / Dim gray"
) 1

$cfgFilledColor = @{ 1 = 32; 2 = 36; 3 = 33; 4 = 37 }[$colorChoice]
$cfgEmptyColor = 90

# --- Summary ---

$styleNames = @{ 1 = "Block"; 2 = "Shade"; 3 = "ASCII" }
$colorNames = @{ 1 = "Green"; 2 = "Cyan"; 3 = "Yellow"; 4 = "White" }

Write-Host ""
Write-Host "--- Summary ---"
Write-Host "  Layout:    $cfgFormat"
Write-Host "  Bar width: $cfgBarWidth"
Write-Host "  Bar style: $($styleNames[$styleChoice])"
Write-Host "  Bar color: $($colorNames[$colorChoice]) / Dim gray"
Write-Host ""

# --- Build example for header comment ---

$exExact = $cfgBarWidth * 0.3
$exFilled = [math]::Floor($exExact)
$exHasHalf = ($exExact - $exFilled) -ge 0.5
$exEmpty = $cfgBarWidth - $exFilled - ([int]$exHasHalf)
$exBar = (([string]$style.fc) * $exFilled) + $(if ($exHasHalf) { [string]$style.hc } else { "" }) + (([string]$style.ec) * $exEmpty)

$exOutput = $cfgFormat -f $exBar, '26.0%', '52.1k/200.0k', '$1.93', '3m 33s', 'Opus 4.6'
$colorAdj = $colorNames[$colorChoice].ToLower()

# --- Write the config block ---

$configBlock = @"
# Claude Code custom status line
# https://code.claude.com/docs/en/statusline
#
# Output: $exOutput
#
# progressBar  = $colorAdj/dim unicode block bar showing context usage visually  (persistent across resumes)
# usedPctStr   = context window usage as percentage                         (persistent across resumes)
# tokenStr     = current context usage / max context window size            (persistent across resumes)
# totalCost    = session cost in USD                                        (resets on resume)
# duration     = total wall-clock time since session started                (resets on resume)
# modelName    = active model display name                                  (persistent across resumes)

# --- Configuration (edit these, or use generate.ps1) ---

`$CFG_BAR_WIDTH    = $cfgBarWidth
`$CFG_FILLED_COLOR = $cfgFilledColor
`$CFG_EMPTY_COLOR  = $cfgEmptyColor
`$CFG_FILLED_CHAR  = $($style.filled)
`$CFG_HALF_CHAR    = $($style.half)
`$CFG_EMPTY_CHAR   = $($style.empty)
`$CFG_FORMAT       = '$cfgFormat'

# --- End configuration ---
"@

# --- Static body (never changes) ---

$staticBody = @'

$json = [Console]::In.ReadToEnd() | ConvertFrom-Json

$modelName = $json.model.display_name
$usedPct   = if ($null -ne $json.context_window.used_percentage) { $json.context_window.used_percentage } else { 0 }
$totalCost = if ($null -ne $json.cost.total_cost_usd) { $json.cost.total_cost_usd } else { 0 }
$maxTokens = if ($null -ne $json.context_window.context_window_size) { $json.context_window.context_window_size } else { 200000 }

$cu = $json.context_window.current_usage
if ($null -ne $cu) {
    $usedTokens = $cu.input_tokens + $cu.cache_creation_input_tokens + $cu.cache_read_input_tokens
    $usedPct = $usedTokens / $maxTokens * 100
} else {
    $usedTokens = [math]::Round($maxTokens * $usedPct / 100)
}

$durationMs = if ($null -ne $json.cost.total_duration_ms) { $json.cost.total_duration_ms } else { 0 }
$elapsed = [TimeSpan]::FromMilliseconds($durationMs)
if ($elapsed.TotalHours -ge 1) {
    $duration = "{0}h {1}m" -f [math]::Floor($elapsed.TotalHours), $elapsed.Minutes
} elseif ($elapsed.TotalMinutes -ge 1) {
    $duration = "{0}m {1}s" -f [math]::Floor($elapsed.TotalMinutes), $elapsed.Seconds
} else {
    $duration = "{0}s" -f [math]::Floor($elapsed.TotalSeconds)
}

function Format-Tokens($n) {
    if ($n -ge 1000000) { return "{0:F1}M" -f ($n / 1000000) }
    if ($n -ge 1000)    { return "{0:F1}k" -f ($n / 1000) }
    return "$n"
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$esc   = [char]27
$green = "$esc[$($CFG_FILLED_COLOR)m"
$dim   = "$esc[$($CFG_EMPTY_COLOR)m"
$reset = "$esc[0m"

$exactFill   = $CFG_BAR_WIDTH * $usedPct / 100
$filledWidth = [math]::Floor($exactFill)
$hasHalf     = ($exactFill - $filledWidth) -ge 0.5
$emptyWidth  = $CFG_BAR_WIDTH - $filledWidth - ([int]$hasHalf)

$filled = ([string]$CFG_FILLED_CHAR) * $filledWidth
$half   = if ($hasHalf) { [string]$CFG_HALF_CHAR } else { "" }
$empty  = ([string]$CFG_EMPTY_CHAR) * $emptyWidth

$progressBar = "$green$filled$half$dim$empty$reset"
$usedPctStr  = "{0:F1}%" -f $usedPct
$tokenStr    = "$(Format-Tokens $usedTokens)/$(Format-Tokens $maxTokens)"
$costStr     = "`$$("{0:F2}" -f $totalCost)"

Write-Host ($CFG_FORMAT -f $progressBar, $usedPctStr, $tokenStr, $costStr, $duration, $modelName)
'@

# --- Write file ---

$outputPath = Join-Path $PSScriptRoot "status-line.ps1"
$content = $configBlock + $staticBody
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($outputPath, $content, $utf8NoBom)
Write-Host "Wrote $outputPath"
