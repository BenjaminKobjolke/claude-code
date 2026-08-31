---
description: Work off the oldest open-issues file, then move it to open-issues/done/
---

Fix the issues collected in the **oldest** `open-issues/` file, then archive it.
One file per run, then stop.

Those files are written by `/bugs:collect`, `/analyze:run-and-fix`, `/analyze:fix-only` and
`/bugs:plan-fix-prexisting` — pre-existing issues that were deliberately left
out of scope at the time.

## Steps

### 1. Pick the oldest file

List the top level of `open-issues/` — do NOT recurse, `done/` is excluded.
Filenames are `YYYY_MM_DD.md`, so name order is age order:

```
powershell -Command "Get-ChildItem 'open-issues\*.md' -File | Sort-Object Name | Select-Object -First 1 -ExpandProperty Name"
```

If the folder is missing or empty, report "no open issues" and stop.

### 2. Read it and plan

Read the file. It holds one `##` section per issue. Check `docs/` for
documentation of the affected features before planning.

Create a plan covering the issues in the file. Group related ones. Follow the
project's conventions and any workflow in its `CLAUDE.md`.

Run `/plan:dry` on the plan before writing code.

### 3. Implement

Implement the plan. After each issue, tick it off in the file:
change its `##` heading to `## [FIXED] <original title>`.

If an issue turns out to be invalid or already fixed, mark it
`## [DROPPED] <original title>` with a one-line reason.

### 4. Verify

Run the project's post-feature workflow (tests, analyzers) as documented in
`CLAUDE.md`, then `/dry:check` on the changed files.

New pre-existing issues you stumble over while working: do NOT fix them here —
append them to **today's** `open-issues/YYYY_MM_DD.md` (a different file from
the one you are working off, unless you happen to be working off today's).

### 5. Archive

Only when every section in the file is `[FIXED]` or `[DROPPED]`, move it to
`open-issues/done/` (create the folder if missing):

```
powershell -Command "New-Item -ItemType Directory -Force 'open-issues\done' | Out-Null; Move-Item 'open-issues\2026_08_29.md' 'open-issues\done\2026_08_29.md'"
```

If anything is left unfixed, leave the file where it is — the remaining sections
are the next run's work. Say so in the summary.

### 6. Summary

Report: which file was worked, what was fixed, what was dropped and why, what is
left, and whether the file was archived.
