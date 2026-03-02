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

5. **Implement the fix**: Make the code changes.

6. **Verify**: Run /validate:pre-commit to check the fix does not break anything.

7. If validation passes, mark the bug as fixed in BUGS.md by adding `[FIXED]` prefix to its entry and tell the user they can commit with /git:commit.

8. If validation fails, report the failures and ask the user how to proceed.
