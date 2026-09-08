---
description: Implement feedback reports from feedback/ (bug fixes, API changes, new features requested by the other repo)
argument-hint: "[feedback-file-name]"
---

Read and implement the feedback reports in this repo's `feedback/` directory. Feedback comes from
the counterpart repo (backend ↔ frontend). A report may link to the original request file in the
other repo (e.g. `feedback/done/....md`) — read it for the intent behind the change.

CRITICAL GUARDRAILS:
- NEVER write feedback files here — ONLY implement code changes. To send feedback to the other
  repo the user runs `/feedback:write`.
- ALWAYS read feedback files completely before starting. Re-read if content seems incomplete.
- ALWAYS check existing project components, services and patterns before building anything new.
  Follow the reuse conventions in `CLAUDE.md` and `CODING_RULES.md` (widgets/components,
  DI registration, translation formats, defensive parsing, ...).
- ALWAYS check for DRY opportunities — prefer one shared component/service over per-file changes.

Steps:

1. List all `.md` files in `feedback/` at the project root. If the directory does not exist or
   is empty, tell the user there are no feedback reports to process.

2. If $ARGUMENTS is provided, find the matching feedback file (partial match on filename,
   case-insensitive). If multiple match, list them and ask the user to pick one. If none match,
   show available files. If no $ARGUMENTS, process **all** feedback files sequentially (oldest
   first). Do NOT ask the user which one to work on.

3. Read each feedback file **completely** — do not skim or assume content. Present a summary to
   the user: title and timestamp, who triggered it, the core issue described.

4. **For each feedback file**, repeat steps 5–10 before moving to the next file:

5. **Convention check**: Search the codebase for existing patterns related to this change.
   Identify reusable components, services and conventions that must be used. List what you found.

6. **Investigate**: Search the codebase for the relevant code mentioned in the feedback.
   Understand the root cause of the issue described.

7. **Implement**: Present a brief summary of what you're changing, then make the code changes
   immediately. Do NOT wait for user approval. Use existing project components — never build a
   new one where one already exists.

8. **DRY check**: Review your changes. If you modified multiple files with similar patterns,
   check if a single shared component/service would be better.

9. **Verify**: Run the post-change verify workflow described in `CLAUDE.md` (test / analyze /
   fix scripts, restart steps if listed) and check the stack conventions `CLAUDE.md` names
   (e.g. new widgets registered in a component gallery, DI registrations, translation key
   format).

10. If verification passes, move the feedback file to `feedback/done/` (create the subdirectory
    if it does not exist). If verification fails, report the failures and ask the user how to
    proceed.

11. **Follow-up for the counterpart** (only when this repo is the backend):

    Resolve the counterpart repo:
    - `.claude/related-projects.md` if it exists;
    - else the `## Related Projects` section of `CLAUDE.md`;
    - else ask the user and store the answer in `.claude/related-projects.md` (gitignored,
      machine-local).

    The entry's label tells the role: `Frontend` / `App` ⇒ this repo is the backend;
    `Backend` / `API` ⇒ this repo is the frontend.

    If this repo is the backend and the processed feedback changed anything the frontend must
    adapt to (new/changed endpoints, response fields, behavior), write a new
    `yyyy_mm_dd_TITLE.md` into `<counterpart>/feedback/` (create the dir if missing) describing
    what the frontend now has to implement, with endpoint paths, methods and request/response
    examples. Reference the processed file, e.g. `feedback/done/....md`. Skip for backend-only
    changes. If this repo is the frontend, write nothing.

12. After all feedback files are processed, tell the user they can commit with `/git:commit`.
