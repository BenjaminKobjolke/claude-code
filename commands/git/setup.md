---
description: Setup global permissions required by git:commit skill
---

# Git Setup Skill

This skill ensures the global Claude Code permissions required by the `/git:commit` skill are configured.

## Step 1: Read Global Settings

Read the global settings file at `~/.claude/settings.json`.

If the file does not exist, ask the user to create it first or run `claude` once to initialize it.

## Step 2: Check and Add Missing Permissions

Check if the following permissions exist in `permissions.allow`. Add any that are missing:

| Permission | Purpose |
|---|---|
| `Bash(git add *)` | Stage files for commit |
| `Bash(git commit *)` | Create commits |
| `Bash(git push *)` | Push to remote |
| `Bash(git status:*)` | Check working tree status |
| `Bash(git diff:*)` | View changes |
| `Bash(git log:*)` | View commit history |
| `Bash(rm tmp/*)` | Clean up temporary commit message file |

**Important:** Merge with existing permissions — never replace the array.

## Step 3: Ensure `tmp/` is Gitignored

The `/git:commit` skill writes a temporary commit message to `tmp/commit_msg.tmp`.

Check if the current project's `.gitignore` contains `tmp/`. If not, add `tmp/` to the `.gitignore` file.

## Step 4: Confirm

Tell the user which permissions were added (if any) and that `/git:commit` is ready to use.
