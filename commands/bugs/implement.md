---
description: Fix all issues of one prepared open-issues file, then move it to open-issues/done/
argument-hint: [filename filter]
---

Fix every issue in **one** file prepared by `/bugs:prepare`. Runs autonomously —
all questions were resolved during prepare, so do NOT ask the user anything.
One file per run, then stop.

## Steps

### 1. Pick the file

```
powershell -Command "Get-ChildItem 'open-issues\ready-to-implement\*.md' -File | Sort-Object Name | Select-Object -ExpandProperty Name"
```

If empty, report "nothing ready — run `/bugs:prepare` first" and stop.

If `$ARGUMENTS` is given, take the oldest file whose name contains it; otherwise
the oldest file.

### 2. Implement

Read the file. For each open `##` section (skip `[FIXED]` / `[DROPPED]`),
implement its `**Plan**`. Group related issues where that is obviously cheaper.
Follow the project's conventions and any workflow in its `CLAUDE.md`.

After each issue, change its heading to `## [FIXED] <original title>`. If it
turns out invalid or already fixed, use `## [DROPPED] <original title>` with a
one-line reason.

### 3. Verify

Run the project's post-feature workflow (tests, analyzers) as documented in
`CLAUDE.md`, then `/dry:check` on the changed files.

New pre-existing issues you stumble over: do NOT fix them here — append them to
**today's** top-level `open-issues/YYYY_MM_DD.md` via `/bugs:plan-fix-prexisting`.

### 4. Archive

Only when every section in the file is `[FIXED]` or `[DROPPED]`, move it to
`open-issues/done/` (create the folder if missing):

```
powershell -Command "New-Item -ItemType Directory -Force 'open-issues\done' | Out-Null; Move-Item 'open-issues\ready-to-implement\2026_08_29.md' 'open-issues\done\2026_08_29.md'"
```

If anything is left unfixed, leave the file in `ready-to-implement/` — the
remaining sections are the next run's work. Say so in the summary.

### 5. Summary

Report: which file was worked, what was fixed, what was dropped and why, what is
left, and whether the file was archived. Do NOT auto-commit — suggest
`/git:commit`.
