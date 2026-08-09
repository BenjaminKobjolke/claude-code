---
description: create new release based on docs/CREATE_NEW_RELEASE.md
---

Create a new release. The concrete commands (version/build, folder path, build
script, translator) live in the project's **`$CLAUDE_PROJECT_DIR/docs/CREATE_NEW_RELEASE.md`**
(authoritative) and the per-stack section in `coding-rules/CREATE_RELEASE_NOTES.md`. If
the project doc is missing, stop and ask the user to run `/release:setup`.

**Arguments.** No arg = **end-user app-store release** (the default). Pass
`internal` (`/release:create-release internal`) for an internal test build
(TestFlight, Play internal/beta, dev/test exe).

**Interaction contract.** The default (end-user) path runs unattended with
**exactly one** interactive question: the publish confirmation in step 6.
Everything else — release notes, build-number bump, translation, build, commit,
tag — happens automatically. Do not ask the user to confirm those steps.

**Build-number model - bump first, ship next.** The build counter (e.g.
`build_version.txt`) holds the **last shipped** build; `0` means nothing shipped
yet. A release **increments** it and ships that new number. The notes folder must
match the shipped label.

## Codex agents: run Windows BAT files outside the sandbox

Codex agents must run the project's documented release, translation, signing, and
publish BAT files with `sandbox_permissions: "require_escalated"`. Use the exact
working directory and command from `docs/CREATE_NEW_RELEASE.md`; for a BAT that calls
other BAT files, use `cmd /c call .\script.bat`.

This is required even when the same BAT works in the user's terminal. The managed
Codex command sandbox can interfere with nested Windows command wrappers such as
Chocolatey FVM. A typical failure is `fvm.exe` spawning a `cmd.exe` process that
consumes CPU indefinitely without ever starting Dart, Flutter, Gradle, or Java.

For Flutter release scripts that use FVM:

1. First run `fvm flutter --version` with
   `sandbox_permissions: "require_escalated"` from the project root.
2. Run the documented release BAT with
   `sandbox_permissions: "require_escalated"` from its documented working directory.
3. Allow the timeout required by the project documentation, yield while it runs, and
   keep waiting on that original process. Never start a second release build in
   parallel.

If a sandboxed attempt was started accidentally and stalls, inspect the release lock,
version file, expected artifacts, and recently started FVM/build processes without
changing them. Stop only the exact runaway child process from that attempt so the
release script can execute its rollback. Before retrying outside the sandbox, verify
that the previous version was restored, the lock was removed, and no release process
is still running.

## Workflow

### 0. End-user release or internal test build? (from the arg — do not ask)

Read the invocation arg instead of asking:

- **No arg** → end-user release (App Store / Play production, public exe / download).
  Commit type `RELEASE` in step 7; release notes **required** in step 2.
- **`internal`** → internal test build (TestFlight, Play internal/beta, dev/test exe).
  Commit type `INTERNAL` in step 7; release notes **skipped** in step 2.

Only ask the user if an arg was passed but is not `internal`.

### 1. Compute the next release label

Read the version (per the stack recipe) and the current build number. The release
ships as `<version>_<currentBuild + 1>`. Call this `<nextLabel>`.

### 2. Ensure release notes exist for `<nextLabel>`

Only required for an **end-user** release (skip entirely for an internal test build —
no notes, no en.json). Check for the notes folder + `en.json` at `<nextLabel>` (path per
the recipe). If missing, **run the release-notes workflow automatically** (follow
`commands/release/create-release-notes.md`) for `<nextLabel>` — do not ask whether to
create them. Those notes must be authored for the **next** label (current build + 1) and
translated. Do not build an end-user release without notes for the shipping label.

The notes workflow may itself prompt in one edge case (zero meaningful user-facing
changes); that is the notes skill's concern — do not add a duplicate question here.

### 3. Increment the build number

Bump the counter to the next build (e.g. `tools/build_increment.bat`). Now the
current build equals the about-to-ship build, and matches the notes folder.

### 4. Translate

Run the project's translator bat so the bundled notes include every locale (skip
only if the project ships English-only).

### 5. Build

Run the project's release build (e.g. `tools/build_release.bat`). It tests,
builds, and bundles `release_notes/`. The artifact ships as `<nextLabel>`.
If the project builds a Windows installer, **both exes get signed**: the app exe
is signed during the build (before the installer packs it), and the installer exe
(not the raw app exe) is the artifact for the publish/sign step.

### 6. Publish

**This is the one interactive gate.** After a successful build, if the project's
`docs/CREATE_NEW_RELEASE.md` defines a publish command, **ask the user once**
whether to publish `<nextLabel>` to the target platform — name the platform from
the project doc (e.g. "Publish `<nextLabel>` to the Google Play Store?").

- **User confirms** → run the documented publish command (e.g.
  `tools\publish_release.bat`). Do not invent a publish command; use the project
  doc as the source of truth. Then proceed to step 7 (auto commit + tag).
- **User declines** → stop, report the built artifact path, and **skip** step 7
  (no commit, no tag).
- **No publish command documented** → stop after the build, report the artifact
  path, and skip step 7.

For Windows installers, publish the installer artifact, not the raw app exe. The
publish step may sign the artifact, upload it, archive the previous remote file,
and upload release notes, depending on the project doc. If signing happens during
publish, watch the output and verify signing succeeded before treating the
release as published.

When the project publishes under a **stable filename** (e.g. `<app>.exe`,
constant download URL), the publish bat copies the versioned installer to the
stable name; the previous remote file is archived to `versions/<previous>/`
automatically (see the project's `CREATE_NEW_RELEASE.md`).

### 7. Commit & tag (automatic — do not ask)

After a successful publish, commit the release and tag it automatically:
`RELEASE (<scope>): <nextLabel>` for an end-user release,
`INTERNAL (<scope>): <nextLabel>` for an internal test build. Only a `RELEASE`
commit advances the anchor `/release:create-release-notes` diffs against —
`INTERNAL` builds still bump the build counter but are skipped when locating "the
last release".

After committing and tagging, **push to the remote automatically** —
`git push` followed by `git push --tags` (or `git push --follow-tags`) — so the
release commit and its tag land upstream.

Skip this step when the user declined to publish or no publish command is
documented (per step 6): the release was not shipped, so it must not be tagged.
