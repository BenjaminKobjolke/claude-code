# Custom Status Line for Claude Code

A custom status line that displays real-time session metrics at the bottom of the Claude Code terminal.

```
████▌██████████ 26.0% | 52.1k/200.0k | $1.93 | 3m 33s | Opus 4.6
```

## Metrics

| Field | Description | On Resume |
|---|---|---|
| Progress bar | Unicode block bar showing context usage visually | Persistent |
| Percentage | Context window usage as a percentage | Persistent |
| Tokens | Current context usage / max context window size | Persistent |
| Cost | Session cost in USD | Resets |
| Duration | Wall-clock time since session started | Resets |
| Model | Active model display name | Persistent |

## File Structure

```
settings/status-line/
  win/
    install.ps1       # Automated installer
    status-line.ps1   # PowerShell status line script
    setup.ps1         # Interactive setup wizard
    settings.json     # Claude Code config snippet
  mac/
    install.sh        # Automated installer
    status-line.sh    # Bash status line script
    setup.sh          # Interactive setup wizard
    settings.json     # Claude Code config snippet
```

## Installation

### Automated (recommended)

Run the install script for your platform. It copies the files into `~/.claude/settings/status-line/`, merges the `statusLine` config into `~/.claude/settings.json`, and optionally launches the customization wizard.

**Windows:**

```powershell
powershell -NoProfile -File path/to/status-line/win/install.ps1
```

**macOS:**

```bash
bash path/to/status-line/mac/install.sh
```

The installer will:
- Skip copying if the files are already inside `~/.claude/`
- Prompt before overwriting an existing `statusLine` setting
- Back up `settings.json` to `settings.json.bak` before modifying
- Validate the output JSON before replacing the original

### Manual

If you prefer to install manually:

1. Copy the `status-line/` folder into `~/.claude/settings/`
2. Add the platform-specific `statusLine` entry to `~/.claude/settings.json`:

**Windows:**

```json
{
    "statusLine": {
        "type": "command",
        "command": "powershell -NoProfile -File \"$USERPROFILE/.claude/settings/status-line/win/status-line.ps1\""
    }
}
```

**macOS:**

```json
{
    "statusLine": {
        "type": "command",
        "command": "bash \"$HOME/.claude/settings/status-line/mac/status-line.sh\""
    }
}
```

3. Restart Claude Code

## Customization

Run the interactive setup wizard to customize the status line appearance. The wizard modifies only the config block (between `:config-start` and `:config-end` markers) in the status line script -- all other code is left untouched.

**Windows:**

```powershell
powershell -File ~/.claude/settings/status-line/win/setup.ps1
```

**macOS:**

```bash
bash ~/.claude/settings/status-line/mac/setup.sh
```

### Options

**Layout** -- choose which fields to display and in what order:

| # | Layout |
|---|---|
| 1 | Progress bar, Percentage, Tokens, Cost, Duration, Model *(default)* |
| 2 | Progress bar, Percentage, Tokens, Cost, Model |
| 3 | Model, Progress bar, Percentage, Tokens, Cost, Duration |
| 4 | Progress bar, Percentage, Cost, Model |

**Bar width** -- number of characters for the progress bar:

| # | Width |
|---|---|
| 1 | 10 |
| 2 | 15 *(default)* |
| 3 | 20 |

**Bar style** -- character set used to render the bar:

| # | Style | Characters |
|---|---|---|
| 1 | Block *(default)* | `█` filled, `▌` half, `█` empty (colored dim) |
| 2 | Shade | `▓` filled, `▒` half, `░` empty |
| 3 | ASCII | `=` filled, `-` half, `-` empty |

**Bar color** -- ANSI color for the filled portion (empty is always dim gray):

| # | Color | ANSI Code |
|---|---|---|
| 1 | Green *(default)* | 32 |
| 2 | Cyan | 36 |
| 3 | Yellow | 33 |
| 4 | White | 37 |

### Manual Configuration

You can also edit the config block directly in the status line script. The configurable variables sit between `# :config-start` and `# :config-end`:

**PowerShell** (`status-line.ps1`):

```powershell
# :config-start
$CFG_BAR_WIDTH    = 15
$CFG_FILLED_COLOR = 32
$CFG_EMPTY_COLOR  = 90
$CFG_FILLED_CHAR  = [char]0x2588
$CFG_HALF_CHAR    = [char]0x258C
$CFG_EMPTY_CHAR   = [char]0x2588
$CFG_FORMAT       = '{0} {1} | {2} | {3} | {4} | {5}'
# :config-end
```

`$CFG_FORMAT` placeholders: `{0}` progress bar, `{1}` percentage, `{2}` tokens, `{3}` cost, `{4}` duration, `{5}` model.

**Bash** (`status-line.sh`):

```bash
# :config-start
CFG_BAR_WIDTH=15
CFG_FILLED_COLOR=32
CFG_EMPTY_COLOR=90
CFG_FILLED_CHAR=$'\xe2\x96\x88'
CFG_HALF_CHAR=$'\xe2\x96\x8c'
CFG_EMPTY_CHAR=$'\xe2\x96\x88'
cfg_output() {
    printf '%s %s | %s/%s | %s | %s | %s\n' \
        "$progress_bar" "$used_pct_str" "$used_str" "$max_str" "$cost_str" "$duration" "$model_name"
}
# :config-end
```

The `cfg_output()` function controls field order by rearranging the `printf` arguments.

## Requirements

- **Windows:** PowerShell 5.1+ (ships with Windows)
- **macOS:** Bash + Python 3 (via Xcode Command Line Tools or Homebrew)

## Reference

- [Claude Code Status Line docs](https://code.claude.com/docs/en/statusline)
