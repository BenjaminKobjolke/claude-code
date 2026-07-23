---
description: Diagnose and permanently fix Git CRLF/LF line-ending warnings in a repository
effort: low
---

# Git Fix Line Endings Skill

Use this skill when Git prints line-ending warnings such as:

- `warning: in the working copy of '<file>', CRLF will be replaced by LF the next time Git touches it`
- `warning: LF will be replaced by CRLF the next time Git touches it`
- files showing as modified only because of line-ending changes

The goal is to make the warning stop **permanently** by aligning three things: the
global `core.autocrlf` setting, the repo's `.gitattributes` policy, and the bytes
stored in the committed blobs.

Run every `git` command directly (no `cd /path &&` prefix) — the working directory
is already the target repo.

## Root cause

The warning almost always comes from a conflict between the user's **global**
`core.autocrlf=true` (common on Windows) and a repository that wants a fixed
line-ending policy. On every `git add`, autocrlf tries to convert endings and warns.
The clean fix is to let `.gitattributes` be the single source of truth and tell the
repo to stop second-guessing it via autocrlf.

## Step 1: Diagnose

```
git config --get core.autocrlf
git config --global --get core.autocrlf
test -f .gitattributes && cat .gitattributes || echo "no .gitattributes"
git ls-files --eol | grep -E 'w/crlf|w/mixed' | head
```

Note whether global autocrlf is `true`, whether a `.gitattributes` exists, and which
files Git sees as needing conversion.

## Step 2: Ensure `.gitattributes` exists (LF policy)

If there is no `.gitattributes`, create one that normalizes text to LF and marks
common binaries (binary files must never be eol-converted):

```
# Normalize all text files to LF in the repository
* text=auto eol=lf

# Windows batch files must be CRLF - cmd.exe misparses LF-only scripts
# (e.g. "set" lines break into fragments, vars stay empty)
*.bat text eol=crlf
*.cmd text eol=crlf

# Explicitly mark binary files
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.pdf binary
*.zip binary
*.gz binary
*.tar binary
```

**The `*.bat`/`*.cmd` CRLF override is mandatory whenever the repo contains batch
files** — an LF catch-all without it checks batch files out with LF endings, and
cmd.exe then misparses them: `set` lines break into command fragments (`'et' is not
recognized...`) and the variables silently stay empty. If an existing
`.gitattributes` has the LF catch-all but lacks this override, add the override
(later rules win) instead of overwriting the file, then convert the working-tree
`.bat`/`.cmd` files to CRLF with `unix2dos` — include gitignored ones (local config
bats break the same way). The stored blobs stay LF (`eol=crlf` converts on
checkout), so tracked files normally produce no content diff; a plain
`git add -- '*.bat'` just refreshes the index. The same applies to any other
CRLF-required types the repo carries (e.g. `*.reg`).

If a `.gitattributes` already exists with a sensible policy, keep it — do not
overwrite the project's chosen convention.

## Step 3: Stop autocrlf from fighting the attributes

Set the repo-local config so `.gitattributes` wins. This is the key fix and it
persists in `.git/config`:

```
git config core.autocrlf false
```

This is **local to the repo** and does not touch the user's global setting (other
repos keep their behavior).

## Step 4: Renormalize the committed content (only if needed)

The committed blobs may still contain the old endings. Restage them through the
attribute filter:

```
git add --renormalize .
```

- If this stages **0 files** (`git diff --cached --stat` is empty), the history is
  already normalized — there is nothing to commit. Skip to verification.
- If it stages files, commit them as a dedicated GIT commit (do not bundle with
  other work):

  Write the message to `tmp/commit_msg.tmp` and run `git commit -F tmp/commit_msg.tmp`,
  then delete the temp file. Suggested message:

  ```
  GIT (attributes): normalize repository line endings to LF

  - set repo-local core.autocrlf=false so .gitattributes governs endings
  - renormalize tracked files via git add --renormalize
  ```

  Also stage `.gitattributes` if it was newly created in Step 2 (same commit is fine).

## Step 5: Verify

```
git add <a-previously-warned-file>
```

Confirm **no** `CRLF will be replaced` / `LF will be replaced` warning appears and
that nothing unexpected is staged, then `git reset` to unstage the probe.

```
git ls-files --eol | grep -c 'w/crlf'
git status --short
```

Report to the user: what was changed (local `core.autocrlf`, `.gitattributes`
created or kept, whether a renormalize commit was made), and that the warning is now
resolved.

## Notes

- `core.autocrlf=false` here is local-only and is **not** committed. Other clones of
  the same repo on Windows will see the warning until they also run this skill, but
  the committed `.gitattributes` is what guarantees consistent endings in history.
- Do not push unless the user asked, or unless Step 4 produced a normalization commit
  that the user wants shared — confirm before pushing.
