---
description: Retry the longest-unchecked pinned Flutter package to see if its blocker is fixed upstream
---

### Retry a pinned package

#### Goal

Every exact pin and `dependency_overrides` entry in `pubspec.yaml` carries a
`PIN` comment with the date it was pinned, the date it was last re-evaluated,
and why. This command picks the pin nobody has re-checked in the longest time,
tries to lift it, verifies, and then either keeps the upgrade or restores the
pin with a fresh `checked` date and an updated reason.

One pin per run. Do not batch several pins into one verification.

---

## 0) The PIN comment format

Every pinned dependency and every override is annotated directly above its line:

```yaml
  # PIN <pinned-date> | checked <last-check-date> | <why it is pinned>
  html: 0.15.6
```

- `PIN <date>` — when the pin was first introduced. Never changes.
- `checked <date>` — when the pin was last actually re-tried. **This command
  always updates it**, whether the retry succeeded or failed.
- reason — one line: the concrete blocker, or
  `no known blocker - exact version is just how the dep was first added`.

Multi-line reasons continue on further `#` lines below the `PIN` line.

If a pinned dependency has no `PIN` comment, add one before proceeding: get the
introduction date with
`git log --format="%ad %s" --date=short -S"  <package>: " -- pubspec.yaml | tail -1`
and set `checked` to that same date.

---

## 1) Preconditions

1. Clean Git working tree — ask the user to commit or stash first.
2. `fvm flutter --version` works.
3. Read `docs/STATUS_OUTDATED_PACKAGES.md` for the history behind each pin.

## 2) Pick the target pin

```bash
grep -n "PIN 20" pubspec.yaml
```

Choose the entry with the **oldest `checked` date**. If the user named a
package in the arguments, use that one instead.

Report the choice to the user before changing anything: package, current pin,
pin date, last-checked date, recorded reason, and the latest published version
(`fvm flutter pub outdated`).

Skip (and just refresh the `checked` date, noting why) when:

- the blocker is another dependency's constraint and that dependency is
  unchanged since the last check — verify with
  `fvm flutter pub deps --style=compact`;
- the only available upgrade is a breaking major the user has explicitly
  deferred, unless the user asks for the migration now.

## 3) Lift the pin

Edit only that one entry:

- reason was `no known blocker` → loosen exact to caret: `1.7.1` → `^1.7.1`.
- reason was a real blocker → set the constraint that the blocker prevented,
  e.g. `html: 0.15.6` → `html: ^0.15.6`.

Keep the `PIN` comment in place for now; it is edited in step 6.

```bash
fvm flutter pub upgrade
```

If resolution fails, the blocker still stands. Go to step 6 (failure path) —
the resolver error itself is the updated reason.

## 4) Verify

```bash
fvm flutter analyze --no-pub
tools/tests.bat
```

**`flutter analyze` does not catch this class of failure.** A pinned package is
usually pinned because a *dependency's own source* stops compiling against a
newer sibling; analyze reports `No issues found!` while every test fails to
load. The test run is the real gate — never conclude success from analyze alone.

Windows/FVM notes:

- `tools/tests.bat` is long (minutes). Redirect it to a log file and run it in
  the background; a backgrounded pipe fills and blocks the child forever.
- The bat can report exit code 0 even when tests failed. Grep the log for
  `Some tests failed` and `FAILED:` rather than trusting the exit code.
- Read the first `Error:` line in the log — for a package-level break it names
  the offending file inside the pub cache, which identifies the culprit package.

## 5) Decide

- analyze clean **and** tests fully green → keep the upgrade.
- anything fails → restore the exact pin and re-run `fvm flutter pub upgrade`
  to get back to the known-good resolution. Re-run the tests once to confirm
  the restore is green before finishing.

## 6) Update the PIN comment (always)

Success — remove the `PIN` comment together with the pin, leaving the ordinary
descriptive comment:

```yaml
  # For HTML DOM parsing
  html: ^0.15.6
```

Failure — keep the pin, keep `PIN <original-date>`, set `checked` to today, and
rewrite the reason to what actually happened this run (quote the decisive error
line, not the whole log):

```yaml
  # PIN 2026-08-30 | checked 2026-11-02 | still broken: html_viewer_elite 0.0.6
  # calls StyledElement.matches, removed in html 0.15.7. Retry after that package updates.
  html: 0.15.6
```

Use absolute dates only — never "today" or "last month".

## 7) Document

Append to `docs/STATUS_OUTDATED_PACKAGES.md` under a dated heading:

- the pin retried and its age;
- outcome (unpinned, or still blocked);
- the decisive error or resolver message;
- what has to change upstream for the next retry to succeed;
- analyze and test results.

`pubspec.lock` is gitignored — only `pubspec.yaml` changes commit. Leave changes
committed or uncommitted according to the user's request.

## 8) Failure handling

- Do not add a `dependency_overrides` entry to force a pin open. An override
  needs explicit user approval and its own `PIN` comment stating the conflict it
  papers over.
- If a stale Kotlin incremental cache breaks an Android build after a plugin
  version change, run `fvm flutter clean` once and rebuild.
- If the retry cascades into unrelated resolution changes, restore the pin and
  report — a pin retry should move one package, not re-resolve the world.
