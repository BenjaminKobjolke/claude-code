---
description: Fix a single bug from open-issues/ with a structured workflow
---

Fix one bug using a structured confirm-then-fix workflow to prevent wrong-layer
fixes. For working off a whole file at once, use `/bugs:work` instead.

## Steps

### 1. Find the issue

List the top level of `open-issues/` — do NOT recurse, `done/` is excluded.
Filenames are `YYYY_MM_DD.md`, name order is age order:

```
powershell -Command "Get-ChildItem 'open-issues\*.md' -File | Sort-Object Name | Select-Object -ExpandProperty Name"
```

If the folder is missing or empty, tell the user to document bugs first with
`/bugs:collect` or `/bugs:plan-fix-prexisting`, and stop.

Read the files. Each holds one `##` section per issue; sections already prefixed
`[FIXED]` or `[DROPPED]` are done — skip them.

If `$ARGUMENTS` is provided, find the matching `##` section (partial match,
case-insensitive). If several match, list them and ask which one. If none match,
show the open ones. If no `$ARGUMENTS`, default to the oldest file and list its
open issues, then ask which to work on.

### 2. Confirm fix target

Before making any changes, present:
- The issue section from the open-issues file
- The file(s) and layer you believe the fix belongs in

Ask the user to confirm this is the right target.

### 3. Validate approach

Present your proposed fix strategy (what to change and why). Wait for user
approval before implementing.

### 4. Write a failing test

Before writing any fix, create a test that reproduces the bug. Run the test
suite to confirm it fails. If the project has no test infrastructure, skip this
step and note it.

### 5. Implement the fix

Make the minimal code changes. Check for existing project patterns and
components before writing new code.

### 6. Run tests

Confirm the failing test now passes and no other tests broke. Iterate if not.

### 7. Verify

Run `/validate:pre-commit`. Also check:
- DI container includes any new services
- Translation keys use the project's format conventions
- No raw HTML where project widgets exist

New pre-existing issues you stumble over: do NOT fix them here — append them to
**today's** `open-issues/YYYY_MM_DD.md` via `/bugs:plan-fix-prexisting`.

### 8. Mark it off

If validation passes, change the issue's `##` heading to
`## [FIXED] <original title>`. If it turned out invalid or already fixed, use
`## [DROPPED] <original title>` with a one-line reason.

### 9. Archive

Only when **every** section in that file is `[FIXED]` or `[DROPPED]`, move it to
`open-issues/done/`:

```
powershell -Command "New-Item -ItemType Directory -Force 'open-issues\done' | Out-Null; Move-Item 'open-issues\2026_08_29.md' 'open-issues\done\2026_08_29.md'"
```

Otherwise leave it — the remaining sections are the next run's work.

### 10. Summary

Report what was fixed, whether the file was archived, what is left, and that the
user can commit with `/git:commit`.
