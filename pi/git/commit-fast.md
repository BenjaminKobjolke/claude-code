---

name: commit-fast
description: GIT commit changed and new files according to XIDA standards, skipping validation
effort: low
-----------

Commit and push local changes. Skip validation/tests/linters/builds, no
`/validate:pre-commit` (caller already validated). Stop after push — re-invoke for later changes.

## HARD RULES

1. Untracked = commit candidate, not ignore candidate. New/unfamiliar/undocumented is never
   a reason to ignore. Inspect → commit. Ignore only if it matches the table below.
2. Never put ignore rules in `.gitattributes` (it can't ignore files — line endings/binary/diff
   only). Ignore rules go only in `.gitignore`.
3. Never `git add .` — stage explicitly, per logical commit.
4. Never commit `PLAN.md`, `HANDOFF.md`, or real credentials.

## LOOP — do not stop early

Commit in a loop, not one pass:
- After EACH commit: run `git status --short`.
- If anything the user's work touches is still uncommitted, make the NEXT commit.
- Keep going until `git status --short` is empty (ignored files aside).

You are DONE only when BOTH are true:
1. `git status --short` shows nothing left to commit.
2. `git push` succeeded.

One commit is NOT done. Do not hand back, summarize, or stop until both hold.

## Ignore decision table

| Matches | Action |
|---|---|
| source/docs/config/prompt/skill/command file, `pi/`, `commands/**`, `scripts/`, `tools/`, `docs/` | inspect → commit |
| `tmp/commit_msg.tmp`, `claude-plans/` | `.gitignore` it, don't commit |
| `*_test.txt`, `*_test.log`, `debug*.log`, `*.debug.log`, `test_output.*` | grouped pattern in `.gitignore` |
| `PLAN.md`, `HANDOFF.md` | never commit, never ignore |
| `.env*`, `*.pem`, `*.key`, `credentials*.json`, `secrets*.json`, `service-account*.json` w/ real secrets | don't stage; ask user re `.gitignore` |
| unclear | inspect; still unclear → ask user |

`.gitignore` changes from this table = separate `GIT` commit. No rules beyond this table.

## Workflow

1. Inspect: `git status --short`, `git status`, `git diff --stat`, `git diff`, `git diff --cached`,
   `git ls-files --others --exclude-standard`. Include out-of-session changes if they're the
   user's current work.
2. Group by concern (fix/feature/improvement/refactor/docs/tooling/git/tests/content). Unrelated
   → separate commits. One feature spanning files → one commit. Base grouping on actual diffs.
3. `.gitattributes` baseline (create if missing, keep existing extra rules):
   ```gitattributes
   * text=auto eol=lf
   *.bat text eol=crlf
   *.cmd text eol=crlf
   ```
   `.bat`/`.cmd` present but CRLF override missing → add it, convert working-tree files to CRLF
   (`unix2dos`). Commit as separate `GIT` commit.
4. Line-ending warnings (`LF will be replaced by CRLF` etc): ensure baseline above →
   `git config core.autocrlf false` → `git add --renormalize .` → `git diff --cached` → commit
   separately as `GIT` only if real changes → continue with original commits. Don't mix into
   feature/fix commit.
5. `.gitmodules` exists → inspect, commit inside changed submodules first, then commit updated
   pointer in parent. Never blind-commit a submodule pointer.
6. Repeat this cycle until status is clean (never heredoc/command substitution for message,
   never `cd path &&`, never ask user to confirm message):
   ```
   a. Pick ONE logical concern from the remaining changes.
   b. Stage only its files: git add <paths>   (never git add .)
   c. Inspect: git diff --cached
   d. Write message to tmp/commit_msg.tmp — from the real diff, see anti-hallucination below.
   e. git commit -F tmp/commit_msg.tmp
   f. Delete tmp/commit_msg.tmp.
   g. git status --short — if anything remains, go back to (a).
   ```
7. Once status is clean, before push: `git status`, `git log --oneline -10`. Verify — everything
   intended committed, no unrelated bundling, no credentials/temp artifacts, no PLAN.md/
   HANDOFF.md/claude-plans/tmp/commit_msg.tmp, gitignore/gitattributes changes are their own
   `GIT` commit.
8. Push once, at the end: `git branch --show-current`, `git push` (`-u origin <branch>` if no
   upstream). Never `--force`/`--force-with-lease` unless explicitly requested.

## Commit message format

```text
<type> (<scope>): <subject>

<body>

<footer>
```
Lines ≤100 chars. Footer optional.

| Type | Use |
|---|---|
| FEATURE | new functionality |
| FIX | bug fix |
| DOCS | documentation |
| STYLE | formatting, no behavior change |
| TEST | tests are the point |
| CLEANUP | remove code/files |
| IMPROVE | improve existing |
| TOOLS | build/dev tooling |
| GIT | .gitignore/.gitattributes/git config |
| RELEASE | record released version (one per client delivery) |
| CONTENT | images/html/pdf/video |
| REFACTOR | restructure, same behavior |
| PERF | performance |
| CI | pipeline |
| CHORE | maintenance/deps/config |
| AI | prompts/model config/agent settings/skills |
| EXAMPLE | sample/demo code |

Scope: affected feature/component (`header`, `auth`, `api`, `database`...). Subject: imperative
present (`change` not `changed`), lowercase start, no period. Body: imperative present, what+why,
old vs new behavior when useful, `- ` for lists, ≤100 chars/line.

Anti-hallucination: base subject and body ONLY on the diff you inspected. Never invent changes,
files, or reasons. Unsure why a change was made → describe what changed, not a guessed why.

Breaking change footer ONLY when the diff removes or renames a public API/CLI/config contract.
Adding a new file or directory is NOT breaking. When in doubt, no footer.
```text
BREAKING CHANGE: temporarily remove id editing

Change the id directly in XML as a workaround.
```
Include description, justification, migration/workaround.

Issues: `Closes #234` or `Closes #123, #245`. Never invent issue numbers.

Release: `RELEASE (<scope>): <version>` + body.

Example:
```text
FIX (player): restore saved playback position

persist the playback position between sessions and restore it when reopening media
```

Commit order when multiple needed: git config → tooling → refactors → fixes → features → tests →
docs → content → release. Deviate if actual dependencies demand it.

## Checklist

- No validation/tests/linters/builds/`/validate:pre-commit`.
- Don't fix app code discovered mid-commit — this commits existing work only.
- Separate `GIT` commit for `.gitignore`/`.gitattributes` changes.
- Never commit `PLAN.md`, `HANDOFF.md`, `claude-plans/`, `tmp/commit_msg.tmp`, real credentials,
  debug/test artifacts.
- Don't auto-ignore unfamiliar files — inspect, use the table.
- Loop until `git status --short` is clean AND pushed — one commit is not done.
- Never invent commit content or BREAKING CHANGE — use the actual diff.
- Push after all commits succeed, then stop.
