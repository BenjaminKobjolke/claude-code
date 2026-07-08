---
description: Record audio-notes folder paths in docs/AUDIO_NOTES.md
---

Set up the audio-notes paths this project needs so `/audio-notes:work` knows
where to find dictated notes. Paths are stored in `docs/AUDIO_NOTES.md` at the
project root (`$CLAUDE_PROJECT_DIR/docs/AUDIO_NOTES.md`).

## Steps

### 1. Locate the config file

Check for `docs/AUDIO_NOTES.md` at the project root. Create the `docs/` folder if
it does not exist.

### 2. Check for existing config (idempotent)

If `docs/AUDIO_NOTES.md` exists AND already contains both a **Base path** and a
**Project note folder** value, report the two paths and stop — nothing to do.

### 3. Ask the user for the paths

If config is missing or incomplete, ask the user for:

- **Base audio-notes path** — the sync root holding all projects' notes, e.g.
  `E:\[--Sync--]\Notes_Audio`.
- **Project note folder** — this project's own note folder, e.g.
  `E:\[--Sync--]\Notes_Audio\MediaFileExplorer`. Ask explicitly; do not guess.

Confirm the project note folder exists:

```
powershell -Command "Test-Path 'E:\[--Sync--]\Notes_Audio\MediaFileExplorer'"
```

If it returns `False`, warn the user the folder is missing but let them proceed
(they may create it later).

### 4. Write docs/AUDIO_NOTES.md

Write this exact content (substitute the real paths):

````markdown
# Audio Notes

Brief dictated notes for this project live here.

- **Base path:** `E:\[--Sync--]\Notes_Audio`
- **Project note folder:** `E:\[--Sync--]\Notes_Audio\MediaFileExplorer`

Notes are read from the top level of the project note folder only. Subfolders:

- `processing/` — notes currently being worked on (lock). If any file is here,
  another process is already running; a new run must stop instead of starting.
- `done/` — archive of handled notes. Never read.

Run `/audio-notes:work` to process the notes.
````

If a partial file already exists, update the path values in place rather than
duplicating sections.

### 5. Confirm

Print a ✓ summary showing the base path and project note folder saved, and note
that `/audio-notes:work` is now ready.
