---
description: write HANDOFF.md if you are running out of context
---

Write a handoff document so the next agent with fresh context can continue this work. Create it fast with minimal extra steps because we are running out of context.

Steps:

Check if HANDOFF.md already exists in the project root.
If it exists, delete it.

Create HANDOFF.md with this template — fill it in quickly from what you know:

```markdown
# Handoff Document

**Status**: in_progress | blocked | ready_for_review

## Goal

What we're trying to accomplish.

## Environment

- OS: (detected)
- Language/Framework: (detected)
- Package Manager: (detected)

## Progress

### Done
- [x] Completed items

### Remaining
- [ ] Pending items

## What Worked

Approaches that succeeded.

## What Didn't Work

Failed approaches with error messages — do not repeat these.

## Next Steps

1. First action
2. Second action
```

Save as HANDOFF.md in the project root and tell the user the file path.
