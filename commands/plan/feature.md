---
description: Plan a new feature by researching the codebase and storing the plan in the project's plan directory
---

Research and plan a new feature for the current project without implementing any code changes.

Steps:

1. Get the feature description from $ARGUMENTS. If not provided, ask the user what feature they want to plan.

2. Derive a short kebab-case name from the feature description (e.g. "user-authentication", "dark-mode-toggle"). This will be used as the plan filename.

3. Research the current codebase to understand how to implement the feature:
   - Identify the project's tech stack, frameworks, and patterns
   - Find existing code that relates to or would be affected by the feature
   - Map dependencies and integration points
   - Check for existing utilities, helpers, or patterns that should be reused
   - Note any configuration or infrastructure that would need changes

4. Ensure the `plan/` directory exists in the project root. If not, create it.

5. Check if a plan file with the derived name already exists in `plan/`. If it does, ask the user if they want to replace it or choose a different name.

6. Create `plan/<feature-name>.md` with the following structure:

   # Feature: <feature title>

   ## Goal
   What this feature achieves and why it's needed.

   ## Current State
   How the codebase works today in the areas this feature will touch.

   ## Affected Files
   List of all files that will need to be modified or created, grouped by purpose.

   ## Implementation Plan
   Numbered steps describing what to build and where, in order of execution.
   Each step should include:
   - What to do
   - Which files to modify or create
   - Key implementation details and patterns to follow

   ## Open Questions
   Uncertainties or decisions that need user input before implementation.

7. Present a summary of the plan to the user. Do NOT implement any changes. This command only plans and documents.
