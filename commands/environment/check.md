---
description: Validate development environment matches project expectations
---

Check that the development environment has the correct tools and configuration for this project.

Steps:

1. Read CLAUDE.md and detect the project's expected tools, language, framework, and package manager.

2. Run the following checks based on what is configured:

   **Package manager**:
   - If project expects uv: verify `uv --version` works. Warn if only pip is available.
   - If project expects fvm: verify `fvm --version` works.
   - If project expects npm/pnpm/yarn: verify the expected one is available.

   **Platform compatibility**:
   - Detect current OS (Windows/Linux/Mac)
   - If Windows: warn about Unix-only commands that may appear in scripts (rm, cp, mv without PowerShell equivalents)
   - Check that configured bat/sh files in tools/ actually exist

   **Language tools**:
   - If Python: check for configured linter (ruff, etc.)
   - If Flutter/Dart: check `fvm flutter --version`
   - If configured analyzers exist in CLAUDE.md, verify their paths are valid

3. Report results:
   - OK: tool found and working
   - MISSING: tool not found, suggest how to install
   - MISMATCH: wrong version or wrong tool detected

4. If all checks pass, tell the user the environment is ready.

5. If any checks fail, list the issues and suggest fixes.
