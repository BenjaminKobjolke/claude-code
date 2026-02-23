---
description: Create a new GitHub release based on docs/CREATE_NEW_GITHUB_RELEASE.md
---

Create a new GitHub release for this project.

## Prerequisites

Read `$CLAUDE_PROJECT_DIR/docs/CREATE_NEW_GITHUB_RELEASE.md` first. If it does not exist, tell the user to run `/xida:github-setup` first and stop.

## Step-by-Step Workflow

### 1. Determine version

- If `$ARGUMENTS` contains a version string, use that (e.g. `/xida:github-create-release 1.2.0`)
- Otherwise, read the `VERSION` file in the project root
- If neither exists, check existing git tags to find the latest release version and suggest the next one
- Ask the user to confirm the version before proceeding
- If the version differs from the `VERSION` file, update the `VERSION` file to match

### 2. Check working tree

- Run `git status` to ensure there are no uncommitted changes
- If there are uncommitted changes, ask the user if they want to commit first or abort

### 3. Review changes since last release

- Find the previous release tag: `git describe --tags --abbrev=0` or check `gh release list --limit 1`
- Show the user a summary of commits since that tag: `git log <last-tag>..HEAD --oneline`
- If there are no new commits, warn the user and ask if they want to proceed anyway

### 4. Run the release script

- Read the script location from `docs/CREATE_NEW_GITHUB_RELEASE.md`
- Execute the release script with the version as argument
- Monitor the output for errors

### 5. Verify

- Confirm the GitHub release was created: `gh release view v<VERSION>`
- Show the user the release URL
- Confirm the release asset (zip) was uploaded
