---
description: write HANDOFF.md if you are running out of context
---

Write a handoff document so the next agent with fresh context can continue this work.

**Low-context mode:** If context is running low, use the abbreviated template — skip the Dependencies section, minimize What Worked/Didn't Work to one line each, and keep all sections as brief as possible.

Steps:

Check if HANDOFF.md already exists in the project root.
If it exists, delete it.

Create HANDOFF.md with the following structured template:

```markdown
# Handoff Document

**Status**: in_progress | blocked | ready_for_review

## Goal

What we're trying to accomplish. Be specific about the end state.

## Environment

- OS: (Windows/Linux/Mac)
- Language/Framework: (and version)
- Package Manager: (and version)
- Key Tools: (list any tools referenced in CLAUDE.md)

## Current Progress

### Completed
- [x] Task that was finished
- [x] Another completed task

### Pending
- [ ] Task still to do
- [ ] Another pending task

## Task Progress

If a TaskList is active, include the current task status here:
- List each task with its status (completed, in_progress, pending)
- Note any blocked tasks and what blocks them

## What Worked

Approaches and solutions that succeeded. Include specific details so the next agent can build on them.

## What Didn't Work

Approaches that failed — include specific error messages and why they failed so the next agent does not repeat them.

- Approach: (what was tried)
  Error: (exact error message or behavior)
  Why it failed: (root cause if known)

## Dependencies

- External dependencies or services required
- Blocking issues that need resolution
- Required tools or access

## Next Steps

Clear, ordered action items for continuing the work:
1. First thing to do
2. Second thing to do
3. ...
```

Fill in each section based on the current session's work. Be specific — vague handoffs waste the next agent's context.

Save as HANDOFF.md in the project root and tell the user the file path so they can start a fresh conversation with just that path.
