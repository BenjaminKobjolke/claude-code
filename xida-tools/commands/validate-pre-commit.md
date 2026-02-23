---
description: Run all configured validators before committing
---

Run all project validators to check if the code is ready to commit.

Steps:

1. Read CLAUDE.md and check if there is info about how to run tests or code analysis.
   If nothing is configured, tell the user they should set up testing with /xida-tools:testing-setup and analysis with /xida-tools:analyze-setup first.

2. Run all configured validators. For each one, set a timeout of 20 minutes per bat file since some projects might have a lot of tests:
   - Tests (if configured) — same as /xida-tools:testing-run
   - Code analysis (if configured) — same as /xida-tools:analyze-run-and-fix but only run analysis, do not auto-fix
   - Language-specific checks if detected:
     - Flutter: `fvm flutter analyze`
     - Python: ruff check or configured linter
     - Other: whatever is configured in CLAUDE.md

3. Report results per validator:
   - PASS: validator ran with no errors
   - FAIL: validator found issues, list them

4. If all validators pass: tell the user everything looks good and they can proceed with /xida-tools:git-commit.

5. If any validator fails: list the failures clearly and ask the user if they want to fix the issues before committing.

This command does NOT auto-commit and does NOT auto-fix. It only validates and reports.
