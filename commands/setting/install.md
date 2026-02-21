---
description: Install a setting from the remote repository
---

# Install Setting

Launch the interactive setting installer in a new terminal window so the user can interact with it directly.

## Instructions

1. **Detect platform** from the runtime environment and launch the installer in a new terminal:

   **Windows (`win32`):**
   ```bash
   powershell -NoProfile -Command "Start-Process powershell -ArgumentList '-NoProfile -File \"<path-to-this-directory>/install.ps1\"'"
   ```

   If `$ARGUMENTS` is provided (e.g., `status-line`), pass it through:
   ```bash
   powershell -NoProfile -Command "Start-Process powershell -ArgumentList '-NoProfile -File \"<path-to-this-directory>/install.ps1\" $ARGUMENTS'"
   ```

   **macOS (`darwin`):**
   ```bash
   osascript -e 'tell app "Terminal" to do script "bash \"<path-to-this-directory>/install.sh\""'
   ```

   If `$ARGUMENTS` is provided:
   ```bash
   osascript -e 'tell app "Terminal" to do script "bash \"<path-to-this-directory>/install.sh\" $ARGUMENTS"'
   ```

   Replace `<path-to-this-directory>` with the absolute path to the directory containing this file (same directory as `install.md`).

2. **Unsupported platforms:** If the platform is neither `win32` nor `darwin`, tell the user that remote installation is not yet supported for their platform.

3. **Tell the user** that the installer has been opened in a new terminal window and they should follow the prompts there.
