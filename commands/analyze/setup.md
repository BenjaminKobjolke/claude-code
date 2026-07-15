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
- **AutoHotkey**: Look for `*.ahk`, `*.ah2`, or `*.ahk2` files

If multiple languages are detected, ask the user which one to configure.

## Step 3: Read Language-Specific Setup Documentation

Based on the detected language, read the corresponding setup documentation from the cli-code-analyzer project:

- Flutter: `{cli-code-analyzer-path}/docs/setup/FLUTTER.md`
- C#: `{cli-code-analyzer-path}/docs/setup/CSHARP.md`
- Python: `{cli-code-analyzer-path}/docs/setup/PYTHON.md`
- PHP: `{cli-code-analyzer-path}/docs/setup/PHP.md`
- AutoHotkey: `{cli-code-analyzer-path}/docs/setup/AUTOHOTKEY.md`

## Step 4: Create Batch Files

Follow the "Example Batch Files" section in the documentation to create the appropriate batch files in the `tools` folder:

1. Create the `tools` folder if it doesn't exist
2. Create `tools/analyze_code.bat` following the template from the documentation
3. Create `tools/analyze_changed_and_new_files.bat` using the exact template from
   `enforce-post-feature-workflow.md` Step 5 (git-aware `--only-changed` run — the
   post-implementation default; do not duplicate the template here)
4. Create any language-specific fixer batch files mentioned in the documentation (e.g., `fix_ruff_issues.bat` for Python, `fix_phpcs_issues.bat` for PHP)

**Important:** When creating batch files, replace the placeholder paths with:
- The actual cli-code-analyzer path provided by the user
- The current project path

## Step 5: Create Rules Configuration File

If a `code_analysis_rules.json` file doesn't exist in the project root, create one using the "Example Configuration" from the language-specific documentation.

### Duplicate-code detection (PMD)

The `pmd_duplicates` (and `pmd_similar_code`) rules require PMD. PMD prompts
interactively for its path on first run if it is not configured, which hangs in
a non-interactive shell — so decide up front:

1. Check whether PMD is configured: read `{cli-code-analyzer-path}/settings.ini`
   for a `[pmd]` `pmd_path`, and confirm that binary actually exists on disk.
2. **If PMD is installed and configured** → set `pmd_duplicates.enabled` to
   `true` in `code_analysis_rules.json` (duplicate detection is valuable and runs
   non-interactively).
3. **If PMD is missing or unconfigured** → leave `pmd_duplicates` disabled and
   **warn the user**: tell them duplicate-code detection is off because PMD was
   not found, and that they can install/configure PMD (run the analyzer once to
   let it download/configure PMD, or set `pmd_path` in `settings.ini`) and then
   flip `pmd_duplicates.enabled` to `true`.

Leave `pmd_similar_code` disabled by default (noisier structural-similarity
pass); the user can enable it the same way once PMD is available.

### Flutter LSP-based analyzers (dart_unused_code, dart_missing_dispose)

For **Flutter/Dart** projects the rules `dart_unused_code` and `dart_missing_dispose`
require **dart-lsp-mcp** (`D:\GIT\BenjaminKobjolke\dart-lsp-mcp`). That repo serves two
distinct roles — do not confuse them:

1. **Library backend for the batch analyzer.** The analyzer imports
   `dart_lsp_watcher.api` (`find_references`, `get_document_symbols`, `get_hover`). For
   this to work the package must be importable from the **cli-code-analyzer venv** —
   install it once:

   ```bash
   "{cli-code-analyzer-path}\venv\Scripts\python.exe" -m pip install -e D:\GIT\BenjaminKobjolke\dart-lsp-mcp
   ```

   Verify: `... python.exe -c "from dart_lsp_watcher.api import find_references, get_document_symbols, get_hover; print('ok')"`.
   If the import fails, **leave both rules disabled** and warn the user (mirror the PMD
   guidance) — otherwise every run reports a "tool failure". These rules also need the
   **Dart SDK on PATH** and are slow (LSP indexes the project on first call).
2. **Interactive MCP server inside Claude Code.** Independently of the batch analyzer,
   `dart-lsp` is also used as an **interactive MCP server in Claude Code** for live code
   navigation (`mcp__dart-lsp__find_references`, `go_to_definition`, `get_hover`,
   `get_diagnostics`, `search_symbols`, …). This is a separate channel from the batch
   run — see "Dart LSP MCP Server Setup (Flutter/Dart Projects)" at the end of this
   document. Offer to register it for Flutter projects.

### Graphify fan-out (opt-in, extra setup)

The `graphify_fanout` rule flags classes with high outgoing coupling (fan-out) using a
graphify dependency graph. **Do not add it to the generated `code_analysis_rules.json`
by default** — it needs graphify installed and a pre-built `graphify-out/graph.json`
that this setup does not create.

If the user wants it, follow the enable flow in
`commands/analyze/check-analyzers.md` → "Graphify Fan-Out (special setup)": build the
graph (`graphify src --directed`), tune `hub_classes`, verify the PreToolUse hook, and
add the JSON block documented there. It can also be added later via `check-analyzers`.

## Step 6: Update CLAUDE.md

Add the following section to the project's CLAUDE.md file (create it if it doesn't exist):

````markdown
## Code Analysis

Two analysis modes — pick by situation:

**Changed-files run (default after implementing a feature, finishing a plan, or
fixing a bug):**

```bash
powershell -Command "cd '{project-path}'; cmd /c '.\tools\analyze_changed_and_new_files.bat'"
```

Uses `--only-changed`: the report is filtered to files new/modified vs git `HEAD`
(includes untracked). Project-wide analyzers still run; only the report is
filtered. Fast feedback, no noise from pre-existing violations elsewhere.

**Full run (whole-project audits):**

```bash
powershell -Command "cd '{project-path}'; cmd /c '.\tools\analyze_code.bat'"
```

Use the full run for: an explicit audit request (`/analyze:run-and-fix`),
exception maintenance (`/analyze:improve-exceptions`), before a release/merge,
after refactors that touch shared code, or when the working tree is clean vs
`HEAD` (a changed-files run would report nothing).

Results are written to `code_analysis_results/` as **per-rule CSV files** (e.g.
`flutter_analyze.csv`, `line_count_report.csv`, `duplicate_code.csv`) — there is
no `.md` report, and a missing CSV means that rule found nothing. Fix any
reported issues before committing.
````

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

---

# Intelephense LSP MCP Server Setup (PHP Projects)

For PHP projects, in addition to the cli-code-analyzer, you can set up the **Intelephense LSP MCP Server** for real-time LSP-based diagnostics accessible via MCP tools.

**Source:** `D:\GIT\BenjaminKobjolke\intelephense-lsp-mcp`

## Prerequisites

- Python 3.10+
- `uv` package manager
- Node.js with Intelephense installed globally: `npm install -g intelephense`

## Step 1: Register the MCP Server

Run this command to add the MCP server to the current project's Claude Code settings:

```bash
claude mcp add --transport stdio intelephense -- uv --directory D:\GIT\BenjaminKobjolke\intelephense-lsp-mcp run python -m intelephense_watcher.mcp_server
```

This adds the following to the project's `mcpServers` in `.claude.json`:

```json
"mcpServers": {
  "intelephense": {
    "type": "stdio",
    "command": "uv",
    "args": [
      "--directory",
      "D:\\GIT\\BenjaminKobjolke\\intelephense-lsp-mcp",
      "run",
      "python",
      "-m",
      "intelephense_watcher.mcp_server"
    ],
    "env": {}
  }
}
```

## Step 2: Verify

Check that the MCP server is running in Claude Code:

```
/mcp
```

The `intelephense` server should appear with its tools listed.

## Step 3: Create `intelephense.json` (Optional)

Create an `intelephense.json` in the PHP project root to exclude files/directories from diagnostics output:

```json
{
    "ignore": [
        "config/app.php",
        "tests/fixtures/**"
    ]
}
```

**How filtering works:**
- **Automatically skipped during scanning** (never opened in LSP): `vendor`, `node_modules`, `.git`, `cache`, `.phpstan-cache`
- **`intelephense.json` ignore patterns**: Files are still scanned but their diagnostics are filtered from output
- **Intelephense internal indexing**: The LSP always indexes `vendor/` internally for import/type resolution regardless of the above filters

## Available MCP Tools

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `get_diagnostics` | Get PHP errors/warnings | `project_path`, `file_path?`, `min_severity?` |
| `find_references` | Find all references to a symbol | `project_path`, `file_path`, `line`, `column` |
| `go_to_definition` | Navigate to symbol definition | `project_path`, `file_path`, `line`, `column` |
| `get_hover` | Get symbol documentation/type | `project_path`, `file_path`, `line`, `column` |
| `get_document_symbols` | List all symbols in a file | `project_path`, `file_path` |
| `search_symbols` | Search workspace symbols | `project_path`, `query` |
| `reindex` | Force re-index all PHP files | `project_path` |

---

# Dart LSP MCP Server Setup (Flutter/Dart Projects)

For Flutter/Dart projects, `dart-lsp` is used as an **interactive MCP server inside Claude Code** for real-time LSP-based code navigation and diagnostics — separate from (and in addition to) the cli-code-analyzer batch run.

**Source:** `D:\GIT\BenjaminKobjolke\dart-lsp-mcp`

## Prerequisites

- Python 3.10+
- `uv` package manager
- Dart SDK installed and on PATH (`dart --version`)

## Step 1: Register the MCP Server

Run this command to register dart-lsp with Claude Code (registration is global; applies to all projects):

```bash
claude mcp add --transport stdio dart-lsp -- uv --directory D:\GIT\BenjaminKobjolke\dart-lsp-mcp run python -m dart_lsp_watcher.mcp_server
```

Or add it manually to the project's `mcpServers` (in `.mcp.json` or `.claude.json`):

```json
"mcpServers": {
  "dart-lsp": {
    "type": "stdio",
    "command": "uv",
    "args": [
      "--directory",
      "D:\\GIT\\BenjaminKobjolke\\dart-lsp-mcp",
      "run",
      "python",
      "-m",
      "dart_lsp_watcher.mcp_server"
    ],
    "env": {}
  }
}
```

## Step 2: Verify

Run `/mcp` in Claude Code — the `dart-lsp` server should appear with its tools listed.

## Step 3: Configure ignore patterns (Optional)

Create `dart_lsp.json` in the project root:

```json
{
  "ignore": ["build/**", ".dart_tool/**", "**/*.g.dart", "**/*.freezed.dart"]
}
```

## Available MCP Tools

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `get_diagnostics` | Get Dart errors/warnings | `project_path`, `file_path?`, `min_severity?` |
| `find_references` | Find all references to a symbol | `project_path`, `file_path`, `line`, `column` |
| `go_to_definition` | Navigate to symbol definition | `project_path`, `file_path`, `line`, `column` |
| `get_hover` | Get symbol documentation/type | `project_path`, `file_path`, `line`, `column` |
| `get_document_symbols` | List all symbols in a file | `project_path`, `file_path` |
| `search_symbols` | Search workspace symbols | `project_path`, `query` |
| `reindex` | Re-scan workspace for new/removed Dart files | `project_path` |

> **Note:** position-based tools take **0-indexed** `line`/`column`; first call is slow (5–10s LSP startup + indexing), subsequent calls are fast.

> **Not the same as the batch analyzer.** `dart_unused_code` / `dart_missing_dispose` consume `dart_lsp_watcher.api` from the analyzer venv (see "Flutter LSP-based analyzers" under Step 5). Registering the MCP server here does **not** enable those batch rules, and vice versa.
