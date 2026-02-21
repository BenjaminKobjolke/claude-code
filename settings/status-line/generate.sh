#!/bin/bash
# Interactive generator for status-line.sh (macOS)
# Prompts for layout, bar width, bar style, and bar color,
# then writes a customized status-line.sh in the same directory.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="$SCRIPT_DIR/status-line.sh"

# ── Prompt 1: Layout ─────────────────────────────────────────────────

echo ""
echo "Layout:"
echo "  1) Progress bar, Percentage, Tokens, Cost, Duration, Model  (default)"
echo "  2) Progress bar, Percentage, Tokens, Cost, Model"
echo "  3) Model, Progress bar, Percentage, Tokens, Cost, Duration"
echo "  4) Progress bar, Percentage, Cost, Model"
read -rp "Choose [1]: " layout_choice
layout_choice=${layout_choice:-1}

case "$layout_choice" in
    1)
        format_comment='# Format: {progress bar} {context %} | {tokens used/max} | {cost} | {duration} | {model}'
        format_example='# Output: ████▌██████████ 26.0% | 52.1k/200.0k | $1.93 | 3m 33s | Opus 4.6'
        output_printf_line1="printf '%s %s | %s/%s | %s | %s | %s\n' \\"
        output_printf_line2='    "$progress_bar" "$used_pct_str" "$used_str" "$max_str" "$cost_str" "$duration" "$model_name"'
        ;;
    2)
        format_comment='# Format: {progress bar} {context %} | {tokens used/max} | {cost} | {model}'
        format_example='# Output: ████▌██████████ 26.0% | 52.1k/200.0k | $1.93 | Opus 4.6'
        output_printf_line1="printf '%s %s | %s/%s | %s | %s\n' \\"
        output_printf_line2='    "$progress_bar" "$used_pct_str" "$used_str" "$max_str" "$cost_str" "$model_name"'
        ;;
    3)
        format_comment='# Format: {model} | {progress bar} {context %} | {tokens used/max} | {cost} | {duration}'
        format_example='# Output: Opus 4.6 | ████▌██████████ 26.0% | 52.1k/200.0k | $1.93 | 3m 33s'
        output_printf_line1="printf '%s | %s %s | %s/%s | %s | %s\n' \\"
        output_printf_line2='    "$model_name" "$progress_bar" "$used_pct_str" "$used_str" "$max_str" "$cost_str" "$duration"'
        ;;
    4)
        format_comment='# Format: {progress bar} {context %} | {cost} | {model}'
        format_example='# Output: ████▌██████████ 26.0% | $1.93 | Opus 4.6'
        output_printf_line1="printf '%s %s | %s | %s\n' \\"
        output_printf_line2='    "$progress_bar" "$used_pct_str" "$cost_str" "$model_name"'
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# ── Prompt 2: Bar width ──────────────────────────────────────────────

echo ""
echo "Bar width:"
echo "  1) 10"
echo "  2) 15  (default)"
echo "  3) 20"
read -rp "Choose [2]: " width_choice
width_choice=${width_choice:-2}

case "$width_choice" in
    1) bar_width=10 ;;
    2) bar_width=15 ;;
    3) bar_width=20 ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# ── Prompt 3: Bar style ──────────────────────────────────────────────

echo ""
echo "Bar style:"
echo "  1) Block: filled/half/empty using unicode blocks  (default)"
echo "  2) Shade: light shade / dark shade"
echo "  3) ASCII: equals / dashes"
read -rp "Choose [1]: " style_choice
style_choice=${style_choice:-1}

case "$style_choice" in
    1)
        # Block style: filled and empty use the same character (█), different colors
        block_vars="FULL_BLOCK=\$'\\xe2\\x96\\x88'   # U+2588 █
HALF_BLOCK=\$'\\xe2\\x96\\x8c'   # U+258C ▌"
        empty_loop_char='$FULL_BLOCK'
        ;;
    2)
        # Shade style
        block_vars="FULL_BLOCK=\$'\\xe2\\x96\\x93'   # U+2593 ▓
HALF_BLOCK=\$'\\xe2\\x96\\x92'   # U+2592 ▒
EMPTY_BLOCK=\$'\\xe2\\x96\\x91'  # U+2591 ░"
        empty_loop_char='$EMPTY_BLOCK'
        ;;
    3)
        # ASCII style
        block_vars="FULL_BLOCK='='
HALF_BLOCK='-'
EMPTY_BLOCK='-'"
        empty_loop_char='$EMPTY_BLOCK'
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# ── Prompt 4: Bar color ──────────────────────────────────────────────

echo ""
echo "Bar color:"
echo "  1) Green / Dim gray  (default)"
echo "  2) Cyan / Dim gray"
echo "  3) Yellow / Dim gray"
echo "  4) White / Dim gray"
read -rp "Choose [1]: " color_choice
color_choice=${color_choice:-1}

case "$color_choice" in
    1) filled_color=32 ; empty_color=90 ; color_label="Green / Dim gray" ; color_adj="green" ;;
    2) filled_color=36 ; empty_color=90 ; color_label="Cyan / Dim gray" ; color_adj="cyan" ;;
    3) filled_color=33 ; empty_color=90 ; color_label="Yellow / Dim gray" ; color_adj="yellow" ;;
    4) filled_color=37 ; empty_color=90 ; color_label="White / Dim gray" ; color_adj="white" ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# ── Summary ───────────────────────────────────────────────────────────

layout_labels=( "" "Bar + Pct + Tokens + Cost + Duration + Model"
                   "Bar + Pct + Tokens + Cost + Model"
                   "Model + Bar + Pct + Tokens + Cost + Duration"
                   "Bar + Pct + Cost + Model" )
style_labels=( "" "Block" "Shade" "ASCII" )

echo ""
echo "── Summary ──────────────────────────────"
echo "  Layout:    ${layout_labels[$layout_choice]}"
echo "  Bar width: $bar_width"
echo "  Bar style: ${style_labels[$style_choice]}"
echo "  Bar color: $color_label"
echo "  Output:    $OUTPUT"
echo "────────────────────────────────────────"
echo ""

# ── Generate status-line.sh ──────────────────────────────────────────

# Use a quoted heredoc for everything static (no shell expansion).
# Then use printf '%s\n' for lines that contain configurable values,
# to avoid unintended shell expansion of $ characters in the content.

cat > "$OUTPUT" << 'GENEOF'
#!/bin/bash
# Claude Code custom status line
# https://code.claude.com/docs/en/statusline
#
GENEOF

# Format comment and example (contain $ in cost, must not be expanded)
printf '%s\n' "$format_comment" >> "$OUTPUT"
printf '%s\n' "$format_example" >> "$OUTPUT"

printf '%s\n' "#" >> "$OUTPUT"
printf '%s\n' "# progressBar  = ${color_adj}/dim unicode block bar showing context usage visually  (persistent across resumes)" >> "$OUTPUT"

cat >> "$OUTPUT" << 'GENEOF'
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
GENEOF

# Color lines (configurable ANSI codes)
printf '%s\n' "GREEN=\"\${ESC}[${filled_color}m\"" >> "$OUTPUT"
printf '%s\n' "DIM=\"\${ESC}[${empty_color}m\"" >> "$OUTPUT"
printf '%s\n' "RESET=\"\${ESC}[0m\"" >> "$OUTPUT"

# Block character variables (configurable style)
printf '%s\n' "$block_vars" >> "$OUTPUT"

# Bar width (configurable)
printf '\n%s\n' "BAR_WIDTH=$bar_width" >> "$OUTPUT"

cat >> "$OUTPUT" << 'GENEOF'

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
GENEOF

# Empty loop line (configurable: uses $FULL_BLOCK for block style, $EMPTY_BLOCK for others)
printf '%s\n' "for ((i = 0; i < empty_width; i++)); do empty+=\"$empty_loop_char\"; done" >> "$OUTPUT"

cat >> "$OUTPUT" << 'GENEOF'

# --- Output ---

progress_bar="${GREEN}${filled}${half}${DIM}${empty}${RESET}"
used_pct_str=$(python3 -c "print(f'${used_pct:.1f}%')")
cost_str=$(python3 -c "print(f'\${${total_cost}:.2f}')")

GENEOF

# Printf statement (configurable layout)
printf '%s\n' "$output_printf_line1" >> "$OUTPUT"
printf '%s\n' "$output_printf_line2" >> "$OUTPUT"

chmod +x "$OUTPUT"

echo "Generated: $OUTPUT"
