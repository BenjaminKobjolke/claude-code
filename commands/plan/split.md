---
description: Split an existing plan (file or current session plan) into ordered phase files in plan/YYYYMMDD_<feature-name>/
argument-hint: [plan-path]
---

IMPORTANT: This is a PLANNING-ONLY command. You MUST NOT edit, create, or modify any project source files. The ONLY files you may create or write to are inside `plan/YYYYMMDD_<feature-name>/`. Do NOT implement any code.

Turn one large plan into ordered phase files that can be implemented one at a time with `/plan:implement-phase`. Each phase must be independently implementable by a fresh session and leave the build green.

## Steps

1. **Source plan**:
   - If `$ARGUMENTS` is given, it is exactly one path to a plan file (`plan/x.md`, `PLAN.md`, `claude-plans/x.md`, absolute paths allowed). Read it completely.
   - If no argument is given, use the plan currently held in this session (the plan-mode plan or the plan just discussed).
   - If neither exists, tell the user there is nothing to split and stop.

2. Derive a short kebab-case `<feature-name>` from the plan title (fallback: the source filename, stripping any `YYYYMMDD_` or `NN_` prefix and the `.md` extension). The folder name is that name prefixed with today's date in `YYYYMMDD_` format (e.g. `20260908_dark-mode-toggle`) — strip the source prefix first so the date is never doubled.

3. Ensure `plan/` exists in the project root. If `plan/YYYYMMDD_<feature-name>/` already exists, ask the user whether to replace it or choose a different name.

4. **Cut the plan into phases** by dependency and area. Phase rules:
   - A fresh session with only `00-context.md` + one phase file can implement that phase. No research may be lost: everything the source plan learned (file traces, patterns to reuse with paths, decisions and why, gotchas, integration points) must land in `00-context.md` or the phase that needs it.
   - Phases are ordered by dependency. After each phase the build/tests are green and the change is committable on its own.
   - 3–8 phases, each small enough for one session. Typical cut: setup/tooling → scaffold → core → feature slices → tests (or tests interleaved per slice) → docs → verification.
   - Nothing from the source is dropped: every step, file path, decision and open question lands in `00-context.md` or exactly one phase file. Each phase header names the source step(s) it came from.
   - Do not re-research the codebase and do not invent requirements. Only restructure what the source already contains.

5. **Write the files** in this exact layout:

   ```
   plan/YYYYMMDD_<feature-name>/
     00-context.md        shared reference — never implemented, always read first
     01-<kebab>.md        phase 1
     02-<kebab>.md        …
     NN-<kebab>.md        last phase: end-to-end verification + out of scope
   (finished phases move to plan/done/YYYYMMDD_<feature-name>/ — created later by /plan:implement-phase)
   ```

   `00-context.md`:

   ```markdown
   # Context — <Feature title> (shared reference for all phases)

   <what + why, 3–8 lines; project/stack summary; source plan path>

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

   Shared context: [00-context.md](00-context.md). Was "Step X" in <source file>. Depends on Phase N-1 (or "none").

   <ordered steps: what to do, which files to modify or create, which existing patterns to reuse (paths)>

   ## Verify
   <what must be green before the next phase: analyze / tests / build / manual check>
   ```

6. **Source handling**: if the source was a top-level `plan/<x>.md`, move it to `plan/YYYYMMDD_<feature-name>/original.md` so `/plan:implement` no longer lists it. Any other source (session plan, `PLAN.md`, `claude-plans/…`) is left untouched.

7. Present a summary: the phase table from `00-context.md` and where the source went. Suggest `/plan:implement-phase <feature-name>` (the bare name is enough — the date prefix does not have to be typed). Then STOP — do NOT implement any part of the plan.
