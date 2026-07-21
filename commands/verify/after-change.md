---
description: Verify code changes by running tests and analysis automatically
---

Run all configured validators to catch issues immediately after code changes.

Steps:

1. Read CLAUDE.md and check if there is info about how to run tests or code analysis.
   If nothing is configured, tell the user they should set up testing with /testing:setup and analysis with /analyze:setup first.

2. Run all configured validators. For each one, set a timeout of 20 minutes per bat file:
   - Tests (if configured) — same as /testing:run
   - Code analysis (if configured) — same as /analyze:run-and-fix but only run analysis, do not auto-fix

   Gotcha: many `tools\*.bat` files end with `pause`, which hangs forever in a
   non-interactive shell even after all tests passed. Before running a bat,
   check it for a trailing `pause`; if present, run the underlying command
   directly (e.g. `uv run pytest tests/unit -v`) instead of the bat.

3. Report results per validator:
   - PASS: validator ran with no errors
   - FAIL: validator found issues, list them

4. If all validators pass: tell the user all checks passed and changes look good.

5. If any validator fails: list the failures and ask the user if they want to fix the issues now or continue working.

This command does NOT auto-commit and does NOT auto-fix. It validates and reports so issues are caught early, not at commit time.
