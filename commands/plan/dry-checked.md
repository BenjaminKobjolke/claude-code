---
description: Reload a DRY-reviewed plan file into the current context
argument-hint: <plan-path>
model: haiku
effort: low
---

Reload exactly one DRY-reviewed plan file into the current context: $ARGUMENTS

Require one explicit, existing `.md` file path; resolve relative paths from the current working directory. Read the complete, unabridged file into the current context regardless of its length. Do not edit it, inspect the repository, or repeat the DRY or Ponytail analysis.

Confirm the resolved path and plan title, summarize any unresolved questions, and state that the plan is loaded for implementation. Do not claim the DRY gate is complete unless the preceding `/plan:dry` result reported both the DRY rewrite and Ponytail pass as complete.
