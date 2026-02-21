# Claude Code custom status line
# https://code.claude.com/docs/en/statusline
#
# Format: {progress bar} {context %} | {tokens used/max} | {cost} | {duration} | {model}
# Output: ████▌██████████ 26.0% | 52.1k/200.0k | $1.93 | 3m 33s | Opus 4.6
#
# progressBar  = green/dim unicode block bar showing context usage visually  (persistent across resumes)
# usedPctStr   = context window usage as percentage                         (persistent across resumes)
# tokenStr     = current context usage / max context window size            (persistent across resumes)
# totalCost    = session cost in USD                                        (resets on resume)
# duration     = total wall-clock time since session started                (resets on resume)
# modelName    = active model display name                                  (persistent across resumes)

# --- Parse JSON from stdin ---

$json = [Console]::In.ReadToEnd() | ConvertFrom-Json

# --- Extract values ---

$modelName = $json.model.display_name
$usedPct   = if ($null -ne $json.context_window.used_percentage) { $json.context_window.used_percentage } else { 0 }
$totalCost = if ($null -ne $json.cost.total_cost_usd) { $json.cost.total_cost_usd } else { 0 }
$maxTokens = if ($null -ne $json.context_window.context_window_size) { $json.context_window.context_window_size } else { 200000 }

# Use exact current_usage fields for token count (input tokens only, matching used_percentage formula)
# Falls back to deriving from used_percentage when current_usage is null (before first API call)
$cu = $json.context_window.current_usage
if ($null -ne $cu) {
    $usedTokens = $cu.input_tokens + $cu.cache_creation_input_tokens + $cu.cache_read_input_tokens
    $usedPct = $usedTokens / $maxTokens * 100
} else {
    $usedTokens = [math]::Round($maxTokens * $usedPct / 100)
}

# --- Format duration ---

$durationMs = if ($null -ne $json.cost.total_duration_ms) { $json.cost.total_duration_ms } else { 0 }
$elapsed = [TimeSpan]::FromMilliseconds($durationMs)
if ($elapsed.TotalHours -ge 1) {
    $duration = "{0}h {1}m" -f [math]::Floor($elapsed.TotalHours), $elapsed.Minutes
} elseif ($elapsed.TotalMinutes -ge 1) {
    $duration = "{0}m {1}s" -f [math]::Floor($elapsed.TotalMinutes), $elapsed.Seconds
} else {
    $duration = "{0}s" -f [math]::Floor($elapsed.TotalSeconds)
}

# --- Format token counts ---

function Format-Tokens($n) {
    if ($n -ge 1000000) { return "{0:F1}M" -f ($n / 1000000) }
    if ($n -ge 1000)    { return "{0:F1}k" -f ($n / 1000) }
    return "$n"
}

# --- Build progress bar ---

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$esc       = [char]27
$green     = "$esc[32m"
$dim       = "$esc[90m"
$reset     = "$esc[0m"
$fullBlock = [char]0x2588
$halfBlock = [char]0x258C

$barWidth    = 15
$exactFill   = $barWidth * $usedPct / 100
$filledWidth = [math]::Floor($exactFill)
$hasHalf     = ($exactFill - $filledWidth) -ge 0.5
$emptyWidth  = $barWidth - $filledWidth - ([int]$hasHalf)

$filled = ([string]$fullBlock) * $filledWidth
$half   = if ($hasHalf) { [string]$halfBlock } else { "" }
$empty  = ([string]$fullBlock) * $emptyWidth

# --- Output ---

$progressBar = "$green$filled$half$dim$empty$reset"
$usedPctStr  = "{0:F1}%" -f $usedPct
$tokenStr    = "$(Format-Tokens $usedTokens)/$(Format-Tokens $maxTokens)"
$costStr     = "`$$("{0:F2}" -f $totalCost)"

Write-Host "$progressBar $usedPctStr | $tokenStr | $costStr | $duration | $modelName"