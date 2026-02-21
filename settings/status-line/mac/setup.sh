#!/bin/bash
# setup.sh - Customize status-line.sh via interactive prompts
# Replaces only the config block between :config-start and :config-end

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/status-line.sh"

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
    1) cfg_output='    printf '"'"'%s %s | %s/%s | %s | %s | %s\n'"'"' \
        "$progress_bar" "$used_pct_str" "$used_str" "$max_str" "$cost_str" "$duration" "$model_name"' ;;
    2) cfg_output='    printf '"'"'%s %s | %s/%s | %s | %s\n'"'"' \
        "$progress_bar" "$used_pct_str" "$used_str" "$max_str" "$cost_str" "$model_name"' ;;
    3) cfg_output='    printf '"'"'%s | %s %s | %s/%s | %s | %s\n'"'"' \
        "$model_name" "$progress_bar" "$used_pct_str" "$used_str" "$max_str" "$cost_str" "$duration"' ;;
    4) cfg_output='    printf '"'"'%s %s | %s | %s\n'"'"' \
        "$progress_bar" "$used_pct_str" "$cost_str" "$model_name"' ;;
    *) echo "Invalid choice." ; exit 1 ;;
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
    1) bar_width=10 ;; 2) bar_width=15 ;; 3) bar_width=20 ;;
    *) echo "Invalid choice." ; exit 1 ;;
esac

# ── Prompt 3: Bar style ──────────────────────────────────────────────

echo ""
echo "Bar style:"
echo "  1) Block: unicode blocks  (default)"
echo "  2) Shade: light/dark shade"
echo "  3) ASCII: equals/dashes"
read -rp "Choose [1]: " style_choice
style_choice=${style_choice:-1}

case "$style_choice" in
    1) cfg_filled="CFG_FILLED_CHAR=\$'\\xe2\\x96\\x88'"
       cfg_half="CFG_HALF_CHAR=\$'\\xe2\\x96\\x8c'"
       cfg_empty="CFG_EMPTY_CHAR=\$'\\xe2\\x96\\x88'" ;;
    2) cfg_filled="CFG_FILLED_CHAR=\$'\\xe2\\x96\\x93'"
       cfg_half="CFG_HALF_CHAR=\$'\\xe2\\x96\\x92'"
       cfg_empty="CFG_EMPTY_CHAR=\$'\\xe2\\x96\\x91'" ;;
    3) cfg_filled="CFG_FILLED_CHAR='='"
       cfg_half="CFG_HALF_CHAR='-'"
       cfg_empty="CFG_EMPTY_CHAR='-'" ;;
    *) echo "Invalid choice." ; exit 1 ;;
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
    1) filled_color=32 ;; 2) filled_color=36 ;; 3) filled_color=33 ;; 4) filled_color=37 ;;
    *) echo "Invalid choice." ; exit 1 ;;
esac

# ── Build replacement config block ────────────────────────────────────

config_block="# :config-start
CFG_BAR_WIDTH=$bar_width
CFG_FILLED_COLOR=$filled_color
CFG_EMPTY_COLOR=90
$cfg_filled
$cfg_half
$cfg_empty
cfg_output() {
$cfg_output
}
# :config-end"

# ── Replace between markers ───────────────────────────────────────────

tmpfile=$(mktemp)
awk -v block="$config_block" '
    /^# :config-start/ { print block; skip=1; next }
    /^# :config-end/   { skip=0; next }
    !skip { print }
' "$TARGET" > "$tmpfile"
mv "$tmpfile" "$TARGET"
chmod +x "$TARGET"

echo "Updated $TARGET"
