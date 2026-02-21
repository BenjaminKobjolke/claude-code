---
description: Install a setting from the remote repository
---

# Install Setting

Install a setting from the remote GitHub repository. Auto-discovers available settings, detects your platform, and runs the installer.

## Instructions

1. **Discover available settings** by listing the remote `settings/` directory:

   First try `gh`:
   ```bash
   gh api repos/BenjaminKobjolke/claude-code/contents/settings?ref=main --jq '[.[] | select(.type == "dir")] | .[].name'
   ```

   If `gh` is not available, fall back to `curl`:
   ```bash
   curl -fsSL "https://api.github.com/repos/BenjaminKobjolke/claude-code/contents/settings?ref=main" | python3 -c "import sys,json;[print(x['name']) for x in json.load(sys.stdin) if x['type']=='dir']"
   ```

   On Windows without python3, use PowerShell:
   ```bash
   powershell -NoProfile -Command "(Invoke-RestMethod 'https://api.github.com/repos/BenjaminKobjolke/claude-code/contents/settings?ref=main') | Where-Object { $_.type -eq 'dir' } | ForEach-Object { $_.name }"
   ```

   These return the names of available settings (e.g., `status-line`).

2. **Select the setting to install:**

   - If `$ARGUMENTS` is provided and matches one of the discovered setting names, select it.
   - If `$ARGUMENTS` is provided but does NOT match, tell the user it was not found and list available settings.
   - If no argument is provided, ask the user to pick from the list of discovered settings.

3. **Detect platform** from the runtime environment:
   - `win32` -> Windows (PowerShell)
   - `darwin` -> macOS (Bash)
   - Any other platform: tell the user that remote installation is not yet supported for their platform and stop.

4. **Run the install script** by streaming it directly to the shell:

   **Windows:**
   ```bash
   powershell -NoProfile -Command "irm 'https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/<name>/win/install.ps1' | iex"
   ```

   **macOS:**
   ```bash
   curl -fsSL 'https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/<name>/mac/install.sh' | bash
   ```

   Replace `<name>` with the selected setting name.

   **On failure:** If the install script fails or produces an error, stop and explain what went wrong. Do not retry automatically.

5. **Report the result** to the user, including whether the installation succeeded or failed and any relevant output from the installer.
