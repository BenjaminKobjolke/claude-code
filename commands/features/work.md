---
description: Implement the oldest open feature from features/, then move it to features/done/
---

Implement the **oldest** open feature file in `features/`, then archive it.
One file per run, then stop.

Those files are written by `/features:collect`.

## Steps

### 1. Pick the feature

List the top level of `features/` — do NOT recurse, `done/` is excluded.
Filenames start with `YYYY_MM_DD_`, so name order is age order:

```
powershell -Command "Get-ChildItem 'features\*.md' -File | Sort-Object Name | Select-Object -First 1 -ExpandProperty Name"
```

If `$ARGUMENTS` is given, filter to files whose name contains it
(case-insensitive) and take the oldest match; if none match, list what is there
and ask. If the folder is missing or empty, report "no open features" and stop.

Ask the user if he wants you to work on that feature. Or postpone it. If the user wants to postpone, rename it so it becomes the newst file. And therefore will not be checked again until all other feature files are done.

### 2. Read it and plan

Read the file. Check `docs/` for documentation of the affected areas before
planning.

**Open questions gate**: if the file lists open questions, ask the user and
write the answers back into the file before writing code.

Create a plan following the project's conventions and any workflow in its
`CLAUDE.md`. Run `/plan:dry` on the plan before implementing.

### 3. Implement

Implement the plan. If a step fails, stop, explain, and ask whether to fix or
create a handoff via `/handoff:create` — do NOT archive an incomplete feature.

Pre-existing bugs you stumble over: do NOT fix them here — record them with
`/bugs:plan-fix-prexisting`.

### 4. Verify

Run the project's post-feature workflow (tests, analyzers) as documented in
`CLAUDE.md`, then `/dry:check` on the changed files.

### 5. Record what was done

Append an `## Implementation` section to the bottom of the feature file:

- **Files changed** — each path with a one-line note and the key
  function/class/method names touched
- **What was done** — short summary as actually implemented
- **Notes** — edge cases, follow-ups, anything non-obvious

This keeps the diff-to-feature link discoverable without digging git history.

### 6. Archive

Change the `#` title to `# [DONE] Feature: <title>`, then move the file to
`features/done/` (create the folder if missing):

```
powershell -Command "New-Item -ItemType Directory -Force 'features\done' | Out-Null; Move-Item 'features\2026_08_30_dark-mode-toggle.md' 'features\done\2026_08_30_dark-mode-toggle.md'"
```

If the feature was dropped instead (invalid, already implemented), title it
`# [DROPPED] Feature: <title>` with a one-line reason and archive it the same way.

### 7. Document

Document the feature in a new md file in /docs/features

### 8. Summary

Report: which feature was worked, what changed, whether it was archived, and
what is left for the next run. Do NOT auto-commit — suggest `/git:commit`.
