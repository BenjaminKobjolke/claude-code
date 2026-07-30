---
description: Set up a cross-repo feedback loop between a backend (API) repo and a frontend/app repo — feedback commands in both repos + CLAUDE.md links
---

# Frontend-Backend Communication Setup

Installs a feedback loop between two repos: each side gets slash commands to write feedback
files (`yyyy_mm_dd_TITLE.md`) into the other repo's `feedback/` folder and to implement
feedback it received. Fixed feedback files move to `feedback/done/`.

Reference implementations:
- `D:\wamp64\www\turbo-habits-api` ↔ `D:\GIT\BenjaminKobjolke\android\turbo-habits-app` (API + Flutter app)
- `D:\wamp64\www\erp-api` ↔ `D:\wamp64\www\erp-frontend` (API + web frontend)

## Step 1: Gather inputs

Ask only what you can't infer:

1. **Backend repo path** — default: current project if it is an API/backend.
2. **Frontend repo path** — the app or web frontend consuming the backend.
3. **FRONTEND_SLUG** — folder name for the backend-side "tell the frontend dev" command.
   Use `app` for mobile apps (→ `/app:implementation`), `frontend` for web frontends
   (→ `/frontend:implementation`).

## Step 2: Read both CLAUDE.md files

From each repo's CLAUDE.md, note:

- The **verify workflow**: which bat files / commands run tests, analysis and auto-fixes
  after a change (e.g. `fix_issues.bat`, `analyze_code.bat`, `tests.bat`).
- **Stack-specific conventions** worth enforcing as guardrails in the implement command
  (widget/component reuse, DI container registration, translation formats, defensive JSON
  parsing, etc.).

## Step 3: Install commands from templates

Templates live next to this command in `setup_files/`, reachable at
`~/.claude/commands/frontend-backend-communication/setup_files/`.

Do not overwrite existing command files without confirming.

**Backend repo** (`<backend>/.claude/commands/`):

| Template | Destination | Purpose |
|---|---|---|
| `backend-feedback-fix.md.template` | `feedback/fix.md` | Process `feedback/*.md`, fix, verify, move to `feedback/done/`, write follow-up feedback file to frontend repo. |
| `backend-SLUG-implementation.md.template` | `<FRONTEND_SLUG>/implementation.md` | Tell the frontend dev what to implement via a feedback file. |

**Frontend repo** (`<frontend>/.claude/commands/feedback/`):

| Template | Destination | Purpose |
|---|---|---|
| `frontend-implement-new-api-changes.md.template` | `implement-new-api-changes.md` | Implement feedback from the backend, with convention/DRY guardrails. |
| `frontend-write-api.md.template` | `write-api.md` | Write a bug/change request into the backend's `feedback/` folder. |

## Step 4: Adapt placeholders

In the copied files:

- Replace `FRONTEND_SLUG` with the slug from Step 1.3 (`app` or `frontend`) and
  `FRONTEND_FEEDBACK_PATH` with `<frontend>\feedback\`.
- Replace every `ADAPT:` comment block with concrete project content from Step 2:
  the exact verify commands, and stack-specific guardrails/verification bullets.
  No `ADAPT:` markers may survive in the installed files.

## Step 5: CLAUDE.md links

Add a `## Related Projects` section near the top of both CLAUDE.md files (skip if the path
is already recorded):

- Backend CLAUDE.md: frontend path — "write feedback files for the app/frontend dev into its `feedback/` folder"
- Frontend CLAUDE.md: backend path — same, pointing back

This is where the commands look up the counterpart path, so they never have to ask.

## Step 6: Confirm

Summarize for the user:

- Commands created in both repos (`/feedback:fix`, `/<FRONTEND_SLUG>:implementation`,
  `/feedback:implement-new-api-changes`, `/feedback:write-api`).
- `feedback/` directories are NOT created up front — the commands handle a missing dir.
- New Claude Code sessions are needed in each repo to pick up the commands.
- Suggest `/git:commit` in both repos.
