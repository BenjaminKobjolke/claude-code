---
description: Plan a new feature as ordered phase files in plan/<feature-name>/ for sequential implementation
argument-hint: <feature description>
---

IMPORTANT: This is a PLANNING-ONLY command. You MUST NOT edit, create, or modify any project source files. The ONLY files you may create or write to are inside `plan/<feature-name>/`. Do NOT implement any code. Your job is finished once you present the phase summary.

Research and plan a new feature, writing it directly as ordered phase files instead of one large plan. Each phase is implemented later, one at a time, with `/plan:implement-phase`.

## Steps

1. Get the feature description from `$ARGUMENTS`. If not provided, ask the user what feature they want to plan.

2. Derive a short kebab-case `<feature-name>` from the feature description (e.g. `user-authentication`, `dark-mode-toggle`). This is the folder name.

3. Research the current codebase to understand how to implement the feature:
   - Identify the project's tech stack, frameworks, and patterns
   - Find existing code that relates to or would be affected by the feature
   - Map dependencies and integration points
   - **Convention check**: Grep for existing UI components, widgets, and reusable patterns related to this feature. List them explicitly — these MUST be reused in the plan (do not assume, verify by searching)
   - Check for existing utilities, helpers, or patterns that should be reused
   - Note any configuration or infrastructure that would need changes
   - Check translation format conventions (e.g. :param vs %param%) and DI container patterns

4. **Open Questions gate — now**: phases are implemented later without asking. Present every open question or decision to the user and wait for answers before writing. Record the answers as Decisions in `00-context.md`. Only questions that genuinely cannot be answered yet stay under Open Questions.

5. Ensure `plan/` exists in the project root. If `plan/<feature-name>/` already exists, ask the user whether to replace it or choose a different name.

6. **Cut the work into phases** by dependency and area. Phase rules:
   - A fresh session with only `00-context.md` + one phase file can implement that phase. No research may be lost: everything learned in step 3 (file traces, patterns to reuse with paths, decisions and why, gotchas, integration points) must land in `00-context.md` or the phase that needs it.
   - Phases are ordered by dependency. After each phase the build/tests are green and the change is committable on its own.
   - 3–8 phases, each small enough for one session. Typical cut: setup/tooling → scaffold → core → feature slices → tests (or tests interleaved per slice) → docs → verification.
   - Every step, file path, and decision lands in `00-context.md` or exactly one phase file.

7. **Write the files** in this exact layout:

   ```
   plan/<feature-name>/
     00-context.md        shared reference — never implemented, always read first
     01-<kebab>.md        phase 1
     02-<kebab>.md        …
     NN-<kebab>.md        last phase: end-to-end verification + out of scope
     done/                created later by /plan:implement-phase
   ```

   `00-context.md`:

   ```markdown
   # Context — <Feature title> (shared reference for all phases)

   <what + why, 3–8 lines; project/stack summary; how the codebase works today in the touched areas>

   ## Decisions taken with the user
   | Topic | Decision |
   |---|---|

   ## Facts the phases rely on
   <APIs, conventions, existing patterns/utilities to reuse — with file paths and grep evidence>

   ## Open Questions
   <unresolved only; answered ones belong in Decisions>

   ## Phases
   | File | Phase | Depends on |
   |---|---|---|
   ```

   Each `NN-<kebab>.md`:

   ```markdown
   # Phase N — <Title>

   Shared context: [00-context.md](00-context.md). Depends on Phase N-1 (or "none").

   <ordered steps: what to do, which files to modify or create, which existing patterns to reuse (paths)>

   ## Verify
   <what must be green before the next phase: analyze / tests / build / manual check>
   ```

8. Present a brief summary (the phase table) and suggest `/plan:implement-phase <feature-name>`. Then STOP COMPLETELY.
   - Do NOT proceed to implement any part of the plan.
   - Do NOT edit, create, or modify any project files besides the files in `plan/<feature-name>/`.
