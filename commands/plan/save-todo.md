---
description: Save the current session plan to claude-plans/todos/ for later, then clear it from the session
---

Save the plan currently held in this session to `claude-plans/todos/` so it can be implemented later, then clear the plan from session memory.

Steps:

1. Use the current plan held in this session (the plan-mode plan or the plan just discussed). If there is no plan in the session, tell the user there is nothing to save and stop.

2. Derive a short kebab-case name from the plan title/topic (e.g. `dark-mode-toggle`, `user-authentication`). This will be used in the filename.

3. Ensure the `claude-plans/todos/` directory exists in the project root. If not, create it.

4. Determine the next number: scan `claude-plans/todos/*.md`, find the highest leading `NN_` integer prefix, add 1, and zero-pad to 2 digits. Start at `01` if no numbered file exists yet.

5. **Make the saved file self-contained so no research is lost.** The session may have done heavy research (file traces, conventions, decisions) before producing the plan — after clearing the session that context is gone and would otherwise be redone at implementation time. Before writing, capture everything learned into the file. The written content = the full plan PLUS a `## Research & Findings` section containing:
   - **Relevant files** — paths and their role, i.e. the code traces already followed.
   - **Patterns / utilities / conventions to reuse** — with file paths and grep evidence.
   - **Key decisions and WHY** — including options considered and rejected.
   - **Gotchas, constraints, integration points** — anything non-obvious discovered.
   - **Open questions + their answers** — fold in anything already resolved with the user.

   Goal: a fresh session (no prior context) could implement purely from this one file.

6. Write that content to `claude-plans/todos/<NN>_<short-name>.md` (e.g. `claude-plans/todos/01_dark-mode-toggle.md`).

7. Clear the plan from session memory — this is equivalent to `/clear` of the active plan: discard the in-context plan so a fresh plan can be started. Do NOT delete the saved `.md` file you just wrote. (If the user wants a full conversation reset, they can run `/clear` themselves.)

8. Confirm the saved path to the user and STOP. Do NOT implement any part of the plan.
