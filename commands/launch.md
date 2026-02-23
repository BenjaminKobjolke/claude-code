---
description: Execute a script in a new external terminal window (cross-platform)
---

# Execute Script Externally

Execute a script file in a new external terminal window. Cross-platform: Windows, macOS, Linux.

## Arguments

`$ARGUMENTS` format: `<script-path> [args...]`

- First argument: path to the script. The extension is **optional** -- if omitted, the command tries platform-appropriate extensions in order. If a known script extension (`.ps1`, `.bat`, `.cmd`, `.sh`, `.zsh`, `.bash`) is included, that exact file is used directly. Relative paths resolve from the current working directory. Absolute paths are used as-is.
- Remaining arguments: passed through to the script.

## Validation

If `$ARGUMENTS` is empty, print this usage message and stop:

```
Usage: /xida:launch <script-path> [args...]

  script-path   Path to script (relative to CWD or absolute). Extension is optional.
                If omitted, tries platform extensions automatically.
                If a known extension (.ps1, .bat, .cmd, .sh, .zsh, .bash) is given, uses it directly.
  args          Optional arguments passed to the script

Examples:
  /xida:launch tools/install
  /xida:launch tools/install.ps1
  /xida:launch resources/setup-files/python/install --verbose
  /xida:launch /absolute/path/to/deploy staging
```

## Step 1: Parse arguments

Split `$ARGUMENTS` into:
- `SCRIPT_PATH` -- the first argument
- `SCRIPT_ARGS` -- everything after the first argument, joined as a single string

## Step 2: Check for explicit extension

Check if `SCRIPT_PATH` ends with a known script extension: `.ps1`, `.bat`, `.cmd`, `.sh`, `.zsh`, `.bash`.

- **If yes** -- the user specified an exact file. Verify it exists, determine the launcher from the extension (`.ps1` → powershell, `.bat`/`.cmd` → cmd, `.sh`/`.zsh`/`.bash` → shell), and launch it directly. On `win32`, `.sh`/`.zsh`/`.bash` → Git Bash (not the default shell). Skip the extension-probing logic in Step 3. If the file does not exist, print an error and stop.
- **If no** -- proceed to Step 3 (try extensions automatically).

## Step 3: Resolve and execute in a single command

Based on the `Platform` environment variable, build a **single chained Bash command** that tries extensions in order, resolves the script, and launches it in a new terminal -- all in one Bash tool call.

Extension priority per platform:

| Platform   | Try in order             |
|------------|--------------------------|
| **win32**  | `.sh`, `.ps1`, `.bat`, `.cmd` |
| **darwin** | `.sh`, `.zsh`            |
| **linux**  | `.sh`, `.bash`           |

### win32

#### With explicit extension

If `SCRIPT_PATH` has a known extension, run one command like this (adapt SCRIPT_PATH, EXT, and SCRIPT_ARGS):

For `.sh`/`.zsh`/`.bash` extensions -- launch via Git Bash:

```bash
if [ -f "SCRIPT_PATH" ]; then
  BASH_EXE="${CLAUDE_CODE_GIT_BASH_PATH:-$(cygpath -u 'C:\Program Files\Git\bin\bash.exe')}"
  powershell -NoProfile -Command "Start-Process '$(cygpath -w "$BASH_EXE")' -ArgumentList '--login', '-i', '\"$(cygpath -w "$(pwd)/SCRIPT_PATH")\"', 'SCRIPT_ARGS'"
else
  echo "Error: File not found: SCRIPT_PATH"
fi
```

> **Note:** The `CLAUDE_CODE_GIT_BASH_PATH` environment variable overrides the default Git Bash path (`C:\Program Files\Git\bin\bash.exe`). Set it if Git is installed in a non-standard location.

For `.ps1` / `.bat` / `.cmd` extensions:

```bash
if [ -f "SCRIPT_PATH" ]; then
  # .ps1 → powershell, .bat/.cmd → cmd
  powershell -NoProfile -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"$(cygpath -w "$(pwd)/SCRIPT_PATH")\" SCRIPT_ARGS'"
else
  echo "Error: File not found: SCRIPT_PATH"
fi
```

Use the appropriate launcher based on extension: `powershell` for `.ps1`, `cmd /k` for `.bat`/`.cmd`, Git Bash for `.sh`/`.zsh`/`.bash`.

#### Without extension (auto-probe)

```bash
if [ -f "SCRIPT_PATH.sh" ]; then
  BASH_EXE="${CLAUDE_CODE_GIT_BASH_PATH:-$(cygpath -u 'C:\Program Files\Git\bin\bash.exe')}"
  powershell -NoProfile -Command "Start-Process '$(cygpath -w "$BASH_EXE")' -ArgumentList '--login', '-i', '\"$(cygpath -w "$(pwd)/SCRIPT_PATH.sh")\"', 'SCRIPT_ARGS'"
elif [ -f "SCRIPT_PATH.ps1" ]; then
  powershell -NoProfile -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"$(cygpath -w "$(pwd)/SCRIPT_PATH.ps1")\" SCRIPT_ARGS'"
elif [ -f "SCRIPT_PATH.bat" ]; then
  powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/k \"$(cygpath -w "$(pwd)/SCRIPT_PATH.bat")\" SCRIPT_ARGS'"
elif [ -f "SCRIPT_PATH.cmd" ]; then
  powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/k \"$(cygpath -w "$(pwd)/SCRIPT_PATH.cmd")\" SCRIPT_ARGS'"
else
  echo "Error: No script found. Tried:"; echo "  SCRIPT_PATH.sh"; echo "  SCRIPT_PATH.ps1"; echo "  SCRIPT_PATH.bat"; echo "  SCRIPT_PATH.cmd"
fi
```

### darwin

#### With explicit extension

If `SCRIPT_PATH` has a known extension (`.sh`, `.zsh`), verify the file exists and launch it directly:

```bash
if [ -f "SCRIPT_PATH" ]; then
  osascript -e 'tell app "Terminal" to do script "\"'"$(pwd)/SCRIPT_PATH"'\" SCRIPT_ARGS"'
else
  echo "Error: File not found: SCRIPT_PATH"
fi
```

#### Without extension (auto-probe)

```bash
if [ -f "SCRIPT_PATH.sh" ]; then
  osascript -e 'tell app "Terminal" to do script "\"'"$(pwd)/SCRIPT_PATH.sh"'\" SCRIPT_ARGS"'
elif [ -f "SCRIPT_PATH.zsh" ]; then
  osascript -e 'tell app "Terminal" to do script "\"'"$(pwd)/SCRIPT_PATH.zsh"'\" SCRIPT_ARGS"'
else
  echo "Error: No script found. Tried:"; echo "  SCRIPT_PATH.sh"; echo "  SCRIPT_PATH.zsh"
fi
```

### linux

#### With explicit extension

If `SCRIPT_PATH` has a known extension (`.sh`, `.bash`), verify the file exists and launch it directly:

```bash
if [ -f "SCRIPT_PATH" ]; then RESOLVED="$(pwd)/SCRIPT_PATH"
else echo "Error: File not found: SCRIPT_PATH"; exit 1; fi
if command -v x-terminal-emulator &>/dev/null; then x-terminal-emulator -e "$RESOLVED" SCRIPT_ARGS
elif command -v gnome-terminal &>/dev/null; then gnome-terminal -- "$RESOLVED" SCRIPT_ARGS
elif command -v xterm &>/dev/null; then xterm -e "$RESOLVED" SCRIPT_ARGS
else "$RESOLVED" SCRIPT_ARGS; fi
```

#### Without extension (auto-probe)

```bash
if [ -f "SCRIPT_PATH.sh" ]; then RESOLVED="$(pwd)/SCRIPT_PATH.sh"
elif [ -f "SCRIPT_PATH.bash" ]; then RESOLVED="$(pwd)/SCRIPT_PATH.bash"
else echo "Error: No script found. Tried:"; echo "  SCRIPT_PATH.sh"; echo "  SCRIPT_PATH.bash"; exit 1; fi
if command -v x-terminal-emulator &>/dev/null; then x-terminal-emulator -e "$RESOLVED" SCRIPT_ARGS
elif command -v gnome-terminal &>/dev/null; then gnome-terminal -- "$RESOLVED" SCRIPT_ARGS
elif command -v xterm &>/dev/null; then xterm -e "$RESOLVED" SCRIPT_ARGS
else "$RESOLVED" SCRIPT_ARGS; fi
```

### Unsupported platform

If `Platform` is none of the above, print:
```
Unsupported platform: {Platform}
```

## Important

- **Use exactly one Bash tool call** that chains file-existence checks and execution together.
- Make sure to properly escape paths that contain spaces using double quotes.
- For relative SCRIPT_PATH, resolve to an absolute path using `$(pwd)/` before passing to the terminal launcher.
- The new terminal window should stay open after the script finishes so the user can read the output.
