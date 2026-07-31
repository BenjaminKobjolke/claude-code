---
description: Preview and update Flutter packages in a verified batch via FVM
---

# Update Flutter Packages

Use the project's tested FVM wrappers to list dependency updates without
changing files. Apply the selected update scope separately, then run analysis
and tests once on the completed dependency set.

## 0) Ask the user: upgrade scope

Before running package commands, ask which scope the user wants:

- **Minor/patch only** - run `tools\packages_get_minor.bat`. This previews
  `fvm flutter pub upgrade --dry-run` within the current `pubspec.yaml`
  constraints without changing the manifest or lockfile.
- **All available, including major versions** - run
  `tools\packages_get_major.bat`. This previews
  `fvm flutter pub upgrade --major-versions --dry-run` and lists the constraints
  that a real major upgrade would rewrite.

Both wrappers list direct and transitive changes as far as the selected
constraints allow. They never update packages. Do not ask a separate
transitive-dependency question.

## 1) Preconditions and setup files

1. Work from the Flutter project root containing `pubspec.yaml`.
2. Require a clean Git working tree. Ask the user to commit or stash existing
   changes before upgrading packages.
3. Read `docs/STATUS_OUTDATED_PACKAGES.md` when present so known blockers are
   not retried unnecessarily.
4. Confirm the project pins Flutter with FVM and that this works:

```bat
git status --short
fvm flutter --version
```

The project must contain these wrappers:

```text
tools\packages_get_minor.bat
tools\packages_get_major.bat
```

If either is missing, copy both from:

```text
D:\GIT\BenjaminKobjolke\claude-code\commands\flutter\setup_files
```

Do not replace a project-specific wrapper without inspecting it first.

## 2) Capture the starting state

Record the current dependency state before upgrading:

```bat
fvm flutter pub outdated
fvm flutter pub deps --style=compact
```

When `pubspec.lock` is ignored, save a temporary copy if a rollback comparison
will be needed. Never add an ignored lockfile to Git just for this workflow.

## 3) Preview one batch without changing files

Run exactly one wrapper selected from the user's scope:

```bat
tools\packages_get_minor.bat
```

or:

```bat
tools\packages_get_major.bat
```

The wrappers:

- change to the project root using their own location;
- verify that `pubspec.yaml` exists;
- run Flutter Pub through FVM in `--dry-run` mode;
- return Pub's exit code to the caller.

Confirm that `pubspec.yaml` and `pubspec.lock` remain unchanged after either
preview wrapper.

## 4) Apply the selected batch intentionally

After the user confirms the previewed scope, run the corresponding real Pub
command separately. Do not remove `--dry-run` from the wrapper files.

Minor/patch within current constraints:

```bat
fvm flutter pub upgrade
```

Including major-version constraint changes:

```bat
fvm flutter pub upgrade --major-versions
```

Do not run analysis or tests between individual packages on the normal path.

## 5) Inspect the resolved batch

After the wrapper succeeds:

```bat
git diff -- pubspec.yaml pubspec.lock
fvm flutter pub outdated
```

Check that:

- the selected scope was respected;
- local `path:` dependencies were not replaced;
- no unexplained `dependency_overrides` were introduced;
- remaining packages are major-version exclusions or constraint-blocked.

For a transitive blocker, use `fvm flutter pub deps --style=compact` to find
the direct parent rather than forcing an override.

## 6) Analyze and test once

Run the project's required verification after the complete batch:

```bat
fvm flutter analyze --no-pub
tools\tests.bat
```

If the project defines different verification commands in `CLAUDE.md`, use
those instead. Run builds and changed-file analysis when the project workflow
requires them.

## 7) Failure handling

If dependency resolution fails:

1. Read Pub's conflicting constraints.
2. Restore or pin only the blocked direct package to its prior compatible
   version.
3. Run the selected wrapper again for the remaining batch.
4. Document the blocker and its parent constraint.

If analysis, tests, or builds fail:

1. Apply required compatibility migrations when they are within the selected
   scope.
2. Re-run only the failed verification while diagnosing.
3. If the responsible upgrade cannot be made green, restore that package and
   resolve the batch again.

Avoid `dependency_overrides` unless the user explicitly approves a temporary
override. For Android plugin upgrades, check compile SDK requirements. After
changing plugin versions, a stale Kotlin incremental-cache failure on Windows
can usually be cleared with `fvm flutter clean` before rebuilding.

## 8) Document the result

Update `docs/STATUS_OUTDATED_PACKAGES.md` with:

- the absolute session date;
- direct dependency changes;
- transitive dependency changes;
- skipped major versions and blocked packages with reasons;
- Flutter/Dart versions;
- analysis, test, and build results.

Leave changes committed or uncommitted according to the user's request.

## 9) Windows/FVM troubleshooting

If `fvm flutter` hangs or produces no output:

1. Confirm `.fvmrc` exists and run `fvm doctor`.
2. Check for stale `fvm`, `flutter`, or `dart` processes from timed-out calls.
3. In a sandboxed agent environment, retry with permission for FVM to access
   its SDK, Pub, Git, Gradle, and Android caches outside the project workspace.
4. Keep project commands routed through FVM. Use the pinned SDK executable
   directly only as a diagnostic when FVM itself cannot start.

Do not assume a silent command succeeded, and do not begin modifying package
constraints until FVM health is confirmed.
