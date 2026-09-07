---
description: Implement one prepared feature from features/ready-to-implement/, then move it to features/done/
argument-hint: [filename filter]
---

Implement **one** feature prepared by `/features:prepare`. Runs autonomously —
all questions were resolved during prepare, so do NOT ask the user anything.
One file per run, then stop.

## Steps

### 1. Pick the feature

```
powershell -Command "Get-ChildItem 'features\ready-to-implement\*.md' -File | Sort-Object Name | Select-Object -ExpandProperty Name"
```

If empty, report "nothing ready — run `/features:prepare` first" and stop.

If `$ARGUMENTS` is given, take the oldest file whose name contains it
(case-insensitive); otherwise the oldest file.

### 2. Implement

Read the file and implement its `## Plan`. Follow the project's conventions and
any workflow in its `CLAUDE.md`.

If a step fails, stop, create a handoff via `/handoff:create`, leave the file in
`ready-to-implement/` and report — do NOT archive an incomplete feature.

Pre-existing bugs you stumble over: do NOT fix them here — record them with
`/bugs:plan-fix-prexisting`.

### 3. Verify

Run the project's post-feature workflow (tests, analyzers) as documented in
`CLAUDE.md`, then `/dry:check` on the changed files.

### 4. Record what was done

Append an `## Implementation` section to the bottom of the feature file:

- **Files changed** — each path with a one-line note and the key
  function/class/method names touched
- **What was done** — short summary as actually implemented
- **Notes** — edge cases, follow-ups, anything non-obvious

### 5. Archive

Change the `#` title to `# [DONE] Feature: <title>`, then move the file to
`features/done/` (create the folder if missing):

```
powershell -Command "New-Item -ItemType Directory -Force 'features\done' | Out-Null; Move-Item 'features\ready-to-implement\2026_08_30_dark-mode-toggle.md' 'features\done\2026_08_30_dark-mode-toggle.md'"
```

If the feature was dropped instead (invalid, already implemented), title it
`# [DROPPED] Feature: <title>` with a one-line reason and archive it the same way.

### 6. Document

Document the feature in a new md file in `docs/features/`.

### 7. Summary

Report: which feature was implemented, what changed, whether it was archived,
and what is left in `ready-to-implement/`. Do NOT auto-commit — suggest
`/git:commit`.
