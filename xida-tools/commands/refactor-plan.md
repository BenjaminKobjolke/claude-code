---
description: Create a phased refactoring plan in PLAN.md
---

Create a structured refactoring plan so large changes can be done incrementally without breaking the build.

Steps:

1. Get the refactoring goal from $ARGUMENTS. If not provided, ask the user what they want to refactor and why.

2. Analyze the current code:
   - Identify all files and modules affected by the refactoring
   - Map dependencies between affected files
   - Check for existing test coverage on affected code
   - Note any areas with high coupling or complexity

3. Check if PLAN.md already exists in the project root. If it does, ask the user if they want to replace it or append to it.

4. Create PLAN.md with the following structure:

   **Goal**: What the refactoring achieves and why it's needed

   **Affected Files**: List of all files that will be modified or created

   **Phases**:
   - Phase 1 — Preparation: ensure tests exist for affected code, create branch
   - Phase 2-N — Incremental changes: each phase is independently committable and keeps the build green
   - Final Phase — Cleanup: remove dead code, update docs

   For each phase include:
   - Files to modify
   - What changes to make
   - Validation criteria (what to test/check after this phase)
   - Rollback strategy (how to undo if something breaks)

   **Risk Assessment**: Identify the riskiest steps and mitigation strategies

   **Session Boundaries**: Note where /xida-tools:handoff-create should be used if the refactoring spans multiple sessions

5. Present the plan to the user. Do NOT implement any changes. This command only plans, similar to how /xida-tools:bugs-collect only documents.
