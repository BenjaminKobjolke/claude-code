---
description: Research the oldest open feature, write a plan into it, move it to features/ready-to-implement/
argument-hint: [filename filter]
---

Turn one `features/` file into a researched, DRY-checked plan. Do **not**
implement — that happens later via `/features:implement`. One file per run.

Those files are written by `/features:collect`.

## Steps

### 1. Pick the feature

List the top level of `features/` — do NOT recurse, `ready-to-implement/` and
`done/` are excluded. Filenames start with `YYYY_MM_DD_`, so name order is age
order:

```
powershell -Command "Get-ChildItem 'features\*.md' -File | Sort-Object Name | Select-Object -First 1 -ExpandProperty Name"
```

If `$ARGUMENTS` is given, filter to files whose name contains it
(case-insensitive) and take the oldest match; if none match, list what is there
and ask. If the folder is missing or empty, report "no open features" and stop.

Ask the user whether to prepare that feature or postpone it. If postponed,
rename it so it becomes the newest file, so it is not picked again until all
other feature files are done.

### 2. Research

Read the file. Check `docs/` for documentation of the affected areas. Find the
files, functions and existing components/patterns the feature touches. Follow
the project's conventions and any workflow in its `CLAUDE.md`.

**Open questions gate**: if the file lists open questions, or research raises
new ones, ask the user **now** and write the answers back into the file —
`/features:implement` runs without asking.

### 3. Write the plan into the file

Append a `## Plan` section:

```markdown
## Plan

- **Files**: `path/to/file.ext` — what changes there (function/class names)
- **Reuse**: existing components/patterns to use, with paths
- **Steps**: ordered implementation steps
- **Decisions**: answers to the open questions
- **Verify**: how to check it works (tests, manual steps)
```

### 4. DRY-check the plan

Run `/plan:dry features/<file>`. It rewrites the file in place for
DRY / KISS / YAGNI.

### 5. Move to ready-to-implement/

```
powershell -Command "New-Item -ItemType Directory -Force 'features\ready-to-implement' | Out-Null; Move-Item 'features\2026_08_30_dark-mode-toggle.md' 'features\ready-to-implement\2026_08_30_dark-mode-toggle.md'"
```

### 6. Summary

Report: which feature was prepared, its path in `ready-to-implement/`, and what
remains at the top level. Do NOT edit any project source file. Suggest
`/features:implement` to build it.
