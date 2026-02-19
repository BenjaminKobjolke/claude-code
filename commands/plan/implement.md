---
description: Implement a feature plan from the plan/ directory
---

Pick up a plan file from `plan/` and implement it step by step.

Steps:

1. List all `.md` files in the `plan/` directory, excluding any files inside `plan/done/`. If no plan files exist, tell the user there are no plans to implement and suggest they create one with `/plan:feature`.

2. If `$ARGUMENTS` is provided, filter the list to files whose name contains the argument as a partial match (case-insensitive). If exactly one plan matches, auto-select it. If multiple plans match, list them and ask the user to choose. If none match, show available plans and ask the user to pick one.

3. If no `$ARGUMENTS` is provided and there are multiple plans, list them all and ask the user to choose one.

4. Read the selected plan file completely.

5. **Open Questions gate**: Check if the plan has an "Open Questions" section with unresolved questions. If it does:
   - Present each open question to the user
   - Wait for answers to ALL questions before proceeding
   - Write the answers back into the plan file under each question
   - Only continue once all questions are resolved

6. **Implement step by step**: Follow the "Implementation Plan" section in order. For each step:
   - Announce which step you are starting
   - Implement the changes described in that step
   - Report what was done before moving to the next step

7. **On failure**: If any step fails or you encounter an unexpected problem:
   - Stop immediately
   - Explain what went wrong
   - Ask the user if they want to attempt a fix or create a handoff via `/handoff:create`
   - Do NOT move the plan to `done/` if implementation is incomplete

8. After all implementation steps are complete, run `/validate:pre-commit`. If validation fails, fix the issues and re-run validation until it passes.

9. Ensure `plan/done/` directory exists. Move the plan file from `plan/` to `plan/done/`.

10. Tell the user the implementation is complete and suggest they review the changes and commit with `/git:commit`. Do NOT auto-commit.
