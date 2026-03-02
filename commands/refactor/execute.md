---
description: Execute refactoring phases from PLAN.md created by refactor:plan
---

Execute a refactoring plan phase by phase, validating after each phase.

Steps:

1. Read PLAN.md in the project root. If it does not exist, tell the user to create a refactoring plan first with /refactor:plan.

2. Identify all phases in the plan. Check which phases are already marked as completed (look for [DONE] or checkbox markers).

3. If $ARGUMENTS is provided, treat it as a phase number or name to execute. Otherwise, pick the next incomplete phase.

4. **Execute the phase**: Follow the phase instructions from PLAN.md. For each change:
   - Announce what you are modifying
   - Make the changes
   - Report what was done

5. **Validate**: After completing the phase, run /validate:pre-commit.

6. If validation passes:
   - Mark the phase as [DONE] in PLAN.md
   - Tell the user the phase is complete and suggest committing with /git:commit
   - Report which phases remain

7. If validation fails:
   - Report the failures
   - Do NOT mark the phase as done
   - Use the rollback strategy from PLAN.md if available
   - Ask the user how to proceed

8. When all phases are marked [DONE], move PLAN.md to plan/done/ with today's date prefix (YYYYMMDD_PLAN.md) and tell the user the refactoring is complete.
