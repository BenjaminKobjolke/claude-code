# Update Flutter Libraries (One by One)

This guide explains how to update Flutter packages incrementally and verify the project still compiles after each change. It also covers how to do the same when using FVM.

## Prerequisites

- Clean working tree or a checkpoint you can roll back to.
- Working Flutter toolchain.

## Step-by-step (without FVM)

1) Sync dependencies

- Run:
  flutter pub get

2) See what can be updated

- Run:
  flutter pub outdated
- Review the list and pick a single package to update first. Prefer updating direct dependencies before transitive ones.

3) Update one package

- Edit `pubspec.yaml` and change the version for the chosen package.
- If you want to use the latest compatible version, set the constraint to a newer semver range (for example, `^x.y.z`).

4) Fetch packages

- Run:
  flutter pub get

5) Verify the project still compiles

- Run the same checks your CI uses. At minimum:
  flutter analyze
  flutter test
- If your project is an app, also confirm a build still succeeds:
  flutter build apk
  (or `flutter build ios` on macOS)

6) Commit or checkpoint

- If all checks pass, commit or tag the change.

7) Repeat

- Go back to step 2 and update the next package.

## Step-by-step (with FVM)

If the project uses FVM, use `fvm` to run Flutter and Dart commands so you always target the correct SDK version.

1) Ensure the project SDK is selected

- Check `.fvmrc` or `.fvm/fvm_config.json` to see the pinned Flutter version.
- Run:
  fvm use

2) Sync dependencies

- Run:
  fvm flutter pub get

3) See what can be updated

- Run:
  fvm flutter pub outdated

4) Update one package

- Edit `pubspec.yaml` for the package you are updating.

5) Fetch packages

- Run:
  fvm flutter pub get

6) Verify the project still compiles

- Run:
  fvm flutter analyze
  fvm flutter test
- If the project is an app, also build:
  fvm flutter build apk
  (or `fvm flutter build ios` on macOS)

7) Commit or checkpoint

- If all checks pass, commit or tag the change.

8) Repeat

- Go back to step 3 and update the next package.

## Notes

- Update direct dependencies first; transitive updates often follow when you refresh direct versions.
- If a package has a major version bump, review its changelog before updating.
- If a compile error appears, roll back the last package change, fix it, or pin a compatible version.
