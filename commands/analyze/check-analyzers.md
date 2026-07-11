---
description: Check if a project has all available analyzers configured and suggest missing ones
---

# Check Available Analyzers

Check if the current project has all applicable analyzers configured and suggest which ones could be added.

## Steps

1. **Find the rules file**: Look for `code_analysis_rules.json` in the project root or ask the user where it is located.

2. **Detect project language(s)**: Check for language indicators:
   - **PHP**: `composer.json`, `*.php` files
   - **Python**: `requirements.txt`, `pyproject.toml`, `setup.py`, `*.py` files
   - **Dart/Flutter**: `pubspec.yaml`
   - **C#/.NET**: `*.csproj`, `*.sln` files
   - **AutoHotkey**: `*.ahk`, `*.ah2`, `*.ahk2` files

3. **Get available analyzers dynamically**:

   First, find the cli-code-analyzer path from the project's `tools/config.bat`:
   ```batch
   set ANALYZER_PATH=D:\path\to\cli-code-analyzer
   ```

   Then run the `--list-analyzers` command using PowerShell:
   ```bash
   powershell -Command "cd 'D:\path\to\cli-code-analyzer'; python main.py --list-analyzers php"
   ```

   Examples for each language:
   ```bash
   powershell -Command "cd 'D:\path\to\cli-code-analyzer'; python main.py --list-analyzers php"
   powershell -Command "cd 'D:\path\to\cli-code-analyzer'; python main.py --list-analyzers python"
   powershell -Command "cd 'D:\path\to\cli-code-analyzer'; python main.py --list-analyzers flutter"
   powershell -Command "cd 'D:\path\to\cli-code-analyzer'; python main.py --list-analyzers csharp"
   ```

   Or list all available analyzers at once:
   ```bash
   powershell -Command "cd 'D:\path\to\cli-code-analyzer'; python main.py --list-analyzers"
   ```

   The output will show analyzer names, descriptions, and requirements (if any)

4. **Report findings**: Show the user:
   - Which analyzers are currently enabled
   - Which analyzers are disabled but configured
   - Which analyzers are missing entirely
   - Recommendations based on project type

5. **Offer to add missing analyzers**: For each missing analyzer that applies to the project language, ask if the user wants to add it with a recommended default configuration. **`graphify_fanout` is a special case** — it needs a pre-built graphify graph, so do not just add it silently: follow "Graphify Fan-Out (special setup)" below.

## Default Configurations

### PHP Defaults
```json
"phpstan_analyze": {
  "enabled": true,
  "level": 5,
  "exclude_patterns": ["vendor/**", "node_modules/**", ".git/**"]
},
"php_cs_fixer": {
  "enabled": true,
  "rules": "@PSR12",
  "exclude_patterns": ["vendor/**", "node_modules/**", ".git/**"]
},
"intelephense_analyze": {
  "enabled": true,
  "min_severity": "warning",
  "timeout": 5,
  "exclude_patterns": ["vendor/**", "node_modules/**", ".git/**"],
  "ignore_unused_underscore": true
}
```

### Intelephense LSP MCP Server

The `intelephense_analyze` analyzer above uses the cli-code-analyzer. For real-time LSP-based diagnostics via MCP, the **Intelephense LSP MCP Server** can be configured separately.

**Source:** `D:\GIT\BenjaminKobjolke\intelephense-lsp-mcp`

#### Adding the MCP Server to Claude Code

Register it per-project in `.claude.json` (project settings) or globally via CLI:

```bash
claude mcp add --transport stdio intelephense -- uv --directory D:\GIT\BenjaminKobjolke\intelephense-lsp-mcp run python -m intelephense_watcher.mcp_server
```

Or add it manually to the project's `mcpServers` section in `.claude.json`:

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

#### Excluding Files via `intelephense.json`

Create an `intelephense.json` in the PHP project root to filter diagnostics for files you don't want to see:

```json
{
    "ignore": [
        "config/app.php",
        "tests/fixtures/**"
    ]
}
```

These patterns filter diagnostics from the output. The LSP still indexes `vendor/` internally for import resolution — only the **scanning** (which files get opened as documents) skips `vendor`, `node_modules`, `.git`, `cache`, and `.phpstan-cache` automatically.

#### Available MCP Tools

| Tool | Description |
|------|-------------|
| `get_diagnostics` | Get PHP errors/warnings for a project or file |
| `find_references` | Find all references to a symbol |
| `go_to_definition` | Navigate to symbol definition |
| `get_hover` | Get symbol documentation/type |
| `get_document_symbols` | List all symbols in a file |
| `search_symbols` | Search workspace symbols |
| `reindex` | Force re-index all PHP files |
```

### Python Defaults
```json
"ruff_analyze": {
  "enabled": true,
  "select": ["F", "E4", "E7", "E9", "W", "I", "B", "UP", "SIM", "C4", "PIE", "ARG", "RUF"],
  "ignore": [],
  "exclude_patterns": ["venv", "__pycache__", ".git", ".venv", "node_modules"]
}
```

### Dart/Flutter Defaults
```json
"dart_analyze": {
  "enabled": true
},
"flutter_analyze": {
  "enabled": true
},
"dart_code_linter": {
  "enabled": true
}
```

### Universal Defaults
```json
"max_lines_per_file": {
  "enabled": true,
  "warning": 300,
  "error": 500,
  "exclude_patterns": ["vendor/**", "node_modules/**", ".git/**"]
},
"pmd_duplicates": {
  "enabled": true,
  "minimum_tokens": 100
},
"pmd_similar_code": {
  "enabled": false,
  "minimum_tokens": 100,
  "ignore_identifiers": true,
  "ignore_literals": true,
  "ignore_annotations": false
}
```

### Graphify Fan-Out (special setup)

`graphify_fanout` flags classes with high outgoing coupling (fan-out) using a graphify
dependency graph. It is **opt-in and requires extra setup** — unlike the other analyzers it
reads a `graphify-out/graph.json` that must already exist. Do **not** silently add it enabled.

When it shows up as missing/disabled:

1. **Ask the user** whether they want to enable graphify fan-out analysis.
2. **If yes, tell them extra setup is required** before it produces results:
   - **graphify must be installed** (the graph builder).
   - **The graph must be built and kept fresh** — run `graphify src --directed` (adjust the
     source folder) after code changes; the analyzer never builds or refreshes it.
   - **Tune the hub list** — set `hub_classes` to the project's centralized constant registries
     (e.g. endpoints, route names, i18n keys) so healthy edges to them don't count as fan-out.
   - See `{cli-code-analyzer-path}/docs/analyzers/graphify_fanout.md` for full options and the
     per-file `exceptions` caveat (match on filename/glob, not a `src/`-anchored path).
3. **If the user still wants it**, add the block below. It is safe to enable without the graph:
   a missing graph produces a single WARNING (not a tool failure), so it never breaks a run.

```json
"graphify_fanout": {
  "enabled": true,
  "warning": 20,
  "error": 32,
  "ratio_max": 0.25,
  "graph_path": "graphify-out/graph.json",
  "hub_classes": [],
  "hub_autodetect": true,
  "hub_autodetect_percentile": 95,
  "exceptions": []
}
```

If the user does not want the extra setup, leave `graphify_fanout` out (or `"enabled": false`)
and note they can enable it later.

## Output Format

Present findings in a clear format:

```
## Analyzer Status for [Project Name]

Detected language(s): PHP, JavaScript

### Currently Enabled
- max_lines_per_file
- phpstan_analyze

### Disabled (configured but not enabled)
- pmd_duplicates

### Missing (not configured)
- php_cs_fixer - Code style checking with auto-fix capability
- intelephense_analyze - LSP-based diagnostics for real-time error detection

Would you like me to add any of the missing analyzers?
```
