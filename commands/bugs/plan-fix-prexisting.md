---
description: Record a pre-existing bug found during the current task as an open issue
---

Write down the pre-existing issues found — do NOT fix them now, and do not let
them grow the current task.

Append them to today's open-issues file:

`open-issues/YYYY_MM_DD.md` — project root, today's date, e.g. `open-issues/2026_08_29.md`

Create `open-issues/` and the file if they do not exist. If the file already
exists, **append** — never overwrite, it may already hold issues from earlier
runs today.

One `##` section per issue:

```markdown
## <short title>

- **Where**: `path/to/file.ext:123`
- **Problem**: what is actually wrong
- **Why not now**: pre-existing, out of scope of <current task>
- **Fix sketch**: rough direction only — the next agent researches the details
```

Keep it a base plan, not a full investigation.

Work them off later with `/bugs:work` (oldest file first).
