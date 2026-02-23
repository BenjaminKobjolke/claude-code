---
description: create new release based on docs/CREATE_NEW_RELEASE.md
---

Create a new release for this project. If `/xida:release-setup` has not been run yet, tell the user to run it first and stop.

Read `$CLAUDE_PROJECT_DIR/docs/CREATE_NEW_RELEASE.md` for project-specific release instructions.

## Step-by-Step Workflow

### 1. Get the Next Build Number
Read the current build/version number from the location specified in `docs/CREATE_NEW_RELEASE.md` (e.g., `VERSION` file, `pubspec.yaml`, `package.json`, or similar). Determine the next version by incrementing appropriately. Ask the user to confirm.

### 2. Check if there are release notes for that
Check if release notes exist for the new version. If not, ask the user if you should run `/xida:release-create-release-notes` to generate them before continuing.

### 3. Increment build number
Update the version/build number in all locations specified by `docs/CREATE_NEW_RELEASE.md`. This may include version files, config files, or manifest files.

### 4. Build
Execute the build process as documented in `docs/CREATE_NEW_RELEASE.md`. Monitor the output for errors. If the build fails, report the error and stop — do NOT proceed with a broken build.
