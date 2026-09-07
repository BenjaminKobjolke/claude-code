---
description: Research one audio note, write a plan into it, move it to ready-to-implement/
---

Turn one dictated audio note (or a cluster about the same feature) into a
researched, DRY-checked plan. Do **not** implement — that happens later via
`/audio-notes:implement`. One unit of work per run, then stop.

## Steps

### 1. Read config (gate on setup)

Read `docs/AUDIO_NOTES.md` at the project root. Get the **Project note folder**
path. If the file or that path is missing, tell the user to run
`/audio-notes:setup` first, then stop.

### 2. Check the processing/ lock

Check the `processing/` subfolder of the project note folder. If it exists and
contains any file, another process is already working — stop immediately and
report "another audio-notes run is in progress (processing/ not empty)".

```
powershell -Command "if (Test-Path 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing') { (Get-ChildItem 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing\*.md' -File | Measure-Object).Count } else { 0 }"
```

If the count is greater than 0, stop.

### 3. List notes (top level only)

List markdown files at the **top level** of the project note folder. Do NOT
recurse — `ready-to-implement/`, `done/` and any other subfolder are excluded:

```
powershell -Command "Get-ChildItem 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\*.md' -File | Select-Object -ExpandProperty Name"
```

If no notes, report "no audio notes to prepare" and stop.

### 4. Pick one unit of work and claim it

Read the candidate notes. Select one coherent unit:

- a single note, or
- a cluster of notes about the **same feature/functionality** (e.g. two notes both
  about the launcher screen — one on item order, one on colors).

Leave notes about unrelated features for a later run.

**Claim the selected note(s):** move them into the `processing/` subfolder (create
it if absent). This is the lock other runs check in step 2.

```
powershell -Command "New-Item -ItemType Directory -Force 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing' | Out-Null; Move-Item 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\note.md' 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing\note.md'"
```

### 5. Gather context from docs/ and prior notes

Notes are brief. Read the project's `docs/` subfolder for fuller documentation
of the affected feature. Search `docs/` for files matching the feature/keywords
from the selected note(s) and read the relevant ones.

A note may reference an earlier issue/task (a follow-up, a bug in a prior change,
or a change request). If so, search the `done/` subfolder for the previous
note(s) on the same feature/keywords and read them — including any
`## Implementation` section — to recover the files changed and full context.

Research the codebase: find the files, functions and existing components /
patterns the change touches. Follow the project's conventions and any workflow
in its `CLAUDE.md`.

### 6. Write the plan into the note

If anything is ambiguous, ask the user **now** and write the answer into the
plan — `/audio-notes:implement` runs without asking.

Append a `## Plan` section to the bottom of the primary note:

```markdown
## Plan

- **Files**: `path/to/file.ext` — what changes there (function/class names)
- **Reuse**: existing components/patterns to use, with paths
- **Steps**: ordered implementation steps
- **Decisions**: answers to questions resolved with the user
- **Verify**: how to check it works (tests, manual steps)
```

For a cluster, append to each secondary note a single line:
`Planned in <primary>.md`.

### 7. DRY-check the plan

Run `/plan:dry` with the full path of the primary note. It rewrites the file in
place for DRY / KISS / YAGNI.

### 8. Move to ready-to-implement/

Move the claimed note(s) from `processing/` into the `ready-to-implement/`
subfolder (create it if missing):

```
powershell -Command "New-Item -ItemType Directory -Force 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\ready-to-implement' | Out-Null; Move-Item 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing\note.md' 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\ready-to-implement\note.md'"
```

If preparation fails, move the note(s) back to the top level so they are not
left stuck in `processing/`.

### 9. Summary

Report: which note(s) were prepared, the path in `ready-to-implement/`, and
which notes remain at the top level. Do NOT edit any project source file.
Suggest `/audio-notes:implement` to build it.
