---
description: Create a new GitHub repository for the current project and push the first commit
effort: low
---

Create a GitHub repository for the current project, then make the first commit and push.

## Step 1: Prerequisites

- Verify `gh` CLI is available: run `gh --version`. If missing, tell the user and stop.
- Verify `gh` is authenticated: run `gh auth status`. If not, tell the user to run `gh auth login` and stop.
- Verify the current directory is a git repo. If not, ask the user whether to run `git init`, then do it if they agree.

## Step 2: Determine repo name

Default to the current project folder name. `$ARGUMENTS`, if given, overrides it. Confirm the final name with the user only if it differs from the folder name.

## Step 3: Check if the repo already exists

Resolve the target owner (the authenticated user, or an org if the user specified `owner/name`).

Run: `gh repo view <owner>/<name>`

- Exit 0 → the repo already exists. Show the URL and **stop** — do not create or overwrite. Ask the user how to proceed (e.g. pick a different name, or push to the existing repo).
- Non-zero (not found) → continue.

## Step 4: Ask private or public

Ask the user: private or public? Do not guess. Wait for the answer.

## Step 5: First commit

Follow the `/git:commit` guidelines for the initial commit (commit message format, `.gitattributes` / `.gitignore` setup, the automatic-ignore rules including `.claude/` and root `PLAN_*.md`, the `tmp/commit_msg.tmp` temp-file approach, no `cd` prefix on git commands).

If there are no commits yet, stage the project and create the first commit — type `FEATURE`, e.g.:

```
FEATURE (init): initial commit
```

## Step 6: Create the repo and push

Create the remote and push in one step with the visibility from Step 4:

```
gh repo create <owner>/<name> --private --source=. --remote=origin --push
```

Use `--public` instead of `--private` if the user chose public.

If `gh repo create` reports the name is taken (race with Step 3), stop and report it — do not force.

## Step 7: Confirm

Show the repo URL (`gh repo view --web` prints it) and confirm the push succeeded.
