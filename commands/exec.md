---
description: Execute a script in a new external terminal window (cross-platform)
---

# Execute Script Externally

Execute a script file in a new external terminal window. Cross-platform: Windows, macOS, Linux.

## Arguments

`$ARGUMENTS` format: `<script-path> [args...]`

- First argument: path to the script **without file extension**. Relative paths resolve from the current working directory. Absolute paths are used as-is.
- Remaining arguments: passed through to the script.

## Validation

If `$ARGUMENTS` is empty, print this usage message and stop:

```
Usage: /xida:exec <script-path> [args...]

  script-path   Path to script without extension (relative to CWD or absolute)
  args          Optional arguments passed to the script

Examples:
  /xida:exec tools/install
  /xida:exec resources/setup-files/python/install --verbose
  /xida:exec /absolute/path/to/deploy staging
```

## Step 1: Parse arguments

Split `$ARGUMENTS` into:
- `SCRIPT_PATH` -- the first argument (no extension)
- `SCRIPT_ARGS` -- everything after the first argument, joined as a single string

## Step 2: Resolve the script file

Based on the `Platform` environment variable, try these extensions **in order** and use the **first file that exists**:

| Platform   | Try in order             |
|------------|--------------------------|
| **win32**  | `.ps1`, `.bat`, `.cmd`   |
| **darwin** | `.sh`, `.zsh`            |
| **linux**  | `.sh`, `.bash`           |

For each extension, check if the file exists at `SCRIPT_PATH + extension`.

If **no file is found** after trying all extensions, print an error listing every path that was checked and stop. Example:

```
Error: No script found. Tried:
  tools/install.ps1
  tools/install.bat
  tools/install.cmd
```

Store the resolved full path (with extension) as `RESOLVED_PATH`.

## Step 3: Execute in a new terminal window

Construct and run the appropriate command based on `Platform` and the resolved file extension. **Output only the command, no extra text.**

### win32

- If `RESOLVED_PATH` ends in `.ps1`:
  ```
  powershell -NoProfile -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"RESOLVED_PATH\" SCRIPT_ARGS'"
  ```

- If `RESOLVED_PATH` ends in `.bat` or `.cmd`:
  ```
  powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/k \"RESOLVED_PATH\" SCRIPT_ARGS'"
  ```

### darwin

```
osascript -e 'tell app "Terminal" to do script "\"RESOLVED_PATH\" SCRIPT_ARGS"'
```

### linux

Try terminal emulators in this order. Use the **first one found** on the system:

1. `x-terminal-emulator -e "RESOLVED_PATH" SCRIPT_ARGS`
2. `gnome-terminal -- "RESOLVED_PATH" SCRIPT_ARGS`
3. `xterm -e "RESOLVED_PATH" SCRIPT_ARGS`

If none are found, fall back to running inline:
```
"RESOLVED_PATH" SCRIPT_ARGS
```

### Unsupported platform

If `Platform` is none of the above, print:
```
Unsupported platform: {Platform}
```

## Important

- Use the Bash tool to check file existence and execute the final command.
- Make sure to properly escape paths that contain spaces using double quotes.
- The new terminal window should stay open after the script finishes so the user can read the output.
