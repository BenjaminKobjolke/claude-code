---
description: Merge upstream changes into a fork, resolve conflicts, run tests, leave the merge uncommitted
argument-hint: "[upstream url | remote | remote/branch]"
---

# Git Sync Upstream Skill

Use this skill when the current repository is a fork (or otherwise tracks a parent
repository) and the parent's new commits should be integrated:

- "integrate / pull in / sync the upstream changes"
- GitHub shows "This branch is N commits behind `<parent>`"

The goal is a **merge** of the upstream branch into the current branch, with every
conflict resolved by intent and the project's tests green — left **staged but
uncommitted** so the user reviews it before it becomes history. Never rebase, never
commit, never push.

Run every `git` command directly (no `cd /path &&` prefix) — the working directory
is already the target repo.

## Input

`$ARGUMENTS` can be:

1. **Empty** — detect the upstream automatically (Step 2).
2. **A URL** — use it as the upstream repository.
3. **A remote name** (`upstream`) or **remote/branch** (`upstream/main`) — use that.

## Step 1: Preconditions

```
git symbolic-ref -q --short HEAD
git rev-parse -q --verify MERGE_HEAD
git status --short
```

- Detached HEAD (first command prints nothing): stop and tell the user to check out
  a branch.
- A merge is already in progress (`MERGE_HEAD` resolves), or a rebase / cherry-pick
  is: stop and report it. Do not abort someone else's operation.
- Remember the list of dirty files for Step 4.

## Step 2: Resolve the upstream

First hit wins:

1. The argument, if given.
2. An existing remote named `upstream` (`git remote get-url upstream`).
3. The hosting platform's fork parent. On GitHub:
   `gh repo view --json parent --jq ".parent.owner.login + \"/\" + .parent.name"`
   gives `owner/name`; the URL is `https://github.com/<owner>/<name>.git`.
4. Otherwise ask the user for the upstream URL.

If the upstream is not yet a remote, add it and say so in the report:

```
git remote add upstream <url>
```

The `upstream` remote is the only thing this skill persists — the next run finds it
in step 2 of this list.

Branch: the one given in the argument, otherwise the upstream's default branch:

```
git ls-remote --symref upstream HEAD
```

(the `ref: refs/heads/<branch>` line). Do not assume it matches the fork's branch
name — forks of old repositories often have `main` on one side and `master` on the
other.

## Step 3: Fetch and report what is incoming

```
git fetch --no-tags upstream
git log --oneline HEAD..upstream/<branch>
git diff --stat HEAD...upstream/<branch>
```

`--no-tags` is deliberate: upstream release tags must not land in (or collide with)
the fork's own tag namespace.

If the log is empty, report "already up to date with upstream/<branch>" and stop.
Otherwise show the user the incoming commits before continuing.

## Step 4: Predict the conflicts

```
git merge-base HEAD upstream/<branch>
git diff --name-only <base> HEAD
git diff --name-only <base> upstream/<branch>
```

Files in **both** lists are the likely conflicts. For each, read what upstream did
and why (`git log -p <base>..upstream/<branch> -- <file>`) and what the fork did
(`git log -p <base>..HEAD -- <file>`) — the resolution in Step 6 depends on
understanding both intents, not on the conflict markers alone.

Dirty working tree (from Step 1):

- A dirty file is also changed upstream: stop. Tell the user to commit or stash that
  file first — merging over it risks losing the uncommitted work, and
  `git merge --abort` cannot always restore it.
- No overlap: continue, and mention in the report that unrelated uncommitted changes
  were left untouched.

## Step 5: Merge

```
git merge --no-commit --no-ff upstream/<branch>
```

`--no-commit` keeps the merge open even when it applies cleanly; `--no-ff` keeps it
a real merge so it can be reviewed and aborted as one unit.

"refusing to merge unrelated histories": stop and report — the remote is not this
repository's upstream. Never pass `--allow-unrelated-histories`.

## Step 6: Resolve conflicts

List them with `git diff --name-only --diff-filter=U` and view them with
`git diff --diff-filter=U` — a bare `git diff` also dumps every unrelated uncommitted
change in the working tree. Resolve each file by intent:

- **Fork identity wins.** Values that make the fork the fork stay as the fork has
  them: version number, app / package name, update and release URLs, signing and
  publishing config, branding. An upstream version bump never overwrites the fork's
  version.
- **Upstream logic is integrated, not discarded.** Bug fixes, new behaviour and new
  tests from upstream go in, adapted to the fork's code where the fork changed the
  same lines. Keep the fork's own features working alongside them.
- **Both sides added something** (two new tests, two new settings): keep both.
- **Never** resolve wholesale with `-X ours`, `-X theirs`, `git checkout --ours .` or
  `--theirs .` — that silently drops one side's work in every file.
- If it is not clear which side is right, ask the user, showing both versions.

After each file: no conflict markers remain, then `git add <file>`. A file resolved
entirely to the fork's side is identical to `HEAD` and drops out of `git status` —
that is expected, not a lost resolution.

Then look for breaks that produced **no** conflict: for every function, class,
setting or file upstream changed, renamed or removed, search the fork's own code
(the files the fork added or changed since the merge base) for uses of it and adapt
them. A merge that applies cleanly can still be wrong.

Do the same for **data**, not only callers: when upstream changes how something is
loaded, merged or saved, check the config / settings / resource files the fork ships
that go through that code. A changed semantic (e.g. nested settings now merged
instead of replaced) alters the fork's behaviour without touching one line of it.
Report such a change even when nothing needs fixing — existing user configuration
may behave differently after the update.

## Step 7: Verify

Run the tests and code analysis the project's `CLAUDE.md` prescribes for the areas
the merge touched. If the project documents no test command, say so in the report
and suggest `/testing:setup` — do not invent one.

Make sure the tests upstream added or changed are actually among the ones that ran;
a project's fast default suite may not include them. If they are not, run those test
files directly as well.

Fix failures caused by the merge (following the project's coding rules), `git add`
the fixes, and re-run. A failure that also occurs on the pre-merge `HEAD` is not
caused by the merge: report it, do not fix it here.

Code analysis scoped to changed files reports every violation in a file the merge
touched, including ones on lines neither side changed. Fix only what the merge
introduced in the fork's own code. Leave upstream's code in upstream's style (lint
nits, missing trailing newlines): restyling it guarantees conflicts on the next
sync. Report those findings as upstream-owned.

## Step 8: Stop and report

Do **not** commit. Do **not** push. Leave the merge open and report:

- upstream remote and branch (and whether the remote was newly added)
- the incoming commits
- each conflicted file and how it was resolved, plus any non-conflict adaptations
- test / analysis results
- how to finish: review with `git diff --cached`, then a plain `git commit`. A merge
  is concluded by exactly one commit, so the split-by-concern of `/git:commit` does
  not apply. Suggested message:

  ```
  GIT (upstream): merge upstream/<branch> at <short-sha>
  ```

- how to undo: `git merge --abort`

## Notes

- Merge, not rebase: a fork's branch is already published, and rebasing it rewrites
  every fork commit and needs a force-push.
- After the merge commit is pushed, the hosting platform's "N commits behind" count
  drops to zero; "ahead" grows by one (the merge commit).
- Unwanted upstream commits: merge anyway and revert their effect in the resolution
  (as with a version bump). Skipping them by cherry-picking the rest leaves the fork
  permanently "behind" and makes every later sync re-examine them.
