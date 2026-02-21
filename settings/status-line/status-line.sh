#!/bin/bash
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

json=$(cat)

# Helper: extract a JSON value by dot-path (e.g. "model.display_name")
# Uses python3 for reliable JSON parsing (available by default on macOS)
jval() {
    printf '%s' "$json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
keys = '$1'.split('.')
val = data
for k in keys:
    if val is None or k not in val:
        val = None
        break
    val = val[k]
if val is None:
    print('')
else:
    print(val)
" 2>/dev/null
}

# --- Extract values ---

model_name=$(jval model.display_name)
used_pct=$(jval context_window.used_percentage)
total_cost=$(jval cost.total_cost_usd)
max_tokens=$(jval context_window.context_window_size)

used_pct=${used_pct:-0}
total_cost=${total_cost:-0}
max_tokens=${max_tokens:-200000}

# Use exact current_usage fields for token count (input tokens only, matching used_percentage formula)
# Falls back to deriving from used_percentage when current_usage is null (before first API call)
read -r used_tokens used_pct <<< "$(printf '%s' "$json" | python3 -c "
import sys, json, math
data = json.load(sys.stdin)
cu = data.get('context_window', {}).get('current_usage')
max_t = data.get('context_window', {}).get('context_window_size') or 200000
used_pct = data.get('context_window', {}).get('used_percentage') or 0
if cu is not None:
    used = cu.get('input_tokens', 0) + cu.get('cache_creation_input_tokens', 0) + cu.get('cache_read_input_tokens', 0)
    pct = used / max_t * 100
    print(f'{used} {pct}')
else:
    used = round(max_t * used_pct / 100)
    print(f'{used} {used_pct}')
" 2>/dev/null)"

# --- Format duration ---

duration_ms=$(jval cost.total_duration_ms)
duration_ms=${duration_ms:-0}

total_secs=$(python3 -c "import math; print(math.floor(${duration_ms} / 1000))")
hours=$((total_secs / 3600))
mins=$(( (total_secs % 3600) / 60 ))
secs=$((total_secs % 60))

if [ "$hours" -ge 1 ]; then
    duration="${hours}h ${mins}m"
elif [ "$mins" -ge 1 ]; then
    duration="${mins}m ${secs}s"
else
    duration="${secs}s"
fi

# --- Format token counts ---

format_tokens() {
    python3 -c "
n = $1
if n >= 1000000:
    print(f'{n/1000000:.1f}M')
elif n >= 1000:
    print(f'{n/1000:.1f}k')
else:
    print(int(n))
"
}

used_str=$(format_tokens "$used_tokens")
max_str=$(format_tokens "$max_tokens")

# --- Build progress bar ---

ESC=$'\033'
GREEN="${ESC}[32m"
DIM="${ESC}[90m"
RESET="${ESC}[0m"
FULL_BLOCK=$'\xe2\x96\x88'   # U+2588 █
HALF_BLOCK=$'\xe2\x96\x8c'   # U+258C ▌

BAR_WIDTH=15

read -r filled_width has_half empty_width <<< "$(python3 -c "
import math
exact_fill = ${BAR_WIDTH} * ${used_pct} / 100
filled = int(math.floor(exact_fill))
has_half = 1 if (exact_fill - filled) >= 0.5 else 0
empty = ${BAR_WIDTH} - filled - has_half
print(f'{filled} {has_half} {empty}')
")"

filled=""
for ((i = 0; i < filled_width; i++)); do filled+="$FULL_BLOCK"; done
half=""
if [ "$has_half" -eq 1 ]; then half="$HALF_BLOCK"; fi
empty=""
for ((i = 0; i < empty_width; i++)); do empty+="$FULL_BLOCK"; done

# --- Output ---

progress_bar="${GREEN}${filled}${half}${DIM}${empty}${RESET}"
used_pct_str=$(python3 -c "print(f'${used_pct:.1f}%')")
cost_str=$(python3 -c "print(f'\${${total_cost}:.2f}')")

printf '%s %s | %s/%s | %s | %s | %s\n' \
    "$progress_bar" "$used_pct_str" "$used_str" "$max_str" "$cost_str" "$duration" "$model_name"
