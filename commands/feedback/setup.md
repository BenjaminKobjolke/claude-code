---
description: Link a backend repo and a frontend repo for the /feedback:* commands — record counterpart paths, migrate old per-project feedback commands
---

# Feedback Setup

`/feedback:implement` and `/feedback:write` are global commands (this repo's `commands/` is
linked into `~/.claude/commands`). They need only one thing per repo: the path of the counterpart
repo. This command records it in both repos and removes leftovers of the old copy-based install.
Re-runnable; report what was done per repo.

## Step 1: Inputs

Ask only what you can't infer:

1. **Backend repo path** — default: current project if it is a backend.
2. **Frontend repo path** — the frontend consuming the backend.

## Step 2: Per repo (backend, then frontend)

1. **Counterpart entry**. Look for the other repo's path in `.claude/related-projects.md`, then
   in the `## Related Projects` section of `CLAUDE.md`. If neither has it, write
   `.claude/related-projects.md` (machine-local paths do not belong in the committed
   `CLAUDE.md`):

   ```markdown
   # Related Projects

   - Frontend repo: `D:\path\to\frontend` — write feedback files for the frontend dev into its `feedback/` folder
   ```

   Backend gets the `Frontend repo:` line; frontend gets a `Backend repo:` line pointing back.
   The label (`Frontend`/`App` vs `Backend`/`API`) is how the commands detect the repo's role.

2. **Gitignore**: ensure `.claude/` is in `.gitignore`; add it if missing.

3. **Migrate old installs**. Delete these per-project copies from the previous
   `/frontend-backend-communication:setup`, but only if their frontmatter `description` starts
   with the old template text below (installs were hand-tailored, e.g. "api developer" instead
   of "backend developer") — anything else is left alone and reported:

   | File | Old description starts with |
   |---|---|
   | `.claude/commands/feedback/fix.md` | `Fix issues and implement features from feedback reports` |
   | `.claude/commands/feedback/implement-new-api-changes.md` | `Fix issues and implement features from feedback reports` |
   | `.claude/commands/feedback/write-api.md` | `Write feedback for bugs or change requests for the` |
   | `.claude/commands/frontend/implementation.md` | `Tell the frontend developer what to do next` |
   | `.claude/commands/app/implementation.md` | `Tell the app developer what to do next` |

   Remove directories that become empty.

4. **Rewrite references in `CLAUDE.md`**: `/feedback:write-api`, `/frontend:implementation`,
   `/app:implementation` → `/feedback:write`; `/feedback:fix`,
   `/feedback:implement-new-api-changes` → `/feedback:implement`.

## Step 3: Report

Per repo: where the counterpart path was found (or that it was written), files deleted,
references rewritten. Then remind the user:

- Commands: `/feedback:implement` (process received feedback) and `/feedback:write` (send
  feedback) — same names in both repos.
- `feedback/` directories are not created up front; the commands handle a missing dir.
- New Claude Code sessions in each repo pick up the global commands.
- If deleted command copies were tracked by git, suggest `/git:commit`.
