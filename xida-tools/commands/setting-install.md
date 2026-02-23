---
description: Install a setting from the remote repository
---

Run the command matching the detected `Platform` environment variable. No text output before or after, only the command.

- win32:
    - if $ARGUMENTS is empty: `powershell -NoProfile -Command 'Start-Process powershell -ArgumentList "-NoProfile -Command try { irm https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/install.ps1 | iex } finally { pause }"'`
    - else: `powershell -NoProfile -Command '$env:SETTING_NAME='"'"'$ARGUMENTS'"'"'.Trim(); Start-Process powershell -ArgumentList "-NoProfile -Command try { irm https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/install.ps1 | iex } finally { pause }"'`
- darwin: `osascript -e 'tell app "Terminal" to do script "curl -fsSL https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/install.sh | bash -s -- $ARGUMENTS"'`
- Else: Say "Unsupported platform: {Platform}"
