# Version
2

# Coding Rules (Pointer)

This project's rules live in two files in the project root:

- `CODING_RULES.md` — code quality and conventions. BINDING for all code work in
  this repository, always.
- `IMPLEMENTATION_FLOW.md` — the end-to-end flow to follow when planning and
  implementing a change (checks, gates, Definition of Done).

MANDATORY: Before writing or editing ANY code, you MUST Read BOTH files in full
**in the current session**. Do not rely on memory of a previous session, a
summary, or partial reads.

If you are about to make a code change and have not read both files in this
session: STOP, read them, then continue.

An external tool may orchestrate the implementation itself. When a skill or run
states that the implementation is orchestrated, ignore `IMPLEMENTATION_FLOW.md`
entirely — the orchestrator runs those steps as its own phases. `CODING_RULES.md`
stays binding either way.

Do not inline rules back into this file and do not use `@import` for either file —
they are intentionally referenced, not imported.

## graphify

This project's code directory is commands/ (tools/ and validate-code/ are not in the graph).

## Post-Implementation Code Analysis

After **any** of the following events, run the changed-file analyzer and fix every reported issue that applies to your changes before considering the work complete:

- A new feature has been implemented
- A plan from `claude-plans/` has been finished
- A bug has been fixed

### How to run

```bash
powershell -Command "cd 'D:\GIT\BenjaminKobjolke\claude-code'; cmd /c '.\tools\analyze_changed_and_new_files.bat'"
```

This runs cli-code-analyzer with `--only-changed`, so it reports only files new or modified vs git `HEAD` (including untracked, excluding deletes).

### When to run the full analyzer instead

Run `tools/analyze_code.bat` (whole tree) for an explicit audit request (`/analyze:run-and-fix`), exception maintenance (`/analyze:improve-exceptions`), before a release or merge, after refactors that touch shared code, or when the working tree is clean vs `HEAD`.

### Workflow

1. Run the changed-files batch file above.
2. Read the per-rule CSV reports under `code_analysis_results/`; a missing CSV means that rule found nothing.
3. Fix every error and warning that applies to your changes.
4. Re-run until clean. The analyzer's result cache self-invalidates when source files change.

