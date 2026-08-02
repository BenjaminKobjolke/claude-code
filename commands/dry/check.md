---
description: Run a bounded post-implementation DRY audit on changed code
argument-hint: "[pathspec]"
context: fork
agent: general-purpose
model: haiku
effort: low
disallowed-tools: Edit, Write, NotebookEdit
---

Audit changed code for duplication, missed reuse, and unnecessary complexity. This command is read-only.

Optional scope: $ARGUMENTS

1. Inventory staged, unstaged, and untracked changes with `git status --short`, `git diff --stat`, and `git diff --cached --stat`. Count lines in untracked text files without loading their contents into context. If a pathspec is supplied, restrict every query, read, and search to it. If nothing matches, ask for a valid pathspec and stop.
2. Before reading code, enforce the budget. If the scope exceeds 10 files or 500 added/removed lines, do not audit or run Ponytail; ask the user to rerun with a narrower pathspec.
3. Inspect the changed hunks first. Read surrounding code only when needed to understand a hunk; do not read whole large files.
4. Look for duplication among the changes and missed existing abstractions. Make at most 3 targeted searches, inspect at most 3 unchanged reference files, and read at most 300 reference lines total. Never run an unrestricted repository survey.
5. Report only concrete findings supported by file and line references. Do not propose a new abstraction without at least 2 consumers or a clear local convention.
6. Run `/ponytail:ponytail` inside this same fork, scoped to these changes, for the separate YAGNI/KISS pass. If Ponytail is unavailable, do not install it; report that the YAGNI gate is incomplete.

Return at most 300 words using only applicable headings:

## Duplication
## Reuse Opportunities
## YAGNI/KISS
## Verdict

If issues exist, end by asking whether the user wants them fixed. Do not modify any files.
