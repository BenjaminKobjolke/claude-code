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

5. **Offer to add missing analyzers**: For each missing analyzer that applies to the project language, ask if the user wants to add it with a recommended default configuration.

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
