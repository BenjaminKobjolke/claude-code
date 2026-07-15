---
description: try to remove exceptions
---

# Code Analysis Fix Instructions

Exception review requires a **full** analyzer run (`tools/analyze_code.bat`) —
exceptions concern the whole tree; a changed-files (`--only-changed`) run hides
the suppressed areas you are reviewing.

Check the exceptions in code_analysis_rules.json.
Try to improve on some of them. Add a date attribute to the ones you checked. So the next time we do this check we are not checking the same files again.

Do not put all just with checked date. Try to pick some that would benefit the most from refractoring and try to improve them so we can remove them from this list.

## Step 0 — prune dead exceptions first (highest value, zero risk)

Before hand-refactoring anything, remove **dead exceptions**: entries whose
referenced `file` no longer exists, or whose documented `function` no longer
appears in that file (renamed, moved to a sibling file, or deleted).

**Why this is safe.** The analyzer matches exceptions on the `file` path only —
the `function` key is documentation, not a match key. A non-matching exception
suppresses nothing, so **deleting a dead exception cannot change the analyzer's
pass/fail** — it is pure cleanup. A function/file that moved and still violates
is already unsuppressed and surfaces on its own; deleting the stale entry does
not hide it. (In one run this pruned 30 of 261 entries.)

**Preferred — use the analyzer's built-in scanner** (in `cli-code-analyzer`):

```
python main.py --dead-exceptions -p <project-root> -r code_analysis_rules.json
```

Add `--fix` to remove them in place, or `-o <folder>` to also write
`dead_exception.csv`. Exit code is non-zero when any dead entry is found.

**Fallback — do the scan by hand** if the tool is unavailable. Detection rules:

- `max_lines_per_file.exceptions[].file` — dead if the path doesn't resolve.
- `pmd_duplicates.exceptions[]` — dead if **any** referenced file is gone. Handle
  both the `files: [...]` array shape used by this project and the
  `file` + `duplicate_of` shape.
- `dart_code_linter.metrics.<metric>.exceptions[]` — dead if `file` is missing,
  OR `function` is present but its identifier no longer appears in the resolved
  file. Handle the `"ClassA.methodA / ClassB.methodB"` multi-name form (split on
  `/`, take the last dotted identifier of each, e.g. `methodA`, `methodB`).
- Path resolution: try `<file>`, then `lib/<file>`, then `test/<file>`.
- Skip glob-valued `file` entries (`*`, `?`, `[`) — they can't be judged dead by
  existence.

Removal is a pure-subset rewrite: `json.load` → drop dead entries →
`json.dump(indent=2, ensure_ascii=True)`. Verify nothing else changed
(the remaining entries must be a strict subset; 0 added or mutated).

## Then — review and improve the survivors

- Date-stamp (`"checked": "<today>"`) the survivors you actually reviewed. Do NOT
  blanket-stamp everything — only what you genuinely examined.
- Pick a few that would benefit most from real refactoring (a genuine code smell,
  cheap to fix and cheap to verify) and improve the code so the exception can be
  deleted entirely. Most copyWith / fromMap / DI-container / generated-file
  exceptions are irreducible — leave those, just record the review with a date.
