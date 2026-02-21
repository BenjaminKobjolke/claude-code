---
description: Install a setting from the remote repository
---

# Install Setting

Launch the interactive setting installer in a new terminal window by piping the script directly from the public repository.

## Instructions

1. **Detect platform** from the runtime environment and launch the installer in a new terminal:

   **Windows (`win32`):**
   ```bash
   powershell -NoProfile -Command "Start-Process powershell -ArgumentList '-NoProfile -Command \"irm https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/install.ps1 | iex\"'"
   ```

   If `$ARGUMENTS` is provided (e.g., `status-line`), pass the setting name via an environment variable:
   ```bash
   powershell -NoProfile -Command "Start-Process powershell -ArgumentList '-NoProfile -Command \"$env:SETTING_NAME=''$ARGUMENTS''; irm https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/install.ps1 | iex\"'"
   ```

   **macOS (`darwin`):**
   ```bash
   osascript -e 'tell app "Terminal" to do script "curl -fsSL https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/install.sh | bash"'
   ```

   If `$ARGUMENTS` is provided:
   ```bash
   osascript -e 'tell app "Terminal" to do script "curl -fsSL https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/install.sh | bash -s -- $ARGUMENTS"'
   ```

2. **Unsupported platforms:** If the platform is neither `win32` nor `darwin`, tell the user that remote installation is not yet supported for their platform.

3. **Tell the user** that the installer has been opened in a new terminal window and they should follow the prompts there.
