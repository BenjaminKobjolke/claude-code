---
description: Setup the process to create GitHub releases for this project
---

Set up a GitHub release workflow for this project. The result is a documented process in `$CLAUDE_PROJECT_DIR/docs/CREATE_NEW_GITHUB_RELEASE.md` and a batch script in the `tools/` folder.

## Step-by-Step

### 1. Check prerequisites

- Verify `gh` CLI is available: run `gh --version`
- Verify `git` is available and the project is a git repo
- Verify `composer` is available (if PHP project with vendor dependencies)
- If any tool is missing, tell the user and stop

### 2. Determine runtime files

Ask the user which files and directories are essential at runtime (i.e. must be included in a release zip). Suggest a starting list based on what you find in the project root, typically:

- Entry point files (e.g. `share.php`, `index.php`)
- Source directories (e.g. `inc/`, `src/`, `lib/`)
- Config templates (e.g. `config/app.php.example`)
- Dependency manifests (e.g. `composer.json`)
- Documentation (e.g. `README.md`, `LICENSE`)

Then ask which files/directories should be **excluded** (dev-only). Common exclusions:

- `vendor/` (will be rebuilt with `--no-dev`)
- `tests/`, `docs/`, `tools/`
- `.git/`, `.github/`
- IDE and editor config (`.vscode/`, `.idea/`)
- CI configs (`.gitlab-ci.yml`, `.github/workflows/`)

### 3. Check for existing release script

Look in the `tools/` folder for any existing `github-release.bat` or similar. If one exists, read it and document it rather than creating a new one.

### 4. Create the release script

If no release script exists, create `tools/github-release.bat` that:

1. Reads the version from a `VERSION` file in the project root (plain text, e.g. `1.0.0`)
2. Optionally accepts a version string as argument to override the file (e.g. `tools\github-release.bat 2.0.0`)
3. Creates a temporary staging directory
4. Copies only the runtime files identified in step 2
5. If the project uses Composer, runs `composer install --no-dev --optimize-autoloader` in the staging dir
6. Zips the staging directory using `tar -a -cf` (built into Windows 10+)
7. Creates a git tag and GitHub release via `gh release create`
8. Cleans up the temp directory and zip file

**Critical:** All external commands (`composer`, `tar`, `gh`) must use the `call` keyword (e.g. `call composer install ...`). Without `call`, a `.bat` file transfers control to the external command and never returns to execute the remaining steps.

### 5. Document everything

Write `$CLAUDE_PROJECT_DIR/docs/CREATE_NEW_GITHUB_RELEASE.md` containing:

- **Runtime files**: list of files/dirs included in the release zip
- **Excluded files**: list of files/dirs NOT included
- **Versioning**: `VERSION` file as source of truth, git tags, semver
- **Script location**: path to the release batch script
- **Usage**: exact command to run with example (reads from VERSION file by default)
- **What the script does**: step-by-step explanation
- **Prerequisites**: `gh` CLI authenticated, Composer installed, etc.

### 6. Verify

- Confirm the batch script exists and is syntactically valid
- Confirm the docs file is complete
- Tell the user they can now run `/github:create-release <version>` to create releases
