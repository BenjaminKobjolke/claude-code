---
description: Implement all plans in claude-plans/todos/ until every plan is finished
---

**Goal: all plans in `claude-plans/todos/` finished.**

Implement every saved plan in `claude-plans/todos/`, one after another, until none remain.

Steps:

1. List all `.md` files directly in `claude-plans/todos/`, excluding anything inside `claude-plans/todos/done/`. If there are none, tell the user there are no todos to implement and suggest they save one with `/plan:save-todo`, then stop.

2. Process the todos in ascending numeric order by their leading `NN_` prefix.

3. For each todo plan, in order:
   - Read the plan file completely, including its `## Research & Findings` section (the research captured when the plan was saved).
   - **Light re-verify**: treat the embedded research as your starting point — do NOT redo the research from scratch. Quickly confirm the key referenced files/symbols still exist (a cheap sanity check). If something referenced has moved, been renamed, or no longer exists, note it and re-research only that specific gap.
   - **Open Questions gate**: if the plan has an "Open Questions" section with unresolved questions, present each to the user, wait for answers to ALL of them, write the answers back into the file, and only then continue.
   - Implement the plan step by step. Announce which step you are starting and report what was done before moving to the next step.
   - **On failure**: stop immediately, explain what went wrong, and ask the user whether to attempt a fix or create a handoff via `/handoff:create`. Do NOT move the file to `done/` if implementation is incomplete.
   - When the plan is fully implemented, ensure `claude-plans/todos/done/` exists and move the file there, prefixing the filename with today's date in `YYYYMMDD_` format (e.g. `01_dark-mode-toggle.md` becomes `claude-plans/todos/done/20260529_01_dark-mode-toggle.md`).

4. **Only after ALL todos are implemented and moved to `done/`**, run analysis/code-checking ONCE: `/validate:pre-commit`. If validation fails, fix the issues and re-run until it passes. Do NOT run analysis or code-checking between individual todos — only this single pass at the end.

5. Tell the user all plans are finished and suggest they review the changes and commit with `/git:commit`. Do NOT auto-commit.
