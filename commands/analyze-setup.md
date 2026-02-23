---
description: Setup bat files that are executed after each new feature to test for errors and improve code quality
---

# Analyze Setup Skill

This skill sets up code analysis batch files for your project.

## Step 1: Get cli-code-analyzer Path

Ask the user: "What is the path to your cli-code-analyzer project?"

Store this path for use in subsequent steps.

## Step 2: Detect Project Language

Analyze the current project to determine its primary language:

- **Flutter/Dart**: Look for `pubspec.yaml` in the project root
- **C#**: Look for `.csproj` or `.sln` files
- **Python**: Look for `requirements.txt`, `setup.py`, `pyproject.toml`, or `*.py` files
- **PHP**: Look for `composer.json` or `*.php` files

If multiple languages are detected, ask the user which one to configure.

## Step 3: Read Language-Specific Setup Documentation

Based on the detected language, read the corresponding setup documentation from the cli-code-analyzer project:

- Flutter: `{cli-code-analyzer-path}/docs/setup/FLUTTER.md`
- C#: `{cli-code-analyzer-path}/docs/setup/CSHARP.md`
- Python: `{cli-code-analyzer-path}/docs/setup/PYTHON.md`
- PHP: `{cli-code-analyzer-path}/docs/setup/PHP.md`

## Step 4: Create Batch Files

Follow the "Example Batch Files" section in the documentation to create the appropriate batch files in the `tools` folder:

1. Create the `tools` folder if it doesn't exist
2. Create `tools/analyze_code.bat` following the template from the documentation
3. Create any language-specific fixer batch files mentioned in the documentation (e.g., `fix_ruff_issues.bat` for Python, `fix_phpcs_issues.bat` for PHP)

**Important:** When creating batch files, replace the placeholder paths with:
- The actual cli-code-analyzer path provided by the user
- The current project path

## Step 5: Create Rules Configuration File

If a `code_analysis_rules.json` file doesn't exist in the project root, create one using the "Example Configuration" from the language-specific documentation.

## Step 6: Update CLAUDE.md

Add the following section to the project's CLAUDE.md file (create it if it doesn't exist):

```markdown
## Code Analysis

After implementing new features or making significant changes, run the code analysis:

```bash
powershell -Command "cd '{project-path}'; cmd /c '.\tools\analyze_code.bat'"
```

Fix any reported issues before committing.
```

Replace `{project-path}` with the actual project path.

---

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
