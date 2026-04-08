---
description: Fix a bug from BUGS.md with a structured workflow
---

Fix a specific bug using a structured confirm-then-fix workflow to prevent wrong-layer fixes.

Steps:

1. Read BUGS.md in the project root. If it does not exist, tell the user to document bugs first with /bugs:collect.

2. If $ARGUMENTS is provided, find the matching bug entry (partial match, case-insensitive). If multiple match, list them and ask the user to pick one. If none match, show available bugs. If no $ARGUMENTS, list all unfixed bugs and ask the user which one to work on.

3. **Confirm fix target**: Before making any changes, present:
   - The bug description from BUGS.md
   - The file(s) and layer you believe the fix belongs in
   - Ask the user to confirm this is the right target

4. **Validate approach**: Present your proposed fix strategy (what to change and why). Wait for user approval before implementing.

5. **Write a failing test**: Before writing any fix, create a test that reproduces the bug. Run the test suite to confirm it fails. If the project has no test infrastructure, skip this step and note it.

6. **Implement the fix**: Make the minimal code changes to fix the bug. Check for existing project patterns and components before writing new code.

7. **Run tests**: Run the test suite to confirm the failing test now passes and no other tests broke. If the test still fails, iterate on the fix.

8. **Verify**: Run /validate:pre-commit to check the fix does not break anything. Also check:
   - DI container includes any new services
   - Translation keys use the project's format conventions
   - No raw HTML where project widgets exist

9. If validation passes, mark the bug as fixed in BUGS.md by adding `[FIXED]` prefix to its entry and tell the user they can commit with /git:commit.

10. If validation fails, report the failures and ask the user how to proceed.
