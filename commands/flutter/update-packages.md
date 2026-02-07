---
description: Update flutter packages via fvm, one by one
---

### Step-by-step guide to update Flutter packages one by one with FVM

#### Goal

Upgrade dependencies incrementally, verifying the project after each upgrade, and keeping changes small and reversible.

---

## 0) Preconditions

1. You are in the Flutter project root (folder containing `pubspec.yaml`).
2. Git is clean (no uncommitted changes).
3. You are using FVM and want all Flutter/Dart commands to run through it.

Commands:

```bash
git status
fvm flutter --version
```

If `git status` is not clean, commit or stash before continuing.

---

## 1) Snapshot current state

1. Record current dependency state:

```bash
fvm flutter pub deps --style=compact > /tmp/pub_deps_before.txt
fvm flutter pub outdated > /tmp/pub_outdated_before.txt
```

2. Ensure lockfile is present and up to date:

```bash
fvm flutter pub get
```

3. Run baseline checks (so later failures are clearly caused by upgrades):

```bash
fvm flutter analyze
fvm flutter test
```

---

## 2) Choose the upgrade order

Upgrade “leaf” and test-only dependencies first, then tooling, then bigger plugins.

Suggested order:

1. Small libs: `characters`, `matcher`, `js`, `material_color_utilities`
2. Test stack: `test_api`, `test_core`, `test`
3. Codegen: `source_helper`, `json_serializable`
4. Analyzer/tooling: `analyzer_plugin`, `analyzer`, `_fe_analyzer_shared`
5. Large plugin: `google_mobile_ads`

Get the current list:

```bash
fvm flutter pub outdated
```

---

## 3) Define the “single package upgrade loop”

For **each** package you upgrade, follow the same loop strictly.

### Loop for one package: `<PKG>`

#### A) Create a branch (optional but recommended)

```bash
git checkout -b chore/upgrade-<PKG>
```

#### B) Upgrade the package (pick ONE method)

**Method 1: Upgrade within existing constraints**

```bash
fvm flutter pub upgrade <PKG>
```

**Method 2: Upgrade to a specific version (recommended for strict one-by-one control)**

```bash
fvm flutter pub add <PKG>:^<TARGET_VERSION>
```

Example:

```bash
fvm flutter pub add characters:^1.4.1
```

> Use Method 2 when you want to ensure exactly one dependency change at a time (as much as Pub allows).

#### C) Fetch packages

```bash
fvm flutter pub get
```

#### D) Inspect what changed

```bash
git diff -- pubspec.yaml pubspec.lock
```

You want to see:

* `pubspec.yaml` updated only for `<PKG>` (if you used `pub add`)
* `pubspec.lock` changes are expected, but should be reasonably related

#### E) Run verification checks

Minimum:

```bash
fvm flutter analyze
fvm flutter test
```

Optional (recommended if you have integration tests / formatting rules):

```bash
fvm flutter format --set-exit-if-changed .
```

#### F) If it fails: fix or revert

* If it’s a simple compile/test issue, fix the code and re-run checks.
* If it’s too disruptive, revert and try a smaller change.

Revert:

```bash
git checkout -- pubspec.yaml pubspec.lock
```

Or discard branch:

```bash
git checkout main
git branch -D chore/upgrade-<PKG>
```

#### G) Commit when green

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: upgrade <PKG> to <VERSION>"
```

#### H) Re-check what’s next

```bash
fvm flutter pub outdated
```

Merge branch (optional):

```bash
git checkout main
git merge --no-ff chore/upgrade-<PKG>
```

Repeat loop for the next package.

---

## 4) How to handle packages that are NOT direct dependencies

Some items in `pub outdated` (like `analyzer`, `_fe_analyzer_shared`, `test_core`) might be transitive.

Rules:

* If it’s **directly listed in your `pubspec.yaml`**, upgrade it normally.
* If it’s **not in `pubspec.yaml`**, it’s transitive:

  * Prefer upgrading the **direct dependency** that pulls it in (e.g., upgrading `test` may bump `test_core`).
  * Avoid forcing transitive overrides unless necessary.

If you must pin a transitive version temporarily:

```yaml
dependency_overrides:
  analyzer: ^9.0.0
```

Then:

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```

Remove overrides once the direct dependencies catch up.

---

## 5) Notes for major upgrades

If the available version is a major bump (e.g., `google_mobile_ads 6.x -> 7.x`, `analyzer 8.x -> 9.x`):

1. Upgrade it alone in its own commit.
2. Expect breaking changes and consult release notes/changelog.
3. If it breaks, either:

   * fix code accordingly, or
   * keep it at the latest minor/patch within the current major for now.

---

## 6) Minimal command template (copy/paste)

Replace `<PKG>` and `<VERSION>`:

```bash
git checkout -b chore/upgrade-<PKG>
fvm flutter pub add <PKG>:^<VERSION>
fvm flutter pub get
git diff -- pubspec.yaml pubspec.lock
fvm flutter analyze
fvm flutter test
git add pubspec.yaml pubspec.lock
git commit -m "chore: upgrade <PKG> to <VERSION>"
git checkout main
git merge --no-ff chore/upgrade-<PKG>
```

---

## 7) Suggested first few upgrades from your list

Start with small ones:

* `characters` → `^1.4.1`
* `matcher` → `^0.12.18`
* `test_api` → `^0.7.8`
* `json_serializable` → `^6.11.3`

Then continue.

---

## 8) Troubleshooting: `fvm flutter` produces no output

On Windows, `fvm flutter pub outdated` (and other `fvm flutter` commands) may exit with code 0 but produce **no output at all**. This is an FVM bug where the proxy swallows stdout.

### How to diagnose

Run `fvm doctor` and check the output. If you see:

* `Config Present: No`
* `Pinned Version: None`

Then FVM has no pinned version and is just proxying to the system Flutter, which causes the stdout issue.

### Solution 1: Pin the Flutter version (fixes the root cause)

```bash
fvm use <VERSION>
```

Example: `fvm use 3.35.7`. This creates a `.fvmrc` file in the project root. After pinning, `fvm flutter pub outdated` should produce output normally.

### Solution 2: Call Flutter directly (bypass FVM)

If pinning doesn't help, call Flutter without the FVM wrapper:

```bash
flutter pub outdated
```

This works when no FVM version is pinned and the system Flutter is the intended SDK.

### Solution 3: Use `pub get` output as a workaround

`fvm flutter pub get` prints lines like `package_name 1.0.0 (2.0.0 available)` as a side effect. This gives the same information in a different format.

---
