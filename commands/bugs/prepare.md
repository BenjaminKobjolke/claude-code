---
description: Research the oldest open-issues file, write a plan per issue, move it to open-issues/ready-to-implement/
argument-hint: [filename filter]
---

Turn one `open-issues/` file into a researched, DRY-checked plan. Do **not**
fix anything — that happens later via `/bugs:implement`. One file per run.

Those files are written by `/bugs:collect`, `/analyze:run-and-fix`,
`/analyze:fix-only` and `/bugs:plan-fix-prexisting`.

## Steps

### 1. Pick the file

List the top level of `open-issues/` — do NOT recurse, `ready-to-implement/`
and `done/` are excluded. Filenames are `YYYY_MM_DD.md`, name order is age order:

```
powershell -Command "Get-ChildItem 'open-issues\*.md' -File | Sort-Object Name | Select-Object -ExpandProperty Name"
```

If the folder is missing or empty, report "no open issues" and stop.

If `$ARGUMENTS` is given, take the oldest file whose name contains it; otherwise
the oldest file.

### 2. Research

Read the file. It holds one `##` section per issue; sections already prefixed
`[FIXED]` or `[DROPPED]` are done — skip them. Check `docs/` for documentation
of the affected features.

For each open issue, find the files and layer the fix belongs in, and existing
patterns/components to reuse. Follow the project's conventions and any workflow
in its `CLAUDE.md`. If an issue is ambiguous, ask the user **now** —
`/bugs:implement` runs without asking.

### 3. Write a plan under each issue

Append to each open `##` section:

```markdown
- **Plan**:
  - `path/to/file.ext` — what changes there (function/class names)
  - reuse: existing helper/pattern, with path
  - steps: ordered fix steps
  - verify: test to add or run
```

An issue that turns out invalid or already fixed: mark its heading
`## [DROPPED] <original title>` with a one-line reason instead of a plan.

### 4. DRY-check the plan

Run `/plan:dry open-issues/<file>`. It rewrites the file in place for
DRY / KISS / YAGNI.

### 5. Move to ready-to-implement/

```
powershell -Command "New-Item -ItemType Directory -Force 'open-issues\ready-to-implement' | Out-Null; Move-Item 'open-issues\2026_08_29.md' 'open-issues\ready-to-implement\2026_08_29.md'"
```

### 6. Summary

Report: which file was prepared, how many issues got a plan, which were dropped
and why, and what remains at the top level. Do NOT edit any project source
file. Suggest `/bugs:implement` to fix them.
