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
  if [ "$idx" = "0" ]; then echo "0: Off"
  else echo "$idx: ${SOUND_NAMES[$((idx - 1))]}"
  fi
}

flash_label() {
  if [ "$1" = "1" ]; then echo "y: on"; else echo "n: off"; fi
}

show_sounds() {
  echo "Available sounds:"
  echo ""
  echo "  0: Off (no sound)"
  for i in "${!SOUND_NAMES[@]}"; do
    echo "  $((i + 1)): ${SOUND_NAMES[$i]}"
  done
  echo ""
  echo "  p: Preview all sounds"
  echo "  q: Quit without saving"
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
  # First run: Enter uses default; subsequent runs: Enter uses current
  local enter_value
  if [ "$HAS_CONFIG" = "1" ]; then
    enter_value="$current"
  else
    enter_value="$default"
  fi
  echo "" >&2
  echo "  $event_label" >&2
  echo "    current = $(sound_label "$current")" >&2
  echo "    default = $(sound_label "$default")" >&2
  while true; do
    read -rp "    choice [0-7, p, q, Enter=$(sound_label "$enter_value")]: " choice
    choice="${choice:-$enter_value}"
    if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
      echo "QUIT"
      return
    fi
    if [ "$choice" = "p" ]; then
      echo "" >&2
      for i in $(seq 1 ${#SOUND_NAMES[@]}); do
        printf "      %d: %s " "$i" "${SOUND_NAMES[$((i - 1))]}" >&2
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
    echo "    Invalid choice. Enter 0-7, p, or q." >&2
  done
}

ask_flash() {
  local event_label="$1"
  local current="$2"
  local default="$3"
  local choice
  # First run: Enter uses default; subsequent runs: Enter uses current
  local enter_value
  if [ "$HAS_CONFIG" = "1" ]; then
    enter_value="$current"
  else
    enter_value="$default"
  fi
  echo "" >&2
  echo "  $event_label" >&2
  echo "    current = $(flash_label "$current")" >&2
  echo "    default = $(flash_label "$default")" >&2
  read -rp "    choice [y=on / n=off / q=quit, Enter=$([ "$enter_value" = "1" ] && echo y || echo n)]: " choice
  choice="${choice:-$([ "$enter_value" = "1" ] && echo y || echo n)}"
  if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
    echo "QUIT"
    return
  fi
  case "$choice" in
    y|Y|yes|YES) echo "1" ;;
    *)           echo "0" ;;
  esac
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

# ── Load existing config ─────────────────────────────

# Fresh install: all values start at 0 (unconfigured)
STOP_SOUND=0
NOTIFICATION_SOUND=0
TASK_COMPLETE_SOUND=0
SUBAGENT_STOP_SOUND=0
STOP_FLASH=0
NOTIFICATION_FLASH=0

# Track whether a config file exists (first run vs subsequent)
HAS_CONFIG=0
if [ -f "$CONF" ]; then
  HAS_CONFIG=1
  . "$CONF"
fi

# ── Action prompt ─────────────────────────────────────

ask_action() {
  echo "── What would you like to do? ───────────" >&2
  echo "" >&2
  if [ "$HAS_CONFIG" = "1" ]; then
    echo "  1: Update settings" >&2
    echo "     Change sound and flash preferences" >&2
    echo "     for each notification event." >&2
    echo "" >&2
    echo "  u: Uninstall" >&2
    echo "     Remove configuration file and silence" >&2
    echo "     all notification sounds and flashes." >&2
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
    echo "     Configure notification sounds and" >&2
    echo "     taskbar flash for Claude Code events." >&2
    echo "     (Stop, Notification, Task Complete," >&2
    echo "      Subagent Stop)" >&2
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

do_uninstall() {
  rm -f "$CONF"
  echo ""
  echo "========================================"
  echo "  Notifications uninstalled"
  echo "========================================"
  echo ""
  echo "Config removed. Notification hooks will now exit silently."
  echo "Re-run /xida:notification to set up again."
  echo ""
  read -rp "Press Enter to close..."
  exit 0
}

# ── Main flow ────────────────────────────────────────

show_header
show_current

ACTION=$(ask_action)
case "$ACTION" in
  quit)
    echo ""
    echo "Quit."
    read -rp "Press Enter to close..."
    exit 0
    ;;
  uninstall)
    do_uninstall
    ;;
esac

# ── Configure sounds ──────────────────────────────────

show_sounds

echo "── Sound per event ──────────────────────"
if [ "$HAS_CONFIG" = "1" ]; then
  echo "  (0=off, 1-7=sound, Enter=keep current)"
else
  echo "  (0=off, 1-7=sound, Enter=use default)"
fi
STOP_SOUND=$(ask_sound "Stop (Claude finished)" "$STOP_SOUND" "$DEFAULT_STOP_SOUND")
quit_if_asked "$STOP_SOUND"
NOTIFICATION_SOUND=$(ask_sound "Notification (needs attention)" "$NOTIFICATION_SOUND" "$DEFAULT_NOTIFICATION_SOUND")
quit_if_asked "$NOTIFICATION_SOUND"
TASK_COMPLETE_SOUND=$(ask_sound "Task Complete" "$TASK_COMPLETE_SOUND" "$DEFAULT_TASK_COMPLETE_SOUND")
quit_if_asked "$TASK_COMPLETE_SOUND"
SUBAGENT_STOP_SOUND=$(ask_sound "Subagent Stop" "$SUBAGENT_STOP_SOUND" "$DEFAULT_SUBAGENT_STOP_SOUND")
quit_if_asked "$SUBAGENT_STOP_SOUND"

if [ "$PLATFORM" = "windows" ]; then
  echo ""
  echo "── Taskbar flash per event ────────────"
  if [ "$HAS_CONFIG" = "1" ]; then
    echo "  (Enter=keep current)"
  else
    echo "  (Enter=use default)"
  fi
  STOP_FLASH=$(ask_flash "Stop" "$STOP_FLASH" "$DEFAULT_STOP_FLASH")
  quit_if_asked "$STOP_FLASH"
  NOTIFICATION_FLASH=$(ask_flash "Notification" "$NOTIFICATION_FLASH" "$DEFAULT_NOTIFICATION_FLASH")
  quit_if_asked "$NOTIFICATION_FLASH"
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
echo "========================================"
echo ""
show_current
echo "Notifications are now active. Re-run /xida:notification to change settings."
echo ""
read -rp "Press Enter to close..."
