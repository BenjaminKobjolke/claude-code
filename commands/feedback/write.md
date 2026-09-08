---
description: Write a feedback file (bug, change request, or what to implement next) into the counterpart repo's feedback/ folder
---

Write a feedback report for the developer of the counterpart repo (backend ↔ frontend).

Resolve the counterpart repo:
- `.claude/related-projects.md` if it exists;
- else the `## Related Projects` section of `CLAUDE.md`;
- else ask the user and store the answer in `.claude/related-projects.md` (gitignored,
  machine-local).

Then create a new md file named `yyyy_mm_dd_TITLE.md` in `<counterpart>/feedback/` (create the
dir if missing) describing:

- the bug, the change request, or the feature the other side has to implement;
- for API changes: endpoint paths, methods, request/response examples, breaking changes;
- a reference to the file or plan in this repo that motivated it, so the other side can read
  the intent.

If this is invoked while planning a feature, writing the feedback file is the **first** entry of
the plan — never the last — so the other developer can start in parallel.

NOTE: This command only writes feedback. To implement feedback this repo received, use
`/feedback:implement`.
