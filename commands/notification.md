---
description: Setup Claude Code notification sounds and taskbar flash
---

This command opens a setup script in a new terminal window. That is ALL it does.

## Execution

1. Say "Launching notification setup..."
2. Run **exactly one Bash tool call** matching the detected `Platform` environment variable:
   - win32: `powershell -NoProfile -Command 'Start-Process powershell -ArgumentList "-NoProfile -Command bash ${CLAUDE_PLUGIN_ROOT}/notification/setup.sh"'`
   - darwin: `osascript -e 'tell app "Terminal" to do script "bash ${CLAUDE_PLUGIN_ROOT}/notification/setup.sh"'`
   - linux: `nohup x-terminal-emulator -e bash ${CLAUDE_PLUGIN_ROOT}/notification/setup.sh &>/dev/null &`
   - Else: Say "Unsupported platform: {Platform}"
3. Stop. Do not output any further text.

## Strictly forbidden

- Do NOT spawn any subagents or Task tool calls.
- Do NOT read, check, or modify any settings files.
- Do NOT add explanatory text, follow-up suggestions, or any output beyond step 1.
- Do NOT take any follow-up actions after the Bash command completes. The setup script in the new terminal handles everything.
