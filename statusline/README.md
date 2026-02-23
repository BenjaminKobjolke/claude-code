# Statusline

Widget-based status line for Claude Code showing model, context usage, cost, and rate limits.

## Quick Start

Run `/xida:statusline` inside Claude Code. This opens an interactive setup in a new terminal. On first run you can install (writes statusLine to `~/.claude/settings.json`). On subsequent runs you can update or uninstall. Restart Claude Code after changes.

## How It Works

Claude Code pipes JSON to the statusLine command on each render. The script parses this JSON via `jq`, runs each widget function, and outputs a single ANSI-colored line.

## Widgets

| Widget | Output | Description |
|--------|--------|-------------|
| Progress | `████░░░░░░ 45%` | Colored progress bar (green/yellow/red). Always shown. |
| Tokens | `90K/200K` | Current / total context tokens. Always shown. |
| Cost | `$0.50` | Session cost, locale-aware (currency + decimal). Hidden when zero. |
| Rate Limit | `5h: 23% (2h) 7d: 5% (4d)` | API usage with reset countdown. Color by health. |
| Model | `Opus 4.6(H)` | Versioned model name + effort level (H/M/L) |

## Output Example

```
████░░░░░░ 45% │ 90K/200K │ $0.50 │ 5h: 23% (2h) 7d: 5% (4d) │ Opus 4.6(H)
```

## Context Calculation

The progress bar uses an autocompact-aware denominator:
- With autocompact enabled: shows percentage of threshold (hits 100% when compact triggers)
- With autocompact disabled: shows percentage of effective context window

## Rate Limits

- Fetches from `api.anthropic.com/api/oauth/usage`
- Auth via `~/.claude/.credentials.json` (or macOS Keychain)
- File-cached in `~/.cache/xida-statusline/` with 60-second TTL
- 7-day limits shown automatically for Max plan users (auto-detected from API response)

## Files

| File | Purpose |
|------|---------|
| `statusline.sh` | Runtime script piped JSON by Claude Code. Widget functions output ANSI text. |
| `setup.sh` | Interactive setup. Install/uninstall modifies `~/.claude/settings.json` via jq. |

## Dependencies

- `jq` — JSON parsing (required)
- `curl` — Rate limit API calls (required for rate limit widget)
- `bash` — Runtime shell
