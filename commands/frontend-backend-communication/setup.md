---
description: Set up a cross-repo feedback loop between a backend repo and a frontend repo — feedback commands in both repos + gitignored path links
---

# Frontend-Backend Communication Setup

Installs a feedback loop between two repos: each side gets slash commands to write feedback
files (`yyyy_mm_dd_TITLE.md`) into the other repo's `feedback/` folder and to implement
feedback it received. Fixed feedback files move to `feedback/done/`.

Re-runnable: every template carries an `<!-- fbc-version: N -->` marker, and a re-run syncs
already-installed command files that are behind the current template version. Never answer
"already set up" — always walk Step 3 and report per-file status.

Reference implementations:
- `D:\wamp64\www\turbo-habits-api` ↔ `D:\GIT\BenjaminKobjolke\android\turbo-habits-app` (backend + frontend)
- `D:\wamp64\www\erp-api` ↔ `D:\wamp64\www\erp-frontend` (backend + frontend)

## Step 1: Gather inputs

Ask only what you can't infer:

1. **Backend repo path** — default: current project if it is a backend.
2. **Frontend repo path** — the frontend consuming the backend.

## Step 2: Read both CLAUDE.md files

From each repo's CLAUDE.md, note:

- The **verify workflow**: which bat files / commands run tests, analysis and auto-fixes
  after a change (e.g. `fix_issues.bat`, `analyze_code.bat`, `tests.bat`).
- **Stack-specific conventions** worth enforcing as guardrails in the implement command
  (widget/component reuse, DI container registration, translation formats, defensive JSON
  parsing, etc.).

## Step 3: Install or sync commands from templates

Templates live next to this command in `setup_files/`, reachable at
`~/.claude/commands/frontend-backend-communication/setup_files/`.

Each template carries `<!-- fbc-version: N -->` on the line right after its frontmatter. The installed copy keeps that marker
verbatim (Step 4 substitution never touches it), so it records which template version a repo has.

For every row in the two tables below, compare the template's version with the installed file's:

| Installed file | Action | Report |
|---|---|---|
| missing | Install from template, then tailor (Step 4). | `installed v<N>` |
| marker == template version | Leave untouched. | `up to date (v<N>)` |
| marker lower, or no marker at all (legacy install) | Overwrite from the template, then re-run Step 4 substitution + `ADAPT:` tailoring using the Step 2 findings. | `updated v<old\|none> → v<N>` |
| marker higher than template | Do not touch. Report and ask the user. | `needs attention` |

Overwriting discards hand-edits to the installed file — the template is the source of truth.
Tell the user which files were overwritten so they can re-check anything they had customized.

**Backend repo** (`<backend>/.claude/commands/`):

| Template | Destination | Purpose |
|---|---|---|
| `backend-feedback-fix.md.template` | `feedback/fix.md` | Process `feedback/*.md`, fix, verify, move to `feedback/done/`, write follow-up feedback file to frontend repo. |
| `backend-frontend-implementation.md.template` | `frontend/implementation.md` | Tell the frontend dev what to implement via a feedback file. |

**Frontend repo** (`<frontend>/.claude/commands/feedback/`):

| Template | Destination | Purpose |
|---|---|---|
| `frontend-implement-new-api-changes.md.template` | `implement-new-api-changes.md` | Implement feedback from the backend, with convention/DRY guardrails. |
| `frontend-write-api.md.template` | `write-api.md` | Write a bug/change request into the backend's `feedback/` folder. |

## Step 4: Adapt placeholders

In the copied files:

- Replace `FRONTEND_FEEDBACK_PATH` with `<frontend>\feedback\`.
- Replace every `ADAPT:` comment block with concrete project content from Step 2:
  the exact verify commands, and stack-specific guardrails/verification bullets.
  No `ADAPT:` markers may survive in the installed files.

## Step 5: Record the counterpart paths

Repo paths are machine-local, so they do NOT go into the committed CLAUDE.md. Write
`<repo>/.claude/related-projects.md` in both repos instead — `.claude/` is already gitignored
by the `/git:commit` rules.

Create (or extend, skipping paths already recorded) in each repo:

```markdown
# Related Projects

- Frontend repo: `D:\path\to\frontend` — write feedback files for the frontend dev into its `feedback/` folder
```

- Backend repo's file: the frontend path.
- Frontend repo's file: the backend path, same wording pointing back.

This is where the commands look up the counterpart path, so they never have to ask. Verify
`.claude/` is in each repo's `.gitignore`; add it if missing.

## Step 6: Confirm

Summarize for the user:

- One status line per command file, using the Step 3 report values, e.g.:

  ```
  backend  feedback/fix.md                    updated none → v1
  backend  frontend/implementation.md         up to date (v1)
  frontend feedback/implement-new-api-changes.md  installed v1
  frontend feedback/write-api.md              installed v1
  ```

  Commands are `/feedback:fix`, `/frontend:implementation`,
  `/feedback:implement-new-api-changes`, `/feedback:write-api`.
- `feedback/` directories are NOT created up front — the commands handle a missing dir.
- Paths live in each repo's gitignored `.claude/related-projects.md`, so every dev sets
  their own once.
- New Claude Code sessions are needed in each repo to pick up the commands.
- Suggest `/git:commit` in both repos.
