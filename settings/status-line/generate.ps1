# generate.ps1 - Interactive generator for Claude Code status-line.ps1
# Prompts the user for layout, bar width, bar style, and bar color,
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

$formatStrings = @{
    1 = '"$progressBar $usedPctStr | $tokenStr | $costStr | $duration | $modelName"'
    2 = '"$progressBar $usedPctStr | $tokenStr | $costStr | $modelName"'
    3 = '"$modelName | $progressBar $usedPctStr | $tokenStr | $costStr | $duration"'
    4 = '"$progressBar $usedPctStr | $costStr | $modelName"'
}
$formatDescriptions = @{
    1 = "{progress bar} {context %} | {tokens used/max} | {cost} | {duration} | {model}"
    2 = "{progress bar} {context %} | {tokens used/max} | {cost} | {model}"
    3 = "{model} | {progress bar} {context %} | {tokens used/max} | {cost} | {duration}"
    4 = "{progress bar} {context %} | {cost} | {model}"
}

$writeHostStr = $formatStrings[$layoutChoice]
$formatDesc = $formatDescriptions[$layoutChoice]

# --- Prompt 2: Bar width ---

$widthChoice = Prompt-Choice "Bar width" @(
    "10"
    "15"
    "20"
) 2

$barWidths = @{ 1 = 10; 2 = 15; 3 = 20 }
$barWidth = $barWidths[$widthChoice]

# --- Prompt 3: Bar style ---

$styleChoice = Prompt-Choice "Bar style" @(
    "Block: filled/half/empty using unicode blocks"
    "Shade: light shade / dark shade"
    "ASCII: equals / dashes"
) 1

# --- Prompt 4: Bar color ---

$colorChoice = Prompt-Choice "Bar color" @(
    "Green / Dim gray"
    "Cyan / Dim gray"
    "Yellow / Dim gray"
    "White / Dim gray"
) 1

$filledColors = @{ 1 = 32; 2 = 36; 3 = 33; 4 = 37 }
$emptyColor = 90
$filledColor = $filledColors[$colorChoice]

$colorNames = @{ 1 = "Green"; 2 = "Cyan"; 3 = "Yellow"; 4 = "White" }
$colorName = $colorNames[$colorChoice]

$styleNames = @{ 1 = "Block"; 2 = "Shade"; 3 = "ASCII" }
$styleName = $styleNames[$styleChoice]

$colorAdj = $colorName.ToLower()

# --- Build example output for header ---

# Build a representative example bar based on chosen style and width.
# The example simulates ~30% fill (4 filled + half + remainder at width 15) for illustration.
# exactFill is computed as barWidth * 0.3 to produce an appealing sample bar.
$exampleExact = $barWidth * 0.3
$exampleFilled = [math]::Floor($exampleExact)
$exampleHasHalf = ($exampleExact - $exampleFilled) -ge 0.5

if ($styleChoice -eq 1) {
    $exFilled = ([string][char]0x2588) * $exampleFilled
    $exHalf = if ($exampleHasHalf) { [string][char]0x258C } else { "" }
    $exEmpty = ([string][char]0x2588) * ($barWidth - $exampleFilled - ([int]$exampleHasHalf))
} elseif ($styleChoice -eq 2) {
    $exFilled = ([string][char]0x2593) * $exampleFilled
    $exHalf = if ($exampleHasHalf) { [string][char]0x2592 } else { "" }
    $exEmpty = ([string][char]0x2591) * ($barWidth - $exampleFilled - ([int]$exampleHasHalf))
} else {
    $exFilled = "=" * $exampleFilled
    $exHalf = if ($exampleHasHalf) { "-" } else { "" }
    $exEmpty = "-" * ($barWidth - $exampleFilled - ([int]$exampleHasHalf))
}
$exBar = "${exFilled}${exHalf}${exEmpty}"

$exampleOutputs = @{
    1 = "$exBar 26.0% | 52.1k/200.0k | `$1.93 | 3m 33s | Opus 4.6"
    2 = "$exBar 26.0% | 52.1k/200.0k | `$1.93 | Opus 4.6"
    3 = "Opus 4.6 | $exBar 26.0% | 52.1k/200.0k | `$1.93 | 3m 33s"
    4 = "$exBar 26.0% | `$1.93 | Opus 4.6"
}
$formatExample = $exampleOutputs[$layoutChoice]

# --- Summary ---

Write-Host ""
Write-Host "--- Summary ---"
Write-Host "  Layout:    $formatDesc"
Write-Host "  Bar width: $barWidth"
Write-Host "  Bar style: $styleName"
Write-Host "  Bar color: $colorName / Dim gray"
Write-Host ""

# --- Build the output script line by line ---

$lines = [System.Collections.Generic.List[string]]::new()

$lines.Add('# Claude Code custom status line')
$lines.Add('# https://code.claude.com/docs/en/statusline')
$lines.Add('#')
$lines.Add("# Format: $formatDesc")
$lines.Add("# Output: $formatExample")
$lines.Add('#')
$lines.Add("# progressBar  = ${colorAdj}/dim unicode block bar showing context usage visually  (persistent across resumes)")
$lines.Add('# usedPctStr   = context window usage as percentage                         (persistent across resumes)')
$lines.Add('# tokenStr     = current context usage / max context window size            (persistent across resumes)')
$lines.Add('# totalCost    = session cost in USD                                        (resets on resume)')
$lines.Add('# duration     = total wall-clock time since session started                (resets on resume)')
$lines.Add('# modelName    = active model display name                                  (persistent across resumes)')
$lines.Add('')
$lines.Add('# --- Parse JSON from stdin ---')
$lines.Add('')
$lines.Add('$json = [Console]::In.ReadToEnd() | ConvertFrom-Json')
$lines.Add('')
$lines.Add('# --- Extract values ---')
$lines.Add('')
$lines.Add('$modelName = $json.model.display_name')
$lines.Add('$usedPct   = if ($null -ne $json.context_window.used_percentage) { $json.context_window.used_percentage } else { 0 }')
$lines.Add('$totalCost = if ($null -ne $json.cost.total_cost_usd) { $json.cost.total_cost_usd } else { 0 }')
$lines.Add('$maxTokens = if ($null -ne $json.context_window.context_window_size) { $json.context_window.context_window_size } else { 200000 }')
$lines.Add('')
$lines.Add('# Use exact current_usage fields for token count (input tokens only, matching used_percentage formula)')
$lines.Add('# Falls back to deriving from used_percentage when current_usage is null (before first API call)')
$lines.Add('$cu = $json.context_window.current_usage')
$lines.Add('if ($null -ne $cu) {')
$lines.Add('    $usedTokens = $cu.input_tokens + $cu.cache_creation_input_tokens + $cu.cache_read_input_tokens')
$lines.Add('    $usedPct = $usedTokens / $maxTokens * 100')
$lines.Add('} else {')
$lines.Add('    $usedTokens = [math]::Round($maxTokens * $usedPct / 100)')
$lines.Add('}')
$lines.Add('')
$lines.Add('# --- Format duration ---')
$lines.Add('')
$lines.Add('$durationMs = if ($null -ne $json.cost.total_duration_ms) { $json.cost.total_duration_ms } else { 0 }')
$lines.Add('$elapsed = [TimeSpan]::FromMilliseconds($durationMs)')
$lines.Add('if ($elapsed.TotalHours -ge 1) {')
$lines.Add('    $duration = "{0}h {1}m" -f [math]::Floor($elapsed.TotalHours), $elapsed.Minutes')
$lines.Add('} elseif ($elapsed.TotalMinutes -ge 1) {')
$lines.Add('    $duration = "{0}m {1}s" -f [math]::Floor($elapsed.TotalMinutes), $elapsed.Seconds')
$lines.Add('} else {')
$lines.Add('    $duration = "{0}s" -f [math]::Floor($elapsed.TotalSeconds)')
$lines.Add('}')
$lines.Add('')
$lines.Add('# --- Format token counts ---')
$lines.Add('')
$lines.Add('function Format-Tokens($n) {')
$lines.Add('    if ($n -ge 1000000) { return "{0:F1}M" -f ($n / 1000000) }')
$lines.Add('    if ($n -ge 1000)    { return "{0:F1}k" -f ($n / 1000) }')
$lines.Add('    return "$n"')
$lines.Add('}')
$lines.Add('')
$lines.Add('# --- Build progress bar ---')
$lines.Add('')
$lines.Add('[Console]::OutputEncoding = [System.Text.Encoding]::UTF8')
$lines.Add('')
$lines.Add('$esc       = [char]27')
$lines.Add("`$green     = `"`$esc[$($filledColor)m`"")
$lines.Add("`$dim       = `"`$esc[$($emptyColor)m`"")
$lines.Add('$reset     = "$esc[0m"')

if ($styleChoice -eq 1) {
    $lines.Add('$fullBlock = [char]0x2588')
    $lines.Add('$halfBlock = [char]0x258C')
} elseif ($styleChoice -eq 2) {
    $lines.Add('$fullBlock = [char]0x2593')
    $lines.Add('$halfBlock = [char]0x2592')
    $lines.Add('$emptyBlock = [char]0x2591')
} else {
    $lines.Add('$fullBlock = "="')
    $lines.Add('$halfBlock = "-"')
}

$lines.Add('')
$lines.Add("`$barWidth    = $barWidth")
$lines.Add('$exactFill   = $barWidth * $usedPct / 100')
$lines.Add('$filledWidth = [math]::Floor($exactFill)')
$lines.Add('$hasHalf     = ($exactFill - $filledWidth) -ge 0.5')
$lines.Add('$emptyWidth  = $barWidth - $filledWidth - ([int]$hasHalf)')
$lines.Add('')
$lines.Add('$filled = ([string]$fullBlock) * $filledWidth')
$lines.Add('$half   = if ($hasHalf) { [string]$halfBlock } else { "" }')

if ($styleChoice -eq 1) {
    $lines.Add('$empty  = ([string]$fullBlock) * $emptyWidth')
} elseif ($styleChoice -eq 2) {
    $lines.Add('$empty  = ([string]$emptyBlock) * $emptyWidth')
} else {
    $lines.Add('$empty  = ([string]"-") * $emptyWidth')
}

$lines.Add('')
$lines.Add('# --- Output ---')
$lines.Add('')
$lines.Add('$progressBar = "$green$filled$half$dim$empty$reset"')
$lines.Add('$usedPctStr  = "{0:F1}%" -f $usedPct')
$lines.Add('$tokenStr    = "$(Format-Tokens $usedTokens)/$(Format-Tokens $maxTokens)"')
$lines.Add('$costStr     = "`$$("{0:F2}" -f $totalCost)"')
$lines.Add('')
$lines.Add("Write-Host $writeHostStr")

# --- Write the file ---

$outputPath = Join-Path $PSScriptRoot "status-line.ps1"
$scriptContent = $lines -join "`r`n"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($outputPath, $scriptContent, $utf8NoBom)
Write-Host "Wrote $outputPath"
