---
description: Update PHP composer packages, one by one
---

### Step-by-step guide to update PHP Composer packages one by one

#### Goal

Upgrade dependencies incrementally, verifying the project after each upgrade, and
keeping changes small and reversible.

---

## 0) Ask the user: upgrade scope

Before starting, ask the user which upgrade scope they want:

* **Minor/patch only** — Only upgrade within existing `composer.json` constraints
  (e.g. `2.0.7 → 2.0.8`, `4.5.4 → 4.7.2`). This is what plain `composer update`
  does. Safest option, least risk of breaking changes.
* **All available** — Also attempt major version upgrades (e.g. `phpunit 10.x → 11.x`).
  A major bump requires rewriting the constraint with `composer require vendor/pkg:^NEW`.
  Higher risk, may require code changes to fix breaking APIs.

This determines whether to skip or attempt major version bumps in step 4.

---

## 1) Preconditions

1. You are in the PHP project root (folder containing `composer.json`).
2. Git is clean (no uncommitted changes).
3. Composer is installed.

Commands:

```bash
git status
composer --version
```

If `git status` is not clean, commit or stash before continuing.

---

## 2) Snapshot current state

1. Check if `docs/STATUS_OUTDATED_PACKAGES.md` exists. If it does, read it to
   understand what was upgraded previously, what was skipped, and why. This gives
   you context on known blockers and avoids re-attempting upgrades that fail.

2. Record current dependency state:

```bash
composer outdated -D > /tmp/composer_outdated_before.txt
composer show > /tmp/composer_show_before.txt
```

3. Ensure the lockfile is present and installed:

```bash
composer install
```

4. Run baseline verification (see step 8 to detect the right commands) so later
   failures are clearly caused by upgrades.

---

## 3) Choose the upgrade order

Upgrade dev-only and leaf dependencies first, then libraries, then framework
packages.

Suggested order:

1. Dev tooling: `phpunit/phpunit`, `phpstan/phpstan`, `friendsofphp/php-cs-fixer`
2. Small libs with no dependents
3. Framework / large packages (e.g. `laravel/framework`, `symfony/*`)

Get the current list of **direct** outdated packages:

```bash
composer outdated -D
```

Color/columns: a package shown in **yellow** is updatable within your constraints;
**red** means a newer version exists outside your constraints (needs a constraint bump).

---

## 4) Define the "single package upgrade loop"

For **each** package you upgrade, follow the same loop strictly.

### Loop for one package: `vendor/pkg`

#### A) Create a branch (optional but recommended)

```bash
git checkout -b chore/upgrade-pkg
```

#### B) Upgrade the package (pick ONE method)

**Method 1: Upgrade within existing constraints**

```bash
composer update vendor/pkg --with-dependencies
```

`--with-dependencies` (`-W`) also bumps that package's own transitive deps as needed.

**Method 2: Bump the constraint to a new version (required for major upgrades)**

```bash
composer require vendor/pkg:^X.Y
```

Example:

```bash
composer require phpunit/phpunit:^11.0
```

For a dev dependency, add `--dev`:

```bash
composer require --dev phpstan/phpstan:^2.0
```

> Use Method 2 when the target is outside the current constraint (major bump), or
> when you want exactly one constraint change at a time.

#### C) Inspect what changed

```bash
git diff -- composer.json composer.lock
```

You want to see:

* `composer.json` updated only for `vendor/pkg` (if you used `composer require`)
* `composer.lock` changes are expected, but should be reasonably related

#### D) Run verification checks

Run the project's configured checks (detected in step 8), e.g.:

```bash
composer test
composer phpstan
```

#### E) If it fails: fix or revert

* If it's a simple compile/test issue, fix the code and re-run checks.
* If it's too disruptive, revert and try a smaller change.

Revert:

```bash
git checkout -- composer.json composer.lock
composer install
```

Or discard branch:

```bash
git checkout main
git branch -D chore/upgrade-pkg
```

#### F) Commit when green

```bash
git add composer.json composer.lock
git commit -m "chore: upgrade vendor/pkg to X.Y"
```

#### G) Re-check what's next

```bash
composer outdated -D
```

Merge branch (optional):

```bash
git checkout main
git merge --no-ff chore/upgrade-pkg
```

Repeat the loop for the next package.

---

## 5) How to handle transitive (indirect) dependencies

Some items in `composer outdated` (without `-D`) are transitive — not listed in your
`composer.json`.

### Finding what pulls in a package

```bash
composer why vendor/pkg
```

This prints the chain of packages that require `vendor/pkg`.

### Why a target version won't install

```bash
composer why-not vendor/pkg X.Y
```

This explains exactly which constraint blocks upgrading `vendor/pkg` to `X.Y`
(e.g. a direct dependency that requires an older major).

### Rules

* If it's **directly listed in your `composer.json`**, upgrade it normally (step 4).
* If it's **transitive**:
  * Use `composer why vendor/pkg` to find the parent direct dependency.
  * Prefer upgrading the **direct dependency** that pulls it in — that usually
    bumps the transitive package too.
  * Avoid forcing transitive versions. Composer has no clean per-package override
    for transitive deps; pinning one in `composer.json` makes it a direct dep and
    can mask real conflicts. Only do this as a documented temporary measure.

---

## 6) Notes for major upgrades

If the available version is a major bump (e.g. `laravel/framework 10.x → 11.x`):

1. Upgrade it alone in its own commit.
2. Expect breaking changes — read the package's `CHANGELOG.md` / `UPGRADE.md` /
   release notes.
3. If it breaks, either fix code accordingly, or keep it at the latest minor/patch
   within the current major for now.

---

## 7) Minimal command template (copy/paste)

Replace `vendor/pkg` and `X.Y`:

```bash
git checkout -b chore/upgrade-pkg
composer require vendor/pkg:^X.Y      # or: composer update vendor/pkg -W
git diff -- composer.json composer.lock
composer test                          # plus any other detected checks
git add composer.json composer.lock
git commit -m "chore: upgrade vendor/pkg to X.Y"
git checkout main
git merge --no-ff chore/upgrade-pkg
```

---

## 8) Detecting the project's verification commands

PHP has no built-in `analyze`/`test` like Flutter. Detect what the project uses,
in this order, and run those after each upgrade (step 4D) and as the baseline (step 2):

1. **`composer.json` `scripts`** (preferred — they encode the project's intent):

   ```bash
   composer run-script --list
   ```

   Look for `test`, `phpstan`, `psalm`, `lint`, `cs`, `check`. Run e.g.
   `composer test`, `composer phpstan`.

2. **`vendor/bin/` executables** if no matching script exists:

   * Tests: `vendor/bin/phpunit`, `vendor/bin/pest`
   * Static analysis: `vendor/bin/phpstan analyse`, `vendor/bin/psalm`
   * Style: `vendor/bin/php-cs-fixer fix --dry-run`, `vendor/bin/rector --dry-run`

3. **Fallback** if nothing is configured: syntax-check changed files only —

   ```bash
   php -l path/to/File.php
   ```

   Skip static analysis if the project has none.

---

## 9) Final step: Document remaining outdated packages

After all upgrades are complete, document what was upgraded, what was skipped, and
why in `docs/STATUS_OUTDATED_PACKAGES.md`. This gives the next upgrade session full
context.

The document should include:

* **Upgraded packages** — what was upgraded this session with version numbers
* **Skipped direct dependencies** — packages intentionally skipped (major bumps,
  conflicts) with the reason
* **Blocked transitive dependencies** — packages that can only be upgraded by
  upgrading a parent (note the parent from `composer why`)
* **Blocked packages** — packages pinned by the PHP version requirement or a
  third-party constraint that cannot move until external updates happen

---
