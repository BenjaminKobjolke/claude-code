#!/usr/bin/env bash
# Interactive statusline setup for Claude Code xida plugin.
# Installs/uninstalls statusline by modifying ~/.claude/settings.json.

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

# ── Config file generation ───────────────────────────

generate_default_conf() {
  [ -f "$CONF_FILE" ] && return
  cat > "$CONF_FILE" << 'EOF'
# ── User preferences (edit these) ────────────────
# Widgets to display (1=on, 0=off)
SHOW_PROGRESS=1
SHOW_TOKENS=1
SHOW_COST=1
SHOW_RATELIMIT=1
SHOW_MODEL=1

# Colors (ANSI escape codes)
C_ACCENT='\033[36m'
C_WARN='\033[33m'
C_DANGER='\033[31m'
C_DIM='\033[38;5;245m'

# Thresholds (ordered to match widget display order)
CONTEXT_WARN_PCT=60
CONTEXT_DANGER_PCT=80
COST_WARN_USD=5
COST_DANGER_USD=10
RATE_WARN_PCT=50
RATE_DANGER_PCT=80

# ── Auto-managed (do not edit) ───────────────────
XIDA_RATE=1
XIDA_RATE_EPOCH=0
EOF
}

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

# ── Install / Uninstall ──────────────────────────────

do_install() {
  # Warn if existing statusLine is set (and it's not ours)
  local current
  current=$(get_current_statusline)
  if [ -n "$current" ] && ! is_installed; then
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

  # Generate default config file if missing
  generate_default_conf

  # Ensure settings.json exists
  if [ ! -f "$SETTINGS" ]; then
    mkdir -p "$(dirname "$SETTINGS")"
    echo '{}' > "$SETTINGS"
  fi

  # Write statusLine entry
  local tmp
  tmp=$(mktemp)
  jq --arg cmd "$STATUSLINE_CMD" '.statusLine = {"type": "command", "command": $cmd}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"

  echo "========================================"
  echo "  Statusline installed!"
  echo "========================================"
  echo ""
  echo "  Command: $STATUSLINE_CMD"
  echo ""
  echo "  Restart Claude Code for changes to take effect."
  echo "  Re-run /xida:statusline to update or uninstall."
  echo ""
  read -rp "  Press Enter to close..."
}

do_uninstall() {
  local tmp
  tmp=$(mktemp)
  jq 'del(.statusLine)' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"

  echo ""
  echo "========================================"
  echo "  Statusline uninstalled"
  echo "========================================"
  echo ""
  echo "  statusLine removed from settings.json."
  echo "  Restart Claude Code for changes to take effect."
  echo "  Re-run /xida:statusline to install again."
  echo ""
  read -rp "  Press Enter to close..."
  exit 0
}

# ── Action prompt ────────────────────────────────────

ask_action() {
  echo "── What would you like to do? ───────────" >&2
  echo "" >&2
  if is_installed; then
    echo "  1: Update (reinstall)" >&2
    echo "     Refresh the statusLine path in" >&2
    echo "     settings.json." >&2
    echo "" >&2
    echo "  u: Uninstall" >&2
    echo "     Remove statusLine from settings.json." >&2
    echo "" >&2
    echo "  q: Quit without changes" >&2
    echo "" >&2
    while true; do
      read -rp "  choice [1, u, q, Enter=update]: " action
      action="${action:-1}"
      case "$action" in
        1) echo "install"; return ;;
        u|U) echo "uninstall"; return ;;
        q|Q) echo "quit"; return ;;
        *) echo "  Invalid choice. Enter 1, u, or q." >&2 ;;
      esac
    done
  else
    echo "  1: Install" >&2
    echo "     Configure the xida statusline" >&2
    echo "     as your Claude Code status bar." >&2
    echo "     Shows: Model, Context %, Tokens," >&2
    echo "     Cost, Rate Limits (5h/7d)" >&2
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

# ── Main flow ────────────────────────────────────────

show_header

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
  install)
    do_install
    ;;
esac
