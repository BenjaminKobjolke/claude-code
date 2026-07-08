---
description: Read this project's audio notes, implement one, move it to done
---

Turn dictated audio notes into implemented changes. Process **one** unit of work
per run (a single note, or a cluster of notes about the same feature), then stop.

## Steps

### 1. Read config (gate on setup)

Read `docs/AUDIO_NOTES.md` at the project root. Get the **Project note folder**
path. If the file or that path is missing, tell the user to run
`/audio-notes:setup` first, then stop.

### 2. Check the processing/ lock

Check the `processing/` subfolder of the project note folder. If it exists and
contains any file, another process is already working — stop immediately and
report "another audio-notes run is in progress (processing/ not empty)". Do NOT
start a new task.

```
powershell -Command "if (Test-Path 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing') { (Get-ChildItem 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing\*.md' -File | Measure-Object).Count } else { 0 }"
```

If the count is greater than 0, stop.

### 3. List notes (top level only)

List markdown files at the **top level** of the project note folder. Do NOT
recurse — the `done/` subfolder (and any other subfolder) is excluded:

```
powershell -Command "Get-ChildItem 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\*.md' -File | Select-Object -ExpandProperty Name"
```

If no notes, report "no audio notes to process" and stop.

### 4. Pick one unit of work and claim it

Read the candidate notes. Select one coherent unit:

- a single note, or
- a cluster of notes about the **same feature/functionality** (e.g. two notes both
  about the launcher screen — one on item order, one on colors).

Leave notes about unrelated features for a later run.

**Claim the selected note(s):** move them into the `processing/` subfolder (create
it if absent) before implementing. This is the lock other runs check in step 2.

```
powershell -Command "New-Item -ItemType Directory -Force 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing' | Out-Null; Move-Item 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\note.md' 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing\note.md'"
```

### 5. Gather context from docs/

Notes are brief. Before implementing, read the project's `docs/` subfolder for
fuller documentation of the affected feature. Search `docs/` for files matching
the feature/keywords from the selected note(s) and read the relevant ones.

### 6. Plan, DRY-check, implement, audit

1. **Create a plan** for the change request / feature / bug fix. Follow the
   project's existing conventions and any workflow defined in its `CLAUDE.md`.

2. **DRY-check the plan**: run `/plan:dry` on the plan to catch duplication and
   YAGNI issues before writing code. Refine the plan per its findings.

3. **Implement the refined plan** in the project code. Follow existing
   conventions and any post-feature workflow in `CLAUDE.md` (tests, analyzers).

4. **Audit the result**: run `/dry:check` for a post-implementation DRY audit
   of the changed files.

### 7. Move handled notes from processing/ to done/

On success, move the claimed note file(s) from `processing/` into the `done/`
subfolder (create `done/` if it does not exist). On filename collision in `done/`,
keep both — suffix the moved file:

```
powershell -Command "New-Item -ItemType Directory -Force 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\done' | Out-Null; Move-Item 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing\note.md' 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\done\note.md'"
```

If implementation fails, move the note(s) back to the top level so they are not
left stuck in `processing/`.

### 8. Summary

Report: which note(s) were handled, what was changed, what was moved to `done/`,
and which notes remain for the next run.
