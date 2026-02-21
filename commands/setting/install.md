---
description: Install a setting from the remote repository
---

# Install Setting

Run the platform-specific interactive installer script located next to this file.

## Instructions

1. **Detect platform** from the runtime environment and run the correct script:

   **Windows (`win32`):**
   ```bash
   powershell -NoProfile -File "<path-to-this-directory>/install.ps1" $ARGUMENTS
   ```

   **macOS (`darwin`):**
   ```bash
   bash "<path-to-this-directory>/install.sh" $ARGUMENTS
   ```

   Replace `<path-to-this-directory>` with the absolute path to the directory containing this file (same directory as `install.md`).

2. **Let the user interact** with the script. Do NOT run it in the background. The script handles all discovery, selection, downloading, and installation interactively.

3. **Unsupported platforms:** If the platform is neither `win32` nor `darwin`, tell the user that remote installation is not yet supported for their platform.

4. **Report the result** based on the script's exit code. Exit code 0 means success; anything else means failure.
