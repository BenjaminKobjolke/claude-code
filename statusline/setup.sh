#!/usr/bin/env bash
# Interactive statusline setup for Claude Code xida plugin.
# Installs/uninstalls statusline by modifying ~/.claude/settings.json.
# Configures widgets, color themes, and thresholds interactively.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS="$HOME/.claude/settings.json"
STATUSLINE_CMD="bash \"$SCRIPT_DIR/statusline.sh\""
CONF_FILE="$SCRIPT_DIR/statusline.conf"

# ── Dependency check ─────────────────────────────────

for cmd in jq curl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not installed."
    read -rp "Press Enter to exit..."
    exit 1
  fi
done

# ── Defaults ─────────────────────────────────────────

DEFAULT_SHOW_PROGRESS=1
DEFAULT_SHOW_TOKENS=1
DEFAULT_SHOW_COST=1
DEFAULT_SHOW_RATELIMIT=1
DEFAULT_SHOW_MODEL=1

DEFAULT_THEME="default"

DEFAULT_C_ACCENT='\033[36m'
DEFAULT_C_WARN='\033[33m'
DEFAULT_C_DANGER='\033[31m'
DEFAULT_C_DIM='\033[38;5;245m'

DEFAULT_CONTEXT_WARN_PCT=60
DEFAULT_CONTEXT_DANGER_PCT=80
DEFAULT_COST_WARN_USD=5
DEFAULT_COST_DANGER_USD=10
DEFAULT_RATE_WARN_PCT=50
DEFAULT_RATE_DANGER_PCT=80

# ── Theme definitions ────────────────────────────────

declare -a THEME_NAMES=("Default" "Blue" "Green" "Purple" "Monochrome")

declare -A THEME_ACCENT THEME_WARN THEME_DANGER THEME_DIM

THEME_ACCENT[default]='\033[36m'       # cyan
THEME_WARN[default]='\033[33m'         # yellow
THEME_DANGER[default]='\033[31m'       # red
THEME_DIM[default]='\033[38;5;245m'    # gray

THEME_ACCENT[blue]='\033[34m'          # blue
THEME_WARN[blue]='\033[33m'            # yellow
THEME_DANGER[blue]='\033[31m'          # red
THEME_DIM[blue]='\033[38;5;245m'       # gray

THEME_ACCENT[green]='\033[32m'         # green
THEME_WARN[green]='\033[33m'           # yellow
THEME_DANGER[green]='\033[31m'         # red
THEME_DIM[green]='\033[38;5;245m'      # gray

THEME_ACCENT[purple]='\033[35m'        # magenta
THEME_WARN[purple]='\033[33m'          # yellow
THEME_DANGER[purple]='\033[31m'        # red
THEME_DIM[purple]='\033[38;5;245m'     # gray

THEME_ACCENT[monochrome]='\033[37m'    # white
THEME_WARN[monochrome]='\033[37m'      # white
THEME_DANGER[monochrome]='\033[37m'    # white
THEME_DIM[monochrome]='\033[2;37m'     # dim white

declare -a THEME_KEYS=("default" "blue" "green" "purple" "monochrome")

# ── Load existing config ─────────────────────────────

SHOW_PROGRESS=1
SHOW_TOKENS=1
SHOW_COST=1
SHOW_RATELIMIT=1
SHOW_MODEL=1

C_ACCENT='\033[36m'
C_WARN='\033[33m'
C_DANGER='\033[31m'
C_DIM='\033[38;5;245m'

CONTEXT_WARN_PCT=60
CONTEXT_DANGER_PCT=80
COST_WARN_USD=5
COST_DANGER_USD=10
RATE_WARN_PCT=50
RATE_DANGER_PCT=80

XIDA_RATE=1
XIDA_RATE_EPOCH=0

HAS_CONFIG=0
if [ -f "$CONF_FILE" ]; then
  HAS_CONFIG=1
  source "$CONF_FILE"
fi

# ── Detect install state ─────────────────────────────

is_installed() {
  [ -f "$SETTINGS" ] || return 1
  local current
  current=$(jq -r '.statusLine.command // empty' "$SETTINGS" 2>/dev/null)
  [[ "$current" == *"$SCRIPT_DIR/statusline.sh"* ]]
}

get_current_statusline() {
  [ -f "$SETTINGS" ] || return
  jq -r '.statusLine.command // empty' "$SETTINGS" 2>/dev/null
}

# ── Theme detection ──────────────────────────────────

detect_theme() {
  for key in "${THEME_KEYS[@]}"; do
    if [ "$C_ACCENT" = "${THEME_ACCENT[$key]}" ] && \
       [ "$C_WARN" = "${THEME_WARN[$key]}" ] && \
       [ "$C_DANGER" = "${THEME_DANGER[$key]}" ] && \
       [ "$C_DIM" = "${THEME_DIM[$key]}" ]; then
      echo "$key"
      return
    fi
  done
  echo "custom"
}

theme_display_name() {
  local key="$1"
  case "$key" in
    default)     echo "Default" ;;
    blue)        echo "Blue" ;;
    green)       echo "Green" ;;
    purple)      echo "Purple" ;;
    monochrome)  echo "Monochrome" ;;
    custom)      echo "Custom" ;;
    *)           echo "$key" ;;
  esac
}

theme_color_hint() {
  local key="$1"
  case "$key" in
    default)     echo "cyan" ;;
    blue)        echo "blue" ;;
    green)       echo "green" ;;
    purple)      echo "magenta" ;;
    monochrome)  echo "white" ;;
    custom)      echo "" ;;
    *)           echo "" ;;
  esac
}

# ── UI helpers ───────────────────────────────────────

show_header() {
  clear 2>/dev/null || true
  echo "========================================"
  echo "  Claude Code Statusline Setup"
  if is_installed; then
    echo "  Status: Installed"
  else
    echo "  Status: Not installed"
  fi
  echo "========================================"
  echo ""
}

widget_label() {
  if [ "$1" = "1" ]; then echo "on"; else echo "off"; fi
}

show_current() {
  local current_theme
  current_theme=$(detect_theme)
  local C_RESET='\033[0m'

  echo "Current settings:"
  echo ""
  echo "  Widgets:"
  printf "    %-16s %s\n" "Progress:" "$(widget_label "$SHOW_PROGRESS")"
  printf "    %-16s %s\n" "Tokens:" "$(widget_label "$SHOW_TOKENS")"
  printf "    %-16s %s\n" "Cost:" "$(widget_label "$SHOW_COST")"
  printf "    %-16s %s\n" "Rate Limit:" "$(widget_label "$SHOW_RATELIMIT")"
  printf "    %-16s %s\n" "Model:" "$(widget_label "$SHOW_MODEL")"
  echo ""
  echo "  Theme:"
  local hint
  hint=$(theme_color_hint "$current_theme")
  printf '    %-16s %s %b██%b' "Colors:" "$(theme_display_name "$current_theme")" "$C_ACCENT" "$C_RESET"
  if [ -n "$hint" ]; then
    printf ' (%s)' "$hint"
  fi
  printf '\n'
  echo ""
  echo "  Thresholds:"
  printf "    %-16s warn=%d%%  danger=%d%%\n" "Context:" "$CONTEXT_WARN_PCT" "$CONTEXT_DANGER_PCT"
  printf "    %-16s warn=\$%s  danger=\$%s\n" "Cost:" "$COST_WARN_USD" "$COST_DANGER_USD"
  printf "    %-16s warn=%d%%  danger=%d%%\n" "Rate Limit:" "$RATE_WARN_PCT" "$RATE_DANGER_PCT"
  echo ""
}

quit_if_asked() {
  if [ "$1" = "QUIT" ]; then
    echo ""
    echo "Quit without saving."
    echo ""
    show_current
    read -rp "Press Enter to close..."
    exit 0
  fi
}

# ── Action prompt ────────────────────────────────────

ask_action() {
  echo "── What would you like to do? ───────────" >&2
  echo "" >&2
  if is_installed; then
    echo "  1: Update settings" >&2
    echo "     Change widgets, theme, and thresholds." >&2
    echo "" >&2
    echo "  u: Uninstall" >&2
    echo "     Remove statusline from settings.json" >&2
    echo "     and delete configuration file." >&2
    echo "" >&2
    echo "  q: Quit without changes" >&2
    echo "" >&2
    while true; do
      read -rp "  choice [1, u, q, Enter=update]: " action
      action="${action:-1}"
      case "$action" in
        1) echo "update"; return ;;
        u|U) echo "uninstall"; return ;;
        q|Q) echo "quit"; return ;;
        *) echo "  Invalid choice. Enter 1, u, or q." >&2 ;;
      esac
    done
  else
    echo "  1: Install" >&2
    echo "     Configure the xida statusline as your" >&2
    echo "     Claude Code status bar. Choose widgets," >&2
    echo "     color theme, and alert thresholds." >&2
    echo "" >&2
    echo "  q: Quit without changes" >&2
    echo "" >&2
    while true; do
      read -rp "  choice [1, q, Enter=install]: " action
      action="${action:-1}"
      case "$action" in
        1) echo "install"; return ;;
        q|Q) echo "quit"; return ;;
        *) echo "  Invalid choice. Enter 1 or q." >&2 ;;
      esac
    done
  fi
}

# ── Widget toggles ───────────────────────────────────

ask_widget() {
  local widget_label="$1"
  local current="$2"
  local default="$3"
  local choice

  local enter_value
  if [ "$HAS_CONFIG" = "1" ]; then
    enter_value="$current"
  else
    enter_value="$default"
  fi

  local enter_display
  if [ "$enter_value" = "1" ]; then enter_display="y"; else enter_display="n"; fi

  echo "" >&2
  echo "  $widget_label" >&2
  echo "    current = $(widget_label "$current")" >&2
  echo "    default = $(widget_label "$default")" >&2
  while true; do
    read -rp "    show? [y/n/q, Enter=$enter_display]: " choice
    choice="${choice:-$enter_display}"
    if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
      echo "QUIT"
      return
    fi
    case "$choice" in
      y|Y|yes|YES) echo "1"; return ;;
      n|N|no|NO)   echo "0"; return ;;
      *) echo "    Invalid. Enter y, n, or q." >&2 ;;
    esac
  done
}

# ── Color theme ──────────────────────────────────────

show_theme_preview() {
  local key="$1"
  local accent="${THEME_ACCENT[$key]}"
  local warn="${THEME_WARN[$key]}"
  local danger="${THEME_DANGER[$key]}"
  local dim="${THEME_DIM[$key]}"
  local reset='\033[0m'

  # Sample statusline: progress bar at 45%, tokens, cost, model
  printf '      '
  printf '%b████░░░░░░ 45%%%b' "$accent" "$reset"
  printf ' %b│%b ' "$dim" "$reset"
  printf '%b90K%b%b/200K%b' "$accent" "$reset" "$dim" "$reset"
  printf ' %b│%b ' "$dim" "$reset"
  printf '%b$3.50%b' "$accent" "$reset"
  printf ' %b│%b ' "$dim" "$reset"
  printf '%bOpus 4.6%b' "$accent" "$reset"
  printf '\n'
}

ask_theme() {
  local current_theme
  current_theme=$(detect_theme)
  local C_RESET='\033[0m'

  echo "" >&2
  echo "── Color theme ──────────────────────────" >&2
  echo "" >&2

  for i in "${!THEME_KEYS[@]}"; do
    local key="${THEME_KEYS[$i]}"
    local num=$((i + 1))
    local name="${THEME_NAMES[$i]}"
    local marker=""
    if [ "$key" = "$current_theme" ]; then marker=" (current)"; fi

    printf '  %d: %s%s\n' "$num" "$name" "$marker" >&2
    show_theme_preview "$key" >&2
    echo "" >&2
  done

  local enter_value
  if [ "$HAS_CONFIG" = "1" ]; then
    # Find current theme index (1-based), default to 1 if custom
    enter_value=1
    for i in "${!THEME_KEYS[@]}"; do
      if [ "${THEME_KEYS[$i]}" = "$current_theme" ]; then
        enter_value=$((i + 1))
        break
      fi
    done
  else
    enter_value=1
  fi

  local enter_name="${THEME_NAMES[$((enter_value - 1))]}"
  echo "  q: Quit without saving" >&2
  echo "" >&2

  while true; do
    read -rp "  choice [1-5, q, Enter=$enter_name]: " choice
    choice="${choice:-$enter_value}"
    if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
      echo "QUIT"
      return
    fi
    if [[ "$choice" =~ ^[1-5]$ ]]; then
      echo "${THEME_KEYS[$((choice - 1))]}"
      return
    fi
    echo "  Invalid choice. Enter 1-5 or q." >&2
  done
}

# ── Threshold prompts ────────────────────────────────

ask_threshold_pct() {
  local label="$1"
  local current="$2"
  local default="$3"
  local choice

  local enter_value
  if [ "$HAS_CONFIG" = "1" ]; then
    enter_value="$current"
  else
    enter_value="$default"
  fi

  echo "" >&2
  echo "  $label" >&2
  echo "    current = ${current}%" >&2
  echo "    default = ${default}%" >&2
  while true; do
    read -rp "    value [0-100, q, Enter=${enter_value}%]: " choice
    choice="${choice:-$enter_value}"
    if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
      echo "QUIT"
      return
    fi
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le 100 ]; then
      echo "$choice"
      return
    fi
    echo "    Invalid. Enter a number 0-100 or q." >&2
  done
}

ask_threshold_usd() {
  local label="$1"
  local current="$2"
  local default="$3"
  local choice

  local enter_value
  if [ "$HAS_CONFIG" = "1" ]; then
    enter_value="$current"
  else
    enter_value="$default"
  fi

  echo "" >&2
  echo "  $label" >&2
  echo "    current = \$$current" >&2
  echo "    default = \$$default" >&2
  while true; do
    read -rp "    value [\$amount, q, Enter=\$$enter_value]: " choice
    choice="${choice:-$enter_value}"
    if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
      echo "QUIT"
      return
    fi
    # Validate: positive number, decimals ok
    if [[ "$choice" =~ ^[0-9]+\.?[0-9]*$ ]] && [ "$(echo "$choice > 0" | bc -l 2>/dev/null || awk "BEGIN{print ($choice+0 > 0)}")" = "1" ]; then
      echo "$choice"
      return
    fi
    echo "    Invalid. Enter a positive number or q." >&2
  done
}

# ── Write config ─────────────────────────────────────

write_conf() {
  cat > "$CONF_FILE" << EOF
# ── User preferences (edit these) ────────────────
# Widgets to display (1=on, 0=off)
SHOW_PROGRESS=$SHOW_PROGRESS
SHOW_TOKENS=$SHOW_TOKENS
SHOW_COST=$SHOW_COST
SHOW_RATELIMIT=$SHOW_RATELIMIT
SHOW_MODEL=$SHOW_MODEL

# Colors (ANSI escape codes)
C_ACCENT='$C_ACCENT'
C_WARN='$C_WARN'
C_DANGER='$C_DANGER'
C_DIM='$C_DIM'

# Thresholds (ordered to match widget display order)
CONTEXT_WARN_PCT=$CONTEXT_WARN_PCT
CONTEXT_DANGER_PCT=$CONTEXT_DANGER_PCT
COST_WARN_USD=$COST_WARN_USD
COST_DANGER_USD=$COST_DANGER_USD
RATE_WARN_PCT=$RATE_WARN_PCT
RATE_DANGER_PCT=$RATE_DANGER_PCT

# ── Auto-managed (do not edit) ───────────────────
XIDA_RATE=$XIDA_RATE
XIDA_RATE_EPOCH=$XIDA_RATE_EPOCH
EOF
}

# ── Install / Uninstall ──────────────────────────────

do_install() {
  # Warn if existing statusLine is set (and it's not ours)
  local current
  current=$(get_current_statusline)
  if [ -n "$current" ] && ! is_installed; then
    echo ""
    echo "  WARNING: An existing statusLine is configured:"
    echo "    $current"
    echo ""
    echo "  Installing will replace it."
    echo ""
    read -rp "  Continue? [y/N]: " confirm
    case "$confirm" in
      y|Y|yes|YES) ;;
      *)
        echo ""
        echo "  Cancelled."
        read -rp "  Press Enter to close..."
        exit 0
        ;;
    esac
    echo ""
  fi

  # Ensure settings.json exists
  if [ ! -f "$SETTINGS" ]; then
    mkdir -p "$(dirname "$SETTINGS")"
    echo '{}' > "$SETTINGS"
  fi

  # Write statusLine entry
  local tmp
  tmp=$(mktemp)
  jq --arg cmd "$STATUSLINE_CMD" '.statusLine = {"type": "command", "command": $cmd}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
}

do_uninstall() {
  # Remove settings.json entry
  if [ -f "$SETTINGS" ]; then
    local tmp
    tmp=$(mktemp)
    jq 'del(.statusLine)' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  fi

  # Remove config file
  rm -f "$CONF_FILE"

  echo ""
  echo "========================================"
  echo "  Statusline uninstalled"
  echo "========================================"
  echo ""
  echo "  statusLine removed from settings.json."
  echo "  Config file deleted."
  echo "  Re-run /xida:statusline to install again."
  echo ""
  read -rp "  Press Enter to close..."
  exit 0
}

# ── Preview ──────────────────────────────────────────

show_preview() {
  local C_RESET='\033[0m'
  local parts=()

  if [ "$SHOW_PROGRESS" = "1" ]; then
    parts+=("$(printf '%b████░░░░░░ 45%%%b' "$C_ACCENT" "$C_RESET")")
  fi

  if [ "$SHOW_TOKENS" = "1" ]; then
    parts+=("$(printf '%b90K%b%b/200K%b' "$C_ACCENT" "$C_RESET" "$C_DIM" "$C_RESET")")
  fi

  if [ "$SHOW_COST" = "1" ]; then
    parts+=("$(printf '%b$3.50%b' "$C_ACCENT" "$C_RESET")")
  fi

  if [ "$SHOW_RATELIMIT" = "1" ]; then
    parts+=("$(printf '%b5h: %b%b23%%%b %b(2h)%b' "$C_DIM" "$C_RESET" "$C_ACCENT" "$C_RESET" "$C_DIM" "$C_RESET")")
  fi

  if [ "$SHOW_MODEL" = "1" ]; then
    parts+=("$(printf '%bOpus 4.6%b' "$C_ACCENT" "$C_RESET")")
  fi

  echo ""
  echo "  Preview:"
  printf '    '
  local sep
  sep=$(printf ' %b│%b ' "$C_DIM" "$C_RESET")
  local first=1
  for part in "${parts[@]}"; do
    if [ "$first" = "0" ]; then
      printf '%b' "$sep"
    fi
    printf '%b' "$part"
    first=0
  done
  printf '\n'
  echo ""
}

# ── Main flow ────────────────────────────────────────

show_header
show_current

ACTION=$(ask_action)
case "$ACTION" in
  quit)
    echo ""
    echo "  Quit."
    read -rp "  Press Enter to close..."
    exit 0
    ;;
  uninstall)
    do_uninstall
    ;;
esac

# ── Configure widgets ────────────────────────────────

echo ""
echo "── Widgets ──────────────────────────────"
if [ "$HAS_CONFIG" = "1" ]; then
  echo "  (Enter=keep current)"
else
  echo "  (Enter=use default)"
fi

SHOW_PROGRESS=$(ask_widget "Progress bar (context usage)" "$SHOW_PROGRESS" "$DEFAULT_SHOW_PROGRESS")
quit_if_asked "$SHOW_PROGRESS"

SHOW_TOKENS=$(ask_widget "Token count (current/max)" "$SHOW_TOKENS" "$DEFAULT_SHOW_TOKENS")
quit_if_asked "$SHOW_TOKENS"

SHOW_COST=$(ask_widget "Session cost" "$SHOW_COST" "$DEFAULT_SHOW_COST")
quit_if_asked "$SHOW_COST"

SHOW_RATELIMIT=$(ask_widget "Rate limit (5h/7d usage)" "$SHOW_RATELIMIT" "$DEFAULT_SHOW_RATELIMIT")
quit_if_asked "$SHOW_RATELIMIT"

SHOW_MODEL=$(ask_widget "Model name" "$SHOW_MODEL" "$DEFAULT_SHOW_MODEL")
quit_if_asked "$SHOW_MODEL"

# ── Color theme ──────────────────────────────────────

CHOSEN_THEME=$(ask_theme)
quit_if_asked "$CHOSEN_THEME"

C_ACCENT="${THEME_ACCENT[$CHOSEN_THEME]}"
C_WARN="${THEME_WARN[$CHOSEN_THEME]}"
C_DANGER="${THEME_DANGER[$CHOSEN_THEME]}"
C_DIM="${THEME_DIM[$CHOSEN_THEME]}"

# ── Thresholds ───────────────────────────────────────

echo ""
echo "── Thresholds ───────────────────────────"
if [ "$HAS_CONFIG" = "1" ]; then
  echo "  (Enter=keep current)"
else
  echo "  (Enter=use default)"
fi

CONTEXT_WARN_PCT=$(ask_threshold_pct "Context warn %" "$CONTEXT_WARN_PCT" "$DEFAULT_CONTEXT_WARN_PCT")
quit_if_asked "$CONTEXT_WARN_PCT"

CONTEXT_DANGER_PCT=$(ask_threshold_pct "Context danger %" "$CONTEXT_DANGER_PCT" "$DEFAULT_CONTEXT_DANGER_PCT")
quit_if_asked "$CONTEXT_DANGER_PCT"

# Auto-swap if warn > danger
if [ "$CONTEXT_WARN_PCT" -gt "$CONTEXT_DANGER_PCT" ]; then
  echo "    (swapped: warn=$CONTEXT_DANGER_PCT%, danger=$CONTEXT_WARN_PCT%)" >&2
  tmp_val="$CONTEXT_WARN_PCT"
  CONTEXT_WARN_PCT="$CONTEXT_DANGER_PCT"
  CONTEXT_DANGER_PCT="$tmp_val"
fi

COST_WARN_USD=$(ask_threshold_usd "Cost warn \$" "$COST_WARN_USD" "$DEFAULT_COST_WARN_USD")
quit_if_asked "$COST_WARN_USD"

COST_DANGER_USD=$(ask_threshold_usd "Cost danger \$" "$COST_DANGER_USD" "$DEFAULT_COST_DANGER_USD")
quit_if_asked "$COST_DANGER_USD"

# Auto-swap if warn > danger
if awk "BEGIN{exit(!($COST_WARN_USD+0 > $COST_DANGER_USD+0))}" 2>/dev/null; then
  echo "    (swapped: warn=\$$COST_DANGER_USD, danger=\$$COST_WARN_USD)" >&2
  tmp_val="$COST_WARN_USD"
  COST_WARN_USD="$COST_DANGER_USD"
  COST_DANGER_USD="$tmp_val"
fi

RATE_WARN_PCT=$(ask_threshold_pct "Rate limit warn %" "$RATE_WARN_PCT" "$DEFAULT_RATE_WARN_PCT")
quit_if_asked "$RATE_WARN_PCT"

RATE_DANGER_PCT=$(ask_threshold_pct "Rate limit danger %" "$RATE_DANGER_PCT" "$DEFAULT_RATE_DANGER_PCT")
quit_if_asked "$RATE_DANGER_PCT"

# Auto-swap if warn > danger
if [ "$RATE_WARN_PCT" -gt "$RATE_DANGER_PCT" ]; then
  echo "    (swapped: warn=$RATE_DANGER_PCT%, danger=$RATE_WARN_PCT%)" >&2
  tmp_val="$RATE_WARN_PCT"
  RATE_WARN_PCT="$RATE_DANGER_PCT"
  RATE_DANGER_PCT="$tmp_val"
fi

# ── Write config and install ─────────────────────────

write_conf
do_install

echo ""
echo "========================================"
echo "  Configuration saved!"
echo "========================================"
echo ""
show_current
show_preview

echo "  You can also edit statusline.conf directly for"
echo "  custom colors or fine-tuned values. Changes"
echo "  apply on next render — no restart needed."
echo ""
echo "  Re-run /xida:statusline to update or uninstall."
echo ""
read -rp "  Press Enter to close..."
