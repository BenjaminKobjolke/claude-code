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
