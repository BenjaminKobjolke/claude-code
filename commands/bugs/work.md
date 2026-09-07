---
description: Prepare the oldest open-issues file and fix it in the same run
argument-hint: [filename filter]
---

One-shot variant of the two-phase bugs flow. One file per run, then stop.

Those files are written by `/bugs:collect`, `/analyze:run-and-fix`,
`/analyze:fix-only` and `/bugs:plan-fix-prexisting`.

1. Run `/bugs:prepare $ARGUMENTS`. If it stopped (no open issues), stop here
   and relay its report.
2. Run `/bugs:implement <filename>` with the file prepare moved into
   `open-issues/ready-to-implement/`.
3. Report the combined summary of both runs.
