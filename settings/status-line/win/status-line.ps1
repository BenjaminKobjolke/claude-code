# Claude Code custom status line
# https://code.claude.com/docs/en/statusline
#
# Output: ████▌██████████ 26.0% | 52.1k/200.0k | $1.93 | 3m 33s | Opus 4.6
#
# progressBar  = green/dim unicode block bar showing context usage visually  (persistent across resumes)
# usedPctStr   = context window usage as percentage                         (persistent across resumes)
# tokenStr     = current context usage / max context window size            (persistent across resumes)
# totalCost    = session cost in USD                                        (resets on resume)
# duration     = total wall-clock time since session started                (resets on resume)
# modelName    = active model display name                                  (persistent across resumes)

# :config-start
$CFG_BAR_WIDTH    = 15
$CFG_FILLED_COLOR = 32
$CFG_EMPTY_COLOR  = 90
$CFG_FILLED_CHAR  = [char]0x2588
$CFG_HALF_CHAR    = [char]0x258C
$CFG_EMPTY_CHAR   = [char]0x2588
$CFG_FORMAT       = '{0} {1} | {2} | {3} | {4} | {5}'
# :config-end
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