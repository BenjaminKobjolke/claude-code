---
description: Implement one prepared audio note from ready-to-implement/, move it to done/
argument-hint: [filename filter]
---

Implement **one** note prepared by `/audio-notes:prepare`. Runs autonomously —
all questions were resolved during prepare, so do NOT ask the user anything.
One unit of work per run, then stop.

## Steps

### 1. Read config (gate on setup)

Read `docs/AUDIO_NOTES.md` at the project root. Get the **Project note folder**
path. If the file or that path is missing, tell the user to run
`/audio-notes:setup` first, then stop.

### 2. Check the processing/ lock

If the `processing/` subfolder exists and contains any file, another run is in
progress — stop and report "another audio-notes run is in progress
(processing/ not empty)".

```
powershell -Command "if (Test-Path 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing') { (Get-ChildItem 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing\*.md' -File | Measure-Object).Count } else { 0 }"
```

### 3. Pick a prepared note

List markdown files in `ready-to-implement/` (no recursion):

```
powershell -Command "Get-ChildItem 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\ready-to-implement\*.md' -File | Sort-Object Name | Select-Object -ExpandProperty Name"
```

If empty, report "nothing ready — run `/audio-notes:prepare` first" and stop.

If `$ARGUMENTS` is given, take the oldest file whose name contains it
(case-insensitive); otherwise the oldest by name. Pick a note that has a
`## Plan` section (skip cluster secondaries that only say `Planned in …`), and
pull those secondary notes along with it.

### 4. Claim it

Move the note(s) into `processing/`:

```
powershell -Command "New-Item -ItemType Directory -Force 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing' | Out-Null; Move-Item 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\ready-to-implement\note.md' 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing\note.md'"
```

### 5. Implement the plan

Implement the `## Plan` as written. Follow the project's conventions and its
`CLAUDE.md` post-feature workflow (tests, analyzers), then run `/dry:check` on
the changed files.

Pre-existing bugs you stumble over: do NOT fix them here — record them with
`/bugs:plan-fix-prexisting`.

### 6. Append implementation details to the note

Append an `## Implementation` section to the bottom of the note (the primary
note for a cluster). Record enough to trace the change later:

- **Files changed** — each path with a one-line note of what changed there,
  and the key function/class/method names touched.
- **What was done** — short summary of the fix/feature as implemented.
- **Notes** — anything non-obvious (edge cases, follow-ups, related code).

### 7. Move to done/

On success, move the note(s) from `processing/` into `done/` (create if
missing). On filename collision in `done/`, keep both — suffix the moved file:

```
powershell -Command "New-Item -ItemType Directory -Force 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\done' | Out-Null; Move-Item 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\processing\note.md' 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer\done\note.md'"
```

If implementation fails, move the note(s) back to `ready-to-implement/` and
report what blocked it.

### 8. Summary

Report: which note(s) were implemented, what changed (and that the
`## Implementation` section was written), what was moved to `done/`, and what
remains in `ready-to-implement/`. Do NOT auto-commit — suggest `/git:commit`.
