---
description: Prepare one audio note and implement it in the same run
---

One-shot variant of the two-phase audio-notes flow. Processes **one** unit of
work, then stops.

1. Run `/audio-notes:prepare`. If it stopped (setup missing, lock held, no
   notes), stop here and relay its report.
2. Run `/audio-notes:implement <filename>` with the note file that prepare
   moved into `ready-to-implement/`.
3. Report the combined summary of both runs.
