#!/bin/bash
# Claude Code custom status line
# https://code.claude.com/docs/en/statusline
#
# Format: {progress bar} {context %} | {tokens used/max} | {cost} | {duration} | {model}
# Output: ██▌███████ 26.0% | 52.1k/200.0k | $1.93 | 3m 33s | Opus 4.6
#
# progressBar  = dynamic color bar showing context health visually           (persistent across resumes)
#                  green (<50%) healthy | yellow (50-75%) caution | red (>75%) critical
# usedPctStr   = context window usage as percentage                         (persistent across resumes)
# tokenStr     = current context usage / max context window size            (persistent across resumes)
# totalCost    = session cost in USD                                        (resets on resume)
# duration     = total wall-clock time since session started                (resets on resume)
# modelName    = active model display name                                  (persistent across resumes)

# :config-start
CFG_BAR_WIDTH=10
CFG_FILLED_COLOR=dynamic
CFG_EMPTY_COLOR=90
CFG_FILLED_CHAR=$'\xe2\x96\x88'
CFG_HALF_CHAR=$'\xe2\x96\x8c'
CFG_EMPTY_CHAR=$'\xe2\x96\x88'
cfg_output() {
    printf '%s %s | %s/%s | %s | %s | %s\n' \
        "$progress_bar" "$used_pct_str" "$used_str" "$max_str" "$cost_str" "$duration" "$model_name"
}
# :config-end

json=$(cat)

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

model_name=$(jval model.display_name)
used_pct=$(jval context_window.used_percentage)
total_cost=$(jval cost.total_cost_usd)
max_tokens=$(jval context_window.context_window_size)

used_pct=${used_pct:-0}
total_cost=${total_cost:-0}
max_tokens=${max_tokens:-200000}

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

ESC=$'\033'
if [ "$CFG_FILLED_COLOR" = "dynamic" ]; then
    filled_color_code=$(python3 -c "
pct = ${used_pct}
if pct >= 75: print(31)
elif pct >= 50: print(33)
else: print(32)
")
else
    filled_color_code=$CFG_FILLED_COLOR
fi
GREEN="${ESC}[${filled_color_code}m"
DIM="${ESC}[${CFG_EMPTY_COLOR}m"
RESET="${ESC}[0m"

read -r filled_width has_half empty_width <<< "$(python3 -c "
import math
exact_fill = ${CFG_BAR_WIDTH} * ${used_pct} / 100
filled = int(math.floor(exact_fill))
has_half = 1 if (exact_fill - filled) >= 0.5 else 0
empty = ${CFG_BAR_WIDTH} - filled - has_half
print(f'{filled} {has_half} {empty}')
")"

filled=""
for ((i = 0; i < filled_width; i++)); do filled+="$CFG_FILLED_CHAR"; done
half=""
if [ "$has_half" -eq 1 ]; then half="$CFG_HALF_CHAR"; fi
empty=""
for ((i = 0; i < empty_width; i++)); do empty+="$CFG_EMPTY_CHAR"; done

progress_bar="${GREEN}${filled}${half}${DIM}${empty}${RESET}"
used_pct_str=$(python3 -c "print(f'${used_pct:.1f}%')")
cost_str=$(python3 -c "print(f'\${${total_cost}:.2f}')")

cfg_output
