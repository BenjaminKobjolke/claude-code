---
description: Setup bat files that are executed after each new feature to test for errors and improve code quality
---

Ask the user which bat files in the tools folder are for running tests .
Usually the files are called: tests.bat, tests_unit_tests.bat, tests_integration_tests.bat.

According to the rules of how to run bat files down below. Then save to CLAUDE.md that after implementing a new feature, that those test bat files need to be executed and then the errors to be fixed.
State the explicit command how to successfully run the bat files.

# Running Batch Files (.bat) in Claude Code

This document explains how to run Windows batch files from within Claude Code.

## The Problem

Claude Code runs in a Unix-like shell environment (bash), which cannot directly execute Windows batch files (`.bat`). Running a batch file directly will result in:

```
/usr/bin/bash: line 1: script.bat: command not found
```

## The Solution

Use PowerShell to execute batch files:

```bash
powershell -Command "cd 'D:\path\to\directory'; cmd /c '.\script.bat'"
```

### Breaking it down:

1. `powershell -Command` - Invokes PowerShell
2. `cd 'D:\path\to\directory'` - Changes to the directory containing the batch file
3. `cmd /c '.\script.bat'` - Uses cmd.exe to execute the batch file


## Timeouts

For long-running scripts (like builds), ensure adequate timeout:

```bash
# In Claude Code tool call, use timeout parameter
timeout: 600000  # 10 minutes in milliseconds
```

## Troubleshooting

### Script runs but no output
Try using `call` before the script:
```bash
powershell -Command "cd 'D:\path'; cmd /c 'call script.bat'"
```

### Path contains spaces
Ensure paths are wrapped in single quotes within the PowerShell command:
```bash
powershell -Command "cd 'D:\Path With Spaces\project'; cmd /c '.\script.bat'"
```

### Environment variables not set
Some scripts depend on environment variables. If a script fails, check if it requires specific environment setup.
