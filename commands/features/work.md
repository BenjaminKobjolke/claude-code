---
description: Prepare the oldest open feature and implement it in the same run
argument-hint: [filename filter]
---

One-shot variant of the two-phase features flow. One file per run, then stop.

Those files are written by `/features:collect`.

1. Run `/features:prepare $ARGUMENTS`. If it stopped (no open features,
   postponed), stop here and relay its report.
2. Run `/features:implement <filename>` with the file prepare moved into
   `features/ready-to-implement/`.
3. Report the combined summary of both runs.
