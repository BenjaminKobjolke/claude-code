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
    1) cfg_output_body='    printf '"'"'%s %s | %s/%s | %s | %s | %s\n'"'"' \
        "$progress_bar" "$used_pct_str" "$used_str" "$max_str" "$cost_str" "$duration" "$model_name"' ;;
    2) cfg_output_body='    printf '"'"'%s %s | %s/%s | %s | %s\n'"'"' \
        "$progress_bar" "$used_pct_str" "$used_str" "$max_str" "$cost_str" "$model_name"' ;;
    3) cfg_output_body='    printf '"'"'%s | %s %s | %s/%s | %s | %s\n'"'"' \
        "$model_name" "$progress_bar" "$used_pct_str" "$used_str" "$max_str" "$cost_str" "$duration"' ;;
    4) cfg_output_body='    printf '"'"'%s %s | %s | %s\n'"'"' \
        "$progress_bar" "$used_pct_str" "$cost_str" "$model_name"' ;;
    *) echo "Invalid choice. Exiting." ; exit 1 ;;
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
    *) echo "Invalid choice. Exiting." ; exit 1 ;;
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
    1) cfg_filled="CFG_FILLED_CHAR=\$'\\xe2\\x96\\x88'   # █"
       cfg_half="CFG_HALF_CHAR=\$'\\xe2\\x96\\x8c'     # ▌"
       cfg_empty="CFG_EMPTY_CHAR=\$'\\xe2\\x96\\x88'    # █"
       style_label="Block" ;;
    2) cfg_filled="CFG_FILLED_CHAR=\$'\\xe2\\x96\\x93'   # ▓"
       cfg_half="CFG_HALF_CHAR=\$'\\xe2\\x96\\x92'     # ▒"
       cfg_empty="CFG_EMPTY_CHAR=\$'\\xe2\\x96\\x91'    # ░"
       style_label="Shade" ;;
    3) cfg_filled="CFG_FILLED_CHAR='='                  # ="
       cfg_half="CFG_HALF_CHAR='-'                    # -"
       cfg_empty="CFG_EMPTY_CHAR='-'                   # -"
       style_label="ASCII" ;;
    *) echo "Invalid choice. Exiting." ; exit 1 ;;
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
    1) filled_color=32 ; color_label="Green" ; color_adj="green" ;;
    2) filled_color=36 ; color_label="Cyan"  ; color_adj="cyan"  ;;
    3) filled_color=33 ; color_label="Yellow"; color_adj="yellow" ;;
    4) filled_color=37 ; color_label="White" ; color_adj="white" ;;
    *) echo "Invalid choice. Exiting." ; exit 1 ;;
esac
empty_color=90

# ── Summary ───────────────────────────────────────────────────────────

layout_labels=( "" "Bar + Pct + Tokens + Cost + Duration + Model"
                   "Bar + Pct + Tokens + Cost + Model"
                   "Model + Bar + Pct + Tokens + Cost + Duration"
                   "Bar + Pct + Cost + Model" )

echo ""
echo "── Summary ──────────────────────────────"
echo "  Layout:    ${layout_labels[$layout_choice]}"
echo "  Bar width: $bar_width"
echo "  Bar style: $style_label"
echo "  Bar color: $color_label / Dim gray"
echo "  Output:    $OUTPUT"
echo "────────────────────────────────────────"
echo ""

# ── Generate: config block ────────────────────────────────────────────

cat > "$OUTPUT" << GENEOF
#!/bin/bash
# Claude Code custom status line
# https://code.claude.com/docs/en/statusline

# --- Configuration (edit these, or use generate.sh) ---

CFG_BAR_WIDTH=$bar_width
CFG_FILLED_COLOR=$filled_color            # ANSI: 32=green, 36=cyan, 33=yellow, 37=white
CFG_EMPTY_COLOR=$empty_color             # ANSI: 90=dim gray
$cfg_filled
$cfg_half
$cfg_empty

cfg_output() {
$cfg_output_body
}

# --- End configuration ---
GENEOF

# ── Generate: static body (one heredoc, no substitution) ──────────────

cat >> "$OUTPUT" << 'GENEOF'

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
GREEN="${ESC}[${CFG_FILLED_COLOR}m"
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
GENEOF

chmod +x "$OUTPUT"
echo "Generated: $OUTPUT"
