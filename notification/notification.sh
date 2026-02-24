#!/usr/bin/env bash
# Cross-platform notification script for Claude Code events.
# Called by plugin hooks with event name as $1.
# Sources notification.conf for settings; exits silently if unconfigured.

set -euo pipefail

EVENT="${1:-}"
[ -z "$EVENT" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$HOME/.config/xida/notification.conf"

# No config = unconfigured = silent exit
[ -f "$CONF" ] || exit 0
. "$CONF"

# Look up sound and flash for this event
case "$EVENT" in
  stop)           SOUND="${STOP_SOUND:-0}";           FLASH="${STOP_FLASH:-0}" ;;
  notification)   SOUND="${NOTIFICATION_SOUND:-0}";   FLASH="${NOTIFICATION_FLASH:-0}" ;;
  task_complete)  SOUND="${TASK_COMPLETE_SOUND:-0}";   FLASH=0 ;;
  subagent_stop)  SOUND="${SUBAGENT_STOP_SOUND:-0}";   FLASH=0 ;;
  *)              exit 0 ;;
esac

# Nothing to do
[ "$SOUND" = "0" ] && [ "$FLASH" = "0" ] && exit 0

# ── Sound maps ───────────────────────────────────────

play_sound_windows() {
  local file
  case "$SOUND" in
    1) file="ding.wav" ;;
    2) file="chimes.wav" ;;
    3) file="Windows Exclamation.wav" ;;
    4) file="notify.wav" ;;
    5) file="chord.wav" ;;
    6) file="Windows Proximity Notification.wav" ;;
    7) file="tada.wav" ;;
    *) return ;;
  esac
  powershell -NoProfile -Command "(New-Object Media.SoundPlayer 'C:\Windows\Media\\$file').PlaySync()" 2>/dev/null || true
}

play_sound_macos() {
  local file
  case "$SOUND" in
    1) file="Tink" ;;
    2) file="Glass" ;;
    3) file="Ping" ;;
    4) file="Purr" ;;
    5) file="Hero" ;;
    6) file="Submarine" ;;
    7) file="Sosumi" ;;
    *) return ;;
  esac
  afplay "/System/Library/Sounds/${file}.aiff" 2>/dev/null || true
}

play_sound_linux() {
  local file
  case "$SOUND" in
    1) file="message-new-instant.oga" ;;
    2) file="complete.oga" ;;
    3) file="dialog-warning.oga" ;;
    4) file="bell.oga" ;;
    5) file="service-login.oga" ;;
    6) file="phone-incoming-call.oga" ;;
    7) file="dialog-information.oga" ;;
    *) return ;;
  esac
  local path="/usr/share/sounds/freedesktop/stereo/$file"
  if [ -f "$path" ]; then
    if command -v paplay &>/dev/null; then
      paplay "$path" 2>/dev/null || true
    elif command -v aplay &>/dev/null; then
      aplay "$path" 2>/dev/null || true
    fi
  fi
}

# ── Taskbar flash (Windows only) ─────────────────────

flash_taskbar_windows() {
  [ "$FLASH" = "1" ] || return 0
  powershell -NoProfile -Command '
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public struct FLASHWINFO {
    public uint cbSize; public IntPtr hwnd; public uint dwFlags;
    public uint uCount; public uint dwTimeout;
}
public static class FlashWindow {
    [DllImport("user32.dll")] public static extern bool FlashWindowEx(ref FLASHWINFO pwfi);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
    public static void Flash(IntPtr hwnd, uint count) {
        if (hwnd == GetForegroundWindow()) return;
        FLASHWINFO fw = new FLASHWINFO();
        fw.cbSize = (uint)System.Runtime.InteropServices.Marshal.SizeOf(typeof(FLASHWINFO));
        fw.hwnd = hwnd; fw.dwFlags = 3; fw.uCount = count; fw.dwTimeout = 0;
        FlashWindowEx(ref fw);
    }
}
"@
$parentOf = @{}
Get-CimInstance Win32_Process -Property ProcessId,ParentProcessId |
  ForEach-Object { $parentOf[[int]$_.ProcessId] = [int]$_.ParentProcessId }
$hwnd = [IntPtr]::Zero; $id = $PID
while ($id -and $id -ne 0) {
    $proc = Get-Process -Id $id -ErrorAction SilentlyContinue
    if ($proc) { $h = $proc.MainWindowHandle
        if ($h -ne [IntPtr]::Zero -and [FlashWindow]::IsWindowVisible($h)) { $hwnd = $h; break } }
    $id = $parentOf[$id]
}
if ($hwnd -ne [IntPtr]::Zero) { [FlashWindow]::Flash($hwnd, 3) }
' 2>/dev/null || true
}

# ── Desktop notification (macOS/Linux) ───────────────

show_notification_macos() {
  local msg
  case "$EVENT" in
    stop)          msg="Claude finished responding" ;;
    notification)  msg="Claude needs your attention" ;;
    task_complete) msg="Task completed" ;;
    subagent_stop) msg="Subagent finished" ;;
    *)             msg="Event: $EVENT" ;;
  esac
  osascript -e "display notification \"$msg\" with title \"Claude Code\"" 2>/dev/null || true
}

show_notification_linux() {
  command -v notify-send &>/dev/null || return 0
  local msg
  case "$EVENT" in
    stop)          msg="Claude finished responding" ;;
    notification)  msg="Claude needs your attention" ;;
    task_complete) msg="Task completed" ;;
    subagent_stop) msg="Subagent finished" ;;
    *)             msg="Event: $EVENT" ;;
  esac
  notify-send "Claude Code" "$msg" 2>/dev/null || true
}

# ── Dispatch by platform ────────────────────────────

case "$OSTYPE" in
  msys*|cygwin*|MSYS*|CYGWIN*)
    [ "$SOUND" != "0" ] && play_sound_windows
    flash_taskbar_windows
    ;;
  darwin*)
    [ "$SOUND" != "0" ] && play_sound_macos
    show_notification_macos
    ;;
  linux-gnu*)
    [ "$SOUND" != "0" ] && play_sound_linux
    show_notification_linux
    ;;
esac

exit 0
