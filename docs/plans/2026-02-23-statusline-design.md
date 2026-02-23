# Statusline Plugin Design

**Date:** 2026-02-23
**Status:** Approved

## Overview

A status line system for Claude Code that displays model info, context usage, cost, and rate limits. Mirrors the notification system's streamlined architecture: a runtime script, an interactive setup, and a slash command.

## Files

```
statusline/
  statusline.sh   — Runtime script (reads JSON from stdin, outputs ANSI status line)
  setup.sh        — Interactive install/uninstall (modifies ~/.claude/settings.json)
  README.md       — Documentation
commands/
  statusline.md   — Slash command (launches setup.sh in a new terminal)
```

## Widget Architecture

`statusline.sh` uses a widget-based design where each widget is a standalone bash function that outputs its text fragment. The main function concatenates them with separators.

### Widgets

| Widget | Function | Output Example | Data Source |
|--------|----------|----------------|-------------|
| Model | `widget_model` | `Opus 4.6(H)` | `model.id` + `~/.claude/settings.json` effort level |
| Progress | `widget_progress` | `████░░░░░░ 45%` | Calculated from context_window fields |
| Tokens | `widget_tokens` | `90K/200K` | `context_window.current_usage` + `context_window_size` |
| Cost | `widget_cost` | `$0.50` | `cost.total_cost_usd` |
| Rate Limit | `widget_ratelimit` | `5h:23%(2h) 7d:5%(4d)` | Anthropic OAuth API |

### Combined output

```
Opus 4.6(H) ████░░░░░░ 45% 90K/200K $0.50 5h:23%(2h)
```

## Model Name Parsing

Parse `model.id` (e.g., `claude-opus-4-6`) to extract versioned display name:
- `*opus-4-6*` → "Opus 4.6"
- `*opus-4-5*` → "Opus 4.5"
- `*sonnet-4-6*` → "Sonnet 4.6"
- `*sonnet-4-5*` → "Sonnet 4.5"
- `*haiku-4-5*` → "Haiku 4.5"
- Fallback to `model.display_name`

Effort level suffix (H/M/L) read from `~/.claude/settings.json` → `effortLevel` or env `CLAUDE_CODE_EFFORT_LEVEL`.

## Context Calculation

Matches the gist's autocompact-aware calculation:
- `CURRENT_TOKENS = input_tokens + cache_creation_input_tokens + cache_read_input_tokens`
- `EHA = context_window_size - min(model_max_output, 20000)`
- If autocompact enabled: `EFFECTIVE = EHA - 13000` (or `EHA * pct/100` if override set)
- If autocompact disabled: `EFFECTIVE = EHA`
- `PERCENT = CURRENT_TOKENS * 100 / EFFECTIVE`

Progress bar colors: green (<50%), yellow (50-80%), red (>80%).

## Rate Limit API

- **Endpoint:** `GET https://api.anthropic.com/api/oauth/usage`
- **Auth:** Bearer token from `~/.claude/.credentials.json` → `claudeAiOauth.accessToken`. macOS: falls back to Keychain.
- **Headers:** `Authorization: Bearer $TOKEN`, `anthropic-beta: oauth-2025-04-20`
- **Response:** `{ five_hour: { utilization, resets_at }, seven_day: { utilization, resets_at } }`
- **Caching:** File-based in `~/.cache/xida-statusline/usage.json` with 60s TTL (check file mtime)
- **Timeout:** 5 seconds via curl
- **Plan detection:** If `seven_day` is non-null in response, user is on Max plan → show 7d widget. Otherwise hide it.

## Setup Flow (`setup.sh`)

Interactive terminal setup mirroring notification/setup.sh:

### If not installed (no statusLine pointing to our script):
1. Show header
2. Check for existing statusLine in settings.json
3. If exists: warn user "Current statusLine: [value]. This will be replaced."
4. Confirm → write statusLine entry via jq
5. Show success message

### If already installed:
1. Show header with "Installed" status
2. Menu: Update (reinstall) / Uninstall / Quit
3. Uninstall: remove statusLine key from settings.json via jq

### statusLine value written to settings.json:
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /absolute/path/to/statusline/statusline.sh"
  }
}
```

## Command (`commands/statusline.md`)

Platform-specific terminal launch commands (same pattern as notification.md):
- win32: `powershell Start-Process ...`
- darwin: `osascript -e 'tell app "Terminal" ...'`
- linux: `nohup x-terminal-emulator -e bash ... &`

## Dependencies

- `jq` — Required for JSON parsing (stdin and settings.json)
- `curl` — Required for rate limit API calls
- `bash` — Runtime shell

## What This Does NOT Include

- No external service API calls (Codex, Gemini, z.ai)
- No transcript parsing (tool activity, agents, todos)
- No session duration tracking
- No git branch info
- No themes/i18n/config files
- No Node.js dependency
