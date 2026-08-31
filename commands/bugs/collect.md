---
description: Collect bugs as open issues in open-issues/
---

Document the bugs I found — do NOT fix them now. Implementation happens later
via `/bugs:fix` or `/bugs:work`.

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
- **Fix sketch**: rough direction only — the next agent researches the details
```

Keep it a base plan, not a full investigation.

Related commands:
- /bugs:fix — fix one documented bug with a structured TDD workflow
- /bugs:work — work off a whole open-issues file, then archive it
- /tdd:bugfix — fix any bug using test-driven development
