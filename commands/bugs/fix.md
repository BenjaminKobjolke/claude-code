---
description: Fix all issues of one open-issues file with a structured workflow
---

Pick **one** `open-issues/` file and fix every issue in it, using a structured
confirm-then-fix workflow per issue to prevent wrong-layer fixes. One file per
run, then stop.

## Steps

### 1. Pick the file

List the top level of `open-issues/` — do NOT recurse, `done/` is excluded.
Filenames are `YYYY_MM_DD.md`, name order is age order:

```
powershell -Command "Get-ChildItem 'open-issues\*.md' -File | Sort-Object Name | Select-Object -ExpandProperty Name"
```

If the folder is missing or empty, tell the user to document bugs first with
`/bugs:collect` or `/bugs:plan-fix-prexisting`, and stop.

If `$ARGUMENTS` is provided, match it against the filenames (partial match). If
several match, list them and ask which one. If no `$ARGUMENTS`, list the files
and ask which one to work off, defaulting to the oldest.

Read the chosen file. It holds one `##` section per issue; sections already
prefixed `[FIXED]` or `[DROPPED]` are done — skip them. Check `docs/` for
documentation of the affected features before planning.

### 2. Work the issues one at a time

Repeat steps 3–9 for each open `##` section in the file, oldest first. Group
related issues into one pass where that is obviously cheaper.

### 3. Confirm fix target

Before making any changes, present:
- The issue section from the open-issues file
- The file(s) and layer you believe the fix belongs in

Ask the user to confirm this is the right target.

### 4. Validate approach

Present your proposed fix strategy (what to change and why). Wait for user
approval before implementing.

### 5. Write a failing test

Before writing any fix, create a test that reproduces the bug. Run the test
suite to confirm it fails. If the project has no test infrastructure, skip this
step and note it.

### 6. Implement the fix

Make the minimal code changes. Check for existing project patterns and
components before writing new code.

### 7. Run tests

Confirm the failing test now passes and no other tests broke. Iterate if not.

### 8. Verify

Run `/validate:pre-commit`. Also check:
- DI container includes any new services
- Translation keys use the project's format conventions
- No raw HTML where project widgets exist

New pre-existing issues you stumble over: do NOT fix them here — append them to
**today's** `open-issues/YYYY_MM_DD.md` via `/bugs:plan-fix-prexisting`.

### 9. Mark it off and move on

If validation passes, change the issue's `##` heading to
`## [FIXED] <original title>`. If it turned out invalid or already fixed, use
`## [DROPPED] <original title>` with a one-line reason.

Then go back to step 3 with the next open issue in the file. Only continue to
step 10 once no open sections are left.

### 10. Archive

Only when **every** section in the file is `[FIXED]` or `[DROPPED]`, move it to
`open-issues/done/` (create the folder if missing):

```
powershell -Command "New-Item -ItemType Directory -Force 'open-issues\done' | Out-Null; Move-Item 'open-issues\2026_08_29.md' 'open-issues\done\2026_08_29.md'"
```

Otherwise leave it — the remaining sections are the next run's work.

### 11. Summary

Report which file was worked, what was fixed, what was dropped and why, what is
left, whether the file was archived, and that the user can commit with
`/git:commit`.
