#!/usr/bin/env bash
# Interactive notification setup for Claude Code xida plugin.
# Detects platform, presents sound/flash options, writes notification.conf.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$SCRIPT_DIR/notification.conf"

# ── Detect platform ─────────────────────────────────

case "$OSTYPE" in
  msys*|cygwin*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
  darwin*)                      PLATFORM="macos" ;;
  linux-gnu*)                   PLATFORM="linux" ;;
  *)
    echo "Unsupported platform: $OSTYPE"
    read -rp "Press Enter to exit..."
    exit 1
    ;;
esac

# ── Sound maps per platform ─────────────────────────

declare -a SOUND_NAMES
case "$PLATFORM" in
  windows)
    SOUND_NAMES=(
      "ding.wav"
      "chimes.wav"
      "Windows Exclamation.wav"
      "notify.wav"
      "chord.wav"
      "Windows Proximity Notification.wav"
      "tada.wav"
    )
    ;;
  macos)
    SOUND_NAMES=(
      "Tink"
      "Glass"
      "Ping"
      "Purr"
      "Hero"
      "Submarine"
      "Sosumi"
    )
    ;;
  linux)
    SOUND_NAMES=(
      "message-new-instant.oga"
      "complete.oga"
      "dialog-warning.oga"
      "bell.oga"
      "service-login.oga"
      "phone-incoming-call.oga"
      "dialog-information.oga"
    )
    ;;
esac

# ── Sound preview ────────────────────────────────────

play_preview() {
  local idx="$1"
  local name="${SOUND_NAMES[$((idx - 1))]}"
  case "$PLATFORM" in
    windows)
      powershell -NoProfile -Command "(New-Object Media.SoundPlayer 'C:\Windows\Media\\$name').PlaySync()" 2>/dev/null || true
      ;;
    macos)
      afplay "/System/Library/Sounds/${name}.aiff" 2>/dev/null || true
      ;;
    linux)
      local path="/usr/share/sounds/freedesktop/stereo/$name"
      if [ -f "$path" ]; then
        if command -v paplay &>/dev/null; then paplay "$path" 2>/dev/null || true
        elif command -v aplay &>/dev/null; then aplay "$path" 2>/dev/null || true
        fi
      else
        echo "  (sound file not found: $path)"
      fi
      ;;
  esac
}

# ── UI helpers ───────────────────────────────────────

show_header() {
  clear 2>/dev/null || true
  echo "========================================"
  echo "  Claude Code Notification Setup"
  echo "  Platform: $PLATFORM"
  echo "========================================"
  echo ""
}

sound_label() {
  local idx="$1"
  if [ "$idx" = "0" ]; then echo "0) Off"
  else echo "$idx) ${SOUND_NAMES[$((idx - 1))]}"
  fi
}

flash_label() {
  if [ "$1" = "1" ]; then echo "on"; else echo "off"; fi
}

show_sounds() {
  echo "Available sounds:"
  echo ""
  echo "  0) Off (no sound)"
  for i in "${!SOUND_NAMES[@]}"; do
    echo "  $((i + 1))) ${SOUND_NAMES[$i]}"
  done
  echo ""
  echo "  p) Preview all sounds"
  echo ""
}

# ── Defaults (before config override) ─────────────────

DEFAULT_STOP_SOUND=2
DEFAULT_NOTIFICATION_SOUND=3
DEFAULT_TASK_COMPLETE_SOUND=1
DEFAULT_SUBAGENT_STOP_SOUND=0
DEFAULT_STOP_FLASH=1
DEFAULT_NOTIFICATION_FLASH=1

show_current() {
  echo "Current settings:"
  echo ""
  printf "  %-20s %s\n" "Stop:"             "$(sound_label "$STOP_SOUND")"
  printf "  %-20s %s\n" "Notification:"     "$(sound_label "$NOTIFICATION_SOUND")"
  printf "  %-20s %s\n" "Task Complete:"    "$(sound_label "$TASK_COMPLETE_SOUND")"
  printf "  %-20s %s\n" "Subagent Stop:"    "$(sound_label "$SUBAGENT_STOP_SOUND")"
  if [ "$PLATFORM" = "windows" ]; then
    printf "  %-20s %s\n" "Stop flash:"       "$(flash_label "$STOP_FLASH")"
    printf "  %-20s %s\n" "Notification flash:" "$(flash_label "$NOTIFICATION_FLASH")"
  fi
  echo ""
}

ask_sound() {
  local event_label="$1"
  local current="$2"
  local default="$3"
  local choice
  echo "" >&2
  echo "  $event_label" >&2
  echo "    current: $(sound_label "$current")" >&2
  echo "    default: $(sound_label "$default")" >&2
  while true; do
    read -rp "    choice [0-7, p, Enter=keep]: " choice
    choice="${choice:-$current}"
    if [ "$choice" = "p" ]; then
      echo "" >&2
      for i in $(seq 1 ${#SOUND_NAMES[@]}); do
        printf "      %d) %s " "$i" "${SOUND_NAMES[$((i - 1))]}" >&2
        play_preview "$i"
        sleep 0.3
        echo "" >&2
      done
      echo "" >&2
      continue
    fi
    if [[ "$choice" =~ ^[0-7]$ ]]; then
      echo "$choice"
      return
    fi
    echo "    Invalid choice. Enter 0-7 or p." >&2
  done
}

ask_flash() {
  local event_label="$1"
  local current="$2"
  local default="$3"
  local choice
  echo "" >&2
  echo "  $event_label" >&2
  echo "    current: $(flash_label "$current")" >&2
  echo "    default: $(flash_label "$default")" >&2
  read -rp "    choice [y/n, Enter=keep]: " choice
  choice="${choice:-$([ "$current" = "1" ] && echo y || echo n)}"
  case "$choice" in
    y|Y|yes|YES) echo "1" ;;
    *)           echo "0" ;;
  esac
}

# ── Load existing config ─────────────────────────────

STOP_SOUND=$DEFAULT_STOP_SOUND
NOTIFICATION_SOUND=$DEFAULT_NOTIFICATION_SOUND
TASK_COMPLETE_SOUND=$DEFAULT_TASK_COMPLETE_SOUND
SUBAGENT_STOP_SOUND=$DEFAULT_SUBAGENT_STOP_SOUND
STOP_FLASH=$DEFAULT_STOP_FLASH
NOTIFICATION_FLASH=$DEFAULT_NOTIFICATION_FLASH

if [ -f "$CONF" ]; then
  . "$CONF"
fi

# ── Main flow ────────────────────────────────────────

show_header
show_current
show_sounds

echo "── Sound per event ──────────────────────"
echo "  (0=off, 1-7=sound, Enter=keep current)"
STOP_SOUND=$(ask_sound "Stop (Claude finished)" "$STOP_SOUND" "$DEFAULT_STOP_SOUND")
NOTIFICATION_SOUND=$(ask_sound "Notification (needs attention)" "$NOTIFICATION_SOUND" "$DEFAULT_NOTIFICATION_SOUND")
TASK_COMPLETE_SOUND=$(ask_sound "Task Complete" "$TASK_COMPLETE_SOUND" "$DEFAULT_TASK_COMPLETE_SOUND")
SUBAGENT_STOP_SOUND=$(ask_sound "Subagent Stop" "$SUBAGENT_STOP_SOUND" "$DEFAULT_SUBAGENT_STOP_SOUND")

if [ "$PLATFORM" = "windows" ]; then
  echo ""
  echo "── Taskbar flash per event ────────────"
  echo "  (Enter=keep current)"
  STOP_FLASH=$(ask_flash "Stop" "$STOP_FLASH" "$DEFAULT_STOP_FLASH")
  NOTIFICATION_FLASH=$(ask_flash "Notification" "$NOTIFICATION_FLASH" "$DEFAULT_NOTIFICATION_FLASH")
fi

# ── Write config ─────────────────────────────────────

cat > "$CONF" << EOF
# Claude Code notification config -- generated by setup.sh
# Sound per event (0=off, 1-7=sound index)
STOP_SOUND=$STOP_SOUND
NOTIFICATION_SOUND=$NOTIFICATION_SOUND
TASK_COMPLETE_SOUND=$TASK_COMPLETE_SOUND
SUBAGENT_STOP_SOUND=$SUBAGENT_STOP_SOUND

# Taskbar flash per event (0=off, 1=on, Windows only)
STOP_FLASH=$STOP_FLASH
NOTIFICATION_FLASH=$NOTIFICATION_FLASH
EOF

echo ""
echo "========================================"
echo "  Configuration saved!"
echo "  File: $CONF"
echo "========================================"
echo ""
echo "Notifications are now active. Re-run /xida:notification to change settings."
echo ""
read -rp "Press Enter to close..."
