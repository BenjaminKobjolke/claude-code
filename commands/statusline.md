---
description: Configure Claude Code status line
---

Say "Launching status line setup..." then run the command matching the detected `Platform` environment variable. No other text output.

- win32: `powershell -NoProfile -Command 'Start-Process powershell -ArgumentList "-NoProfile -Command bash ${CLAUDE_PLUGIN_ROOT}/statusline/setup.sh"'`
- darwin: `osascript -e 'tell app "Terminal" to do script "bash ${CLAUDE_PLUGIN_ROOT}/statusline/setup.sh"'`
- linux: `nohup x-terminal-emulator -e bash ${CLAUDE_PLUGIN_ROOT}/statusline/setup.sh &>/dev/null &`
- Else: Say "Unsupported platform: {Platform}"
