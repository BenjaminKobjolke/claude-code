---
description: Collect a feature request as a file in features/
---

Document a feature request and its implementation plan. Do **not** implement
anything — the work happens later via `/features:prepare` + `/features:implement`
(or `/features:work` for both at once).

## Steps

### 1. Get the request

Take the feature description from `$ARGUMENTS`. If empty, ask the user what
feature they want to record.

### 2. Derive the filename

`features/YYYY_MM_DD_<kebab-name>.md` in the project root — today's date plus a
short kebab-case name derived from the description, e.g.
`features/2026_08_30_dark-mode-toggle.md`.

Create `features/` if missing. If that file already exists, append a new `##`
section to it instead of overwriting.

### 3. Research just enough

Before writing, look at how the codebase solves similar things: existing
components, utilities, patterns, conventions and any `docs/` page for the
affected area. This is a base plan, not a full investigation — the agent that
works it off researches the details.

### 4. Write the file

```markdown
# Feature: <title>

- **Goal**: what this achieves and why
- **Where**: `path/to/file.ext` — files/areas this touches
- **Reuse**: existing components/patterns found, with paths
- **Plan sketch**: rough steps only
- **Open questions**: anything needing user input before implementation
```

### 5. Stop

Report the file path. Do NOT edit any project source file. Work it off later
with `/features:prepare` then `/features:implement` (oldest file first), or
`/features:work` for both at once.

Related commands:
- `/features:prepare` — research the oldest open feature and write its plan
- `/features:implement` — build a prepared feature and archive it
- `/features:work` — prepare + implement in one run
- `/plan:feature` — full research-heavy plan in `plan/` for one big feature
- `/bugs:collect` — same idea for bugs
