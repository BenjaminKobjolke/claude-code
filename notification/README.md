# Notification System

Cross-platform notification sounds and taskbar flash for Claude Code events.

## Quick Start

Run `/xida:notification` inside Claude Code. This opens an interactive setup in a new terminal. On first run you can install (configure sounds and flash per event). On subsequent runs you can update settings or uninstall (removes config, silences all notifications). Notifications are silent until you run setup.

## How It Works

The plugin registers four hooks in `hooks/hooks.json`. Each hook fires asynchronously (non-blocking) and calls `notification.sh` with the event name. The script sources `notification.conf` for user preferences, then plays a sound and/or flashes the taskbar based on the configuration.

If `notification.conf` does not exist, every hook exits silently in ~1ms.

## Hooks

| Hook | When it fires | Use case |
|------|---------------|----------|
| **Stop** | Claude finishes responding | Know when a long response is done |
| **Notification** | Claude needs your attention (permission prompt, idle, etc.) | Don't miss permission dialogs while multitasking |
| **TaskCompleted** | A task is marked complete | Track progress on multi-step work |
| **SubagentStop** | A subagent finishes its work | Monitor background agent activity |

All hooks run with `async: true` and a 5-second timeout, so they never block Claude's execution.

## Files

| File | Purpose |
|------|---------|
| `notification.sh` | Main script called by hooks. Detects OS, plays sound, flashes taskbar. |
| `setup.sh` | Interactive setup. Install/update/uninstall flow with sound preview, quit support, and sensible first-run defaults. Writes `notification.conf`. |
| `notification.conf` | User config (gitignored). Created by `setup.sh`. |

## Platform Support

| Feature | Windows | macOS | Linux |
|---------|---------|-------|-------|
| Sound playback | PowerShell + `C:\Windows\Media\` sounds | `afplay` + system sounds | `paplay`/`aplay` + freedesktop sounds |
| Taskbar flash | Win32 `FlashWindowEx` | -- | -- |
| Desktop notification | -- | `osascript` display notification | `notify-send` |

## Sound Options

Each event can be set to one of 7 sounds (or 0 for off):

| Index | Windows | macOS | Linux |
|-------|---------|-------|-------|
| 0 | Off | Off | Off |
| 1 | ding.wav | Tink | message-new-instant.oga |
| 2 | chimes.wav | Glass | complete.oga |
| 3 | Windows Exclamation.wav | Ping | dialog-warning.oga |
| 4 | notify.wav | Purr | bell.oga |
| 5 | chord.wav | Hero | service-login.oga |
| 6 | Windows Proximity Notification.wav | Submarine | phone-incoming-call.oga |
| 7 | tada.wav | Sosumi | dialog-information.oga |

## Configuration

`notification.conf` is a sourceable shell file with 6 variables:

```bash
# Sound per event (0=off, 1-7=sound index)
STOP_SOUND=2
NOTIFICATION_SOUND=3
TASK_COMPLETE_SOUND=1
SUBAGENT_STOP_SOUND=0

# Taskbar flash per event (0=off, 1=on, Windows only)
STOP_FLASH=1
NOTIFICATION_FLASH=1
```

You can edit this file directly or re-run `/xida:notification` to use the interactive setup.
