---
description: Plan a new feature by researching the codebase and storing the plan in the project's plan directory
---

IMPORTANT: This is a PLANNING-ONLY command. You MUST NOT edit, create, or modify any project source files. The ONLY file you may create or write to is the plan file inside the `plan/` directory. Do NOT implement any code. Do NOT create any files beyond the plan file. Your job is finished once you present the plan summary.

Research and plan a new feature for the current project without implementing any code changes.

Steps:

1. Get the feature description from $ARGUMENTS. If not provided, ask the user what feature they want to plan.

2. Derive a short kebab-case name from the feature description (e.g. "user-authentication", "dark-mode-toggle"). This will be used as the plan filename.

3. Research the current codebase to understand how to implement the feature:
   - Identify the project's tech stack, frameworks, and patterns
   - Find existing code that relates to or would be affected by the feature
   - Map dependencies and integration points
   - **Convention check**: Grep for existing UI components, widgets, and reusable patterns related to this feature. List them explicitly — these MUST be reused in the plan (do not assume, verify by searching)
   - Check for existing utilities, helpers, or patterns that should be reused
   - Note any configuration or infrastructure that would need changes
   - Check translation format conventions (e.g. :param vs %param%) and DI container patterns

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

   ## Existing Patterns to Reuse
   List of existing components, widgets, utilities, and conventions found during research that MUST be used in the implementation. Include file paths and grep evidence.

   ## Implementation Plan
   Numbered steps describing what to build and where, in order of execution.
   Each step should include:
   - What to do
   - Which files to modify or create
   - Key implementation details and patterns to follow
   - Which existing components/patterns to reuse (reference the section above)

   ## Open Questions
   Uncertainties or decisions that need user input before implementation.

7. Present a brief summary of the plan to the user, then STOP COMPLETELY.
   - Do NOT proceed to implement any part of the plan.
   - Do NOT edit, create, or modify any project files besides the plan file.
   - Do NOT write any code, tests, or configuration changes.
   - Your task is FINISHED. The user will decide when and how to implement the plan.
