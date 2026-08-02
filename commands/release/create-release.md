---
description: create new release based on docs/CREATE_NEW_RELEASE.md
---

Create a new release. The concrete commands (version/build, folder path, build
script, translator) live in the project's **`$CLAUDE_PROJECT_DIR/docs/CREATE_NEW_RELEASE.md`**
(authoritative) and the per-stack section in `coding-rules/CREATE_RELEASE_NOTES.md`. If
the project doc is missing, stop and ask the user to run `/release:setup`.

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

### 0. End-user release or internal test build?

Ask the user (if not already stated): is this build shipping to end users (App Store /
Play production, public exe / download) or is it an internal test build (TestFlight,
Play internal/beta, dev/test exe)? This decides the commit type in step 7 and whether
release notes are required in step 2.

### 1. Compute the next release label

Read the version (per the stack recipe) and the current build number. The release
ships as `<version>_<currentBuild + 1>`. Call this `<nextLabel>`.

### 2. Ensure release notes exist for `<nextLabel>`

Only required for an **end-user** release (skip entirely for an internal test build —
no notes, no en.json). Check for the notes folder + `en.json` at `<nextLabel>` (path per
the recipe). If missing, ask the user whether to run `/release:create-release-notes`
first - those notes must be authored for the **next** label (current build + 1) and
translated. Do not build an end-user release without notes for the shipping label.

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

If the project's `docs/CREATE_NEW_RELEASE.md` defines a publish command, run it
after the build (e.g. `tools\publish_release.bat`). Do not invent a publish
command; use the project doc as the source of truth. If the project has no
publish command documented, stop after the build and report the artifact path.

For Windows installers, publish the installer artifact, not the raw app exe. The
publish step may sign the artifact, upload it, archive the previous remote file,
and upload release notes, depending on the project doc. If signing happens during
publish, watch the output and verify signing succeeded before treating the
release as published.

When the project publishes under a **stable filename** (e.g. `<app>.exe`,
constant download URL), the publish bat copies the versioned installer to the
stable name; the previous remote file is archived to `versions/<previous>/`
automatically (see the project's `CREATE_NEW_RELEASE.md`).

### 7. Commit & tag (optional, ask first)

Offer to commit the release and tag it: `RELEASE (<scope>): <nextLabel>` for an
end-user release, `INTERNAL (<scope>): <nextLabel>` for an internal test build. Only a
`RELEASE` commit advances the anchor `/release:create-release-notes` diffs against —
`INTERNAL` builds still bump the build counter but are skipped when locating "the last
release".
