#!/bin/bash
# setup.sh - Customize status-line.sh via interactive prompts
# Replaces only the config block between :config-start and :config-end

FROM_INSTALL=false
for arg in "$@"; do
    [ "$arg" = "--from-install" ] && FROM_INSTALL=true
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$SCRIPT_DIR/status-line.sh"

echo "Customizing status line..."

# ── Show current settings when run standalone ─────────────────────
if [ "$FROM_INSTALL" = false ] && [ -f "$TARGET" ]; then
    cur_bar_width=$(grep -oP 'CFG_BAR_WIDTH=\K\d+' "$TARGET" 2>/dev/null || echo 15)
    cur_color=$(grep -oP 'CFG_FILLED_COLOR=\K\d+' "$TARGET" 2>/dev/null || echo 32)
    cur_filled_char=$(grep -oP 'CFG_FILLED_CHAR=\K.*' "$TARGET" 2>/dev/null || echo "")
    cur_output_line=$(sed -n '/^cfg_output()/,/^}/{ /printf/p; }' "$TARGET" 2>/dev/null || echo "")

    case "$cur_color" in
        32) cur_color_name="Green" ;; 36) cur_color_name="Cyan" ;; 33) cur_color_name="Yellow" ;; 37) cur_color_name="White" ;;
        *)  cur_color_name="ANSI $cur_color" ;;
    esac
    case "$cur_filled_char" in
        *96*88*) cur_style_name="Block" ;; *96*93*) cur_style_name="Shade" ;; *"="*) cur_style_name="ASCII" ;;
        *)       cur_style_name="Custom" ;;
    esac
    if echo "$cur_output_line" | grep -q 'model_name.*progress_bar'; then
        cur_layout_name="Model, Context Progress Bar, Context %, Tokens Used, Cost, Duration"
    elif echo "$cur_output_line" | grep -q 'duration.*model_name'; then
        cur_layout_name="Context Progress Bar, Context %, Tokens Used, Cost, Duration, Model"
    elif echo "$cur_output_line" | grep -q 'cost_str.*model_name' && ! echo "$cur_output_line" | grep -q 'duration'; then
        if echo "$cur_output_line" | grep -q 'max_str'; then
            cur_layout_name="Context Progress Bar, Context %, Tokens Used, Cost, Model"
        else
            cur_layout_name="Context Progress Bar, Context %, Cost, Model"
        fi
    else
        cur_layout_name="Context Progress Bar, Context %, Tokens Used, Cost, Duration, Model"
    fi

    echo ""
    echo "  Current settings:"
    echo "    Layout:    $cur_layout_name"
    echo "    Bar width: $cur_bar_width"
    echo "    Bar style: $cur_style_name"
    echo "    Bar color: $cur_color_name"
fi

# ── Prompt 1: Layout ─────────────────────────────────────────────────

echo ""
echo "  Layout:"
echo "    1) Context Progress Bar, Context %, Tokens Used, Cost, Duration, Model  (default)"
echo "    2) Context Progress Bar, Context %, Tokens Used, Cost, Model"
echo "    3) Model, Context Progress Bar, Context %, Tokens Used, Cost, Duration"
echo "    4) Context Progress Bar, Context %, Cost, Model"
read -rp "  Choose [1]: " layout_choice
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
    *) echo "    Invalid choice." ; exit 1 ;;
esac

# ── Prompt 2: Bar width ──────────────────────────────────────────────

echo ""
echo "  Bar width:"
echo "    1) 10"
echo "    2) 15  (default)"
echo "    3) 20"
read -rp "  Choose [2]: " width_choice
width_choice=${width_choice:-2}

case "$width_choice" in
    1) bar_width=10 ;; 2) bar_width=15 ;; 3) bar_width=20 ;;
    *) echo "    Invalid choice." ; exit 1 ;;
esac

# ── Prompt 3: Bar style ──────────────────────────────────────────────

echo ""
echo "  Bar style:"
echo "    1) Block: unicode blocks  (default)"
echo "    2) Shade: light/dark shade"
echo "    3) ASCII: equals/dashes"
read -rp "  Choose [1]: " style_choice
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
    *) echo "    Invalid choice." ; exit 1 ;;
esac

# ── Prompt 4: Bar color ──────────────────────────────────────────────

echo ""
echo "  Bar color:"
echo "    1) Green / Dim gray  (default)"
echo "    2) Cyan / Dim gray"
echo "    3) Yellow / Dim gray"
echo "    4) White / Dim gray"
read -rp "  Choose [1]: " color_choice
color_choice=${color_choice:-1}

case "$color_choice" in
    1) filled_color=32 ;; 2) filled_color=36 ;; 3) filled_color=33 ;; 4) filled_color=37 ;;
    *) echo "    Invalid choice." ; exit 1 ;;
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

case "$filled_color" in
    32) color_name="Green" ;; 36) color_name="Cyan" ;; 33) color_name="Yellow" ;; 37) color_name="White" ;;
    *)  color_name="ANSI $filled_color" ;;
esac
case "$style_choice" in
    1) style_name="Block" ;; 2) style_name="Shade" ;; 3) style_name="ASCII" ;;
esac
case "$layout_choice" in
    1) layout_name="Context Progress Bar, Context %, Tokens Used, Cost, Duration, Model" ;;
    2) layout_name="Context Progress Bar, Context %, Tokens Used, Cost, Model" ;;
    3) layout_name="Model, Context Progress Bar, Context %, Tokens Used, Cost, Duration" ;;
    4) layout_name="Context Progress Bar, Context %, Cost, Model" ;;
esac

echo ""
echo "  New settings:"
echo "    Layout:    $layout_name"
echo "    Bar width: $bar_width"
echo "    Bar style: $style_name"
echo "    Bar color: $color_name"

if [ "$FROM_INSTALL" = false ]; then
    echo ""
    echo "Customization complete. Open a new Claude Code session to see changes."
    echo ""
    read -rp "Press Enter to exit"
fi
