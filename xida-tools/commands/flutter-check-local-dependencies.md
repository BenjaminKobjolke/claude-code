---
description: Use when checking if local path dependencies have outdated constraints that hold back transitive packages in the main project
---

### Check local path dependencies for upgradeable constraints

#### Goal

Identify local (path) dependencies whose version constraints prevent the main project from resolving to the latest available versions of transitive packages. Then check each constraint against the latest published version and report what can be upgraded.

---

## 1) Find all local path dependencies

Search `pubspec.yaml` for `path:` entries pointing to local directories:

```bash
grep -n "path:" pubspec.yaml
```

Read each referenced `pubspec.yaml` to collect their dependency constraints.

Also check for **nested** local path dependencies (local packages that themselves reference other local packages, e.g. `azul_video_editor` referencing `flutter_soloud`).

---

## 2) Run `flutter pub outdated` in the main project

```bash
fvm flutter pub outdated
```

Compare the **Current**, **Resolvable**, and **Latest** columns:

- If **Resolvable < Latest** for a package, something is constraining it.
- If **Resolvable = Current** and both are **< Latest**, the constraint is tight.

---

## 3) Cross-reference constraints

For each outdated transitive dependency, check if a local package is the one constraining it:

1. Find which local package declares the dependency.
2. Compare the constraint (e.g. `^0.0.5` means `>=0.0.5 <0.1.0`) against the latest published version.
3. If the latest version falls outside the constraint range, the local package is the blocker.

Use `fvm flutter pub deps --style=compact` to trace which package pulls in a transitive dependency if needed.

---

## 4) Check changelogs for breaking changes

Before recommending an upgrade, verify the changelog of each candidate package:

- **Bug fixes / minor changes only** — safe to bump the constraint.
- **Breaking API changes** — check the local package's usage of the dependency to assess impact.
- **Deprecated APIs removed** — verify the local package doesn't use them.

---

## 5) Report findings

Present a summary table to the user:

| Local Package | Dependency | Current Constraint | Resolved Version | Latest Version | Blocking? | Safe to Upgrade? |
|---------------|------------|--------------------|------------------|----------------|-----------|------------------|

For each blocking constraint, recommend the new constraint value (e.g. `^0.1.3`) and note any risks.

---

## 6) Apply upgrades (with user approval)

For each approved upgrade:

1. Edit the local package's `pubspec.yaml` with the new constraint.
2. Run `fvm flutter pub get` in the main project.
3. Verify the transitive dependency resolved to the expected version.
4. Run `fvm flutter analyze --no-pub` — no new errors.
5. Run `fvm flutter test` — all tests pass.

Commit each local package change separately for easy rollback.
