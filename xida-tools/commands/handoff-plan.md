---
description: Create a handoff for a planned but not yet implemented feature
---

Create a HANDOFF.md that hands off the current Claude Code plan for implementation by a fresh agent.

Steps:

1. Look for plan files (`.md` files) in the `.claude/plans/` directory. If the directory does not exist or contains no `.md` files, tell the user: "No active plans found. Use plan mode to create a plan first." and stop.

2. If there are multiple plan files, pick the most recently modified one.

3. Read the plan file thoroughly.

4. Check if HANDOFF.md already exists in the project root. If it exists, delete it.

5. Create HANDOFF.md with the following structure, filled in from the plan:

   # Handoff Document

   **Status**: planned

   ## Goal

   The goal of the plan. Be specific about the end state.

   ## Environment

   - OS: (detected)
   - Language/Framework: (detected)
   - Package Manager: (detected)

   ## Plan Summary

   A clear summary of the planned changes derived from the plan file.

   ## Files to Modify or Create

   List all files mentioned in the plan that need to be modified or created.

   ## Implementation Steps

   Ordered action items derived from the plan:
   1. First implementation step
   2. Second implementation step
   3. ...

   ## Open Questions

   Any unresolved questions or decisions from the plan that need user input before implementation.

6. Save as HANDOFF.md in the project root and tell the user the file path so they can start a fresh conversation with: "Read @HANDOFF.md and implement the plan."
