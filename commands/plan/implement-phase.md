---
description: Implement the next phase of a multi-step plan in plan/YYYYMMDD_<feature-name>/ — or a given phase, or all remaining
argument-hint: [feature] [NN|all]
---

Implement phases of a multi-step plan (created by `/plan:multi-step` or `/plan:split`) one at a time. Each phase must leave the build green before the next one starts.

## Steps

1. **Resolve the plan folder**: candidates are subdirectories of `plan/` that contain a `00-context.md` (ignore `plan/done/`), sorted by folder name (dated folders sort oldest first). The folder name is `YYYYMMDD_<feature-name>`; call it `<folder-name>` below. Older undated folders are valid candidates too.
   - If the first `$ARGUMENTS` token is given, filter candidates whose folder name contains it (case-insensitive, partial match — so `tickets-watcher` matches `20260908_tickets-watcher`). When listing, show the full folder names. Exactly one match → select it. Several → list them and ask. None → show the candidates and ask.
   - If no token is given: one candidate → auto-select. Several → list and ask. None → tell the user there are no multi-step plans and suggest `/plan:multi-step` or `/plan:split`, then stop.

2. **Resolve which phase(s)**: remaining phases are the `NN-*.md` files directly in the folder (exclude `00-context.md`, `original.md`, and `done/`), sorted by their `NN` prefix.
   - Second token `NN` (e.g. `03`) → that phase only.
   - Second token `all` → every remaining phase, in order.
   - No second token → the lowest remaining phase.
   - If no phase remains, go to step 9.

3. Read `00-context.md` completely, then the phase file completely. **Light re-verify**: treat the recorded research as your starting point — do NOT redo it. Quickly confirm the key referenced files/symbols still exist. If something has moved, been renamed, or no longer exists, re-research only that specific gap.

4. **Open Questions gate**: if `00-context.md` or the phase file has unresolved questions relevant to this phase, present them to the user, wait for answers to ALL of them, and write the answers into the `Decisions taken with the user` table in `00-context.md`. Only then continue.

5. **Implement step by step**: follow the phase file in order. For each step announce what you are starting, make the changes, and report what was done before moving on.

6. **On failure**: stop immediately, explain what went wrong, and ask the user whether to attempt a fix or create a handoff via `/handoff:create`. Do NOT move the phase file if implementation is incomplete.

7. Run the phase's `## Verify` checks, then `/validate:pre-commit`. If anything fails, fix it and re-run until it passes. This happens per phase — every phase must be green on its own.

8. Ensure `plan/done/<folder-name>/` exists and move the phase file there (keep the filename — the `NN-` prefix preserves order). Move its sidecar files too: any file in `plan/<folder-name>/` whose name starts with the phase file's basename plus `-` (e.g. `02-foo-changed-files.md`, `02-foo-post-impl-delegate.log`) goes to the same `done/` folder, keeping its filename. Report which phases remain and suggest committing with `/git:commit`. Do NOT auto-commit.
   - In `all` mode, continue with the next remaining phase from step 3. Suggest a commit between phases but keep going.

9. When no `NN-*.md` remains in the folder, move the leftovers (`00-context.md`, `original.md`) into `plan/done/<folder-name>/` too and delete the now-empty `plan/<folder-name>/`. Tell the user the multi-step plan is complete and suggest reviewing and committing with `/git:commit`.
