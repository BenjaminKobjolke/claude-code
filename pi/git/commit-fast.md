---

name: commit-fast
description: GIT commit and push changed and new files according to XIDA standards, skipping validation
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
5. Fast-path group (table below) = fixed message, no body, no diff read. Don't overthink it.

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
| root-level `PLAN_*.md` | add `/PLAN_*.md` to `.gitignore` (anchored), don't commit |
| `.claude/` | ensure `.claude/` in `.gitignore`, don't commit |
| `.env*`, `*.pem`, `*.key`, `credentials*.json`, `secrets*.json`, `service-account*.json` w/ real secrets | don't stage; ask user re `.gitignore` |
| unclear | inspect; still unclear → ask user |

`.gitignore` changes from this table = separate `GIT` commit. No rules beyond this table.

## Fast path — canonical messages

Check BEFORE grouping and before reading any diff. If EVERY file in a commit group matches
one row: use that message verbatim, NO body, and read only `--stat` — never the full patch.

| Whole group is | Message |
|---|---|
| `.gitignore` | `GIT (ignore): update ignore list` |
| `.gitattributes` | `GIT (attributes): update line ending rules` |
| `.gitignore` + `.gitattributes` | `GIT (config): update git config files` |
| `README.md` | `DOCS (readme): update readme` |
| `*.md`, none of them prompt files (see carve-out) | `DOCS (docs): update documentation` |

Carve-out: a `.md` under `commands/`, `pi/`, `skills/`, `.claude/`, `.codex/`, or any
`*/SKILL.md` is an AI prompt, not documentation. Those take type `AI` with a real scope and
subject — no DOCS fast path.

Fast path is per group, not per run. A group holding `.gitignore` AND source code is
mis-grouped — split it, then re-check.

## Workflow

1. Inspect — 3 commands, not more:
   ```
   git status --short                  # full picture, untracked (??) included
   git --no-pager diff HEAD --stat     # sizes, to decide what is worth reading
   git --no-pager diff HEAD -- <paths> # full patch, only where needed
   ```
   `--stat` ONLY (never the full patch) for: lockfiles (`package-lock.json`, `composer.lock`,
   `yarn.lock`, `uv.lock`, `pubspec.lock`), generated/minified/build output, binaries, and any
   file with >300 changed lines — describe the file ("regenerate lockfile"), not its lines.
   Untracked files outside a fast-path row: read enough to classify, not the whole file.
   Include out-of-session changes if they're the user's current work.
2. Group by concern (fix/feature/improvement/refactor/docs/tooling/git/tests/content). Unrelated
   → separate commits. One feature spanning files → one commit. Base grouping on actual diffs.
3. `.gitattributes` — REACTIVE only. Do NOT audit it every run. Act only if git emits a
   line-ending warning, OR the repo has `.bat`/`.cmd` files and no `.gitattributes` at all.
   Then ensure this baseline (create if missing, keep existing extra rules):
   ```gitattributes
   * text=auto eol=lf
   *.bat text eol=crlf
   *.cmd text eol=crlf
   ```
   Convert working-tree `.bat`/`.cmd` files to CRLF (`unix2dos`). Separate `GIT` commit.
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
   c. Inspect: git diff --cached   (skip for a fast-path group)
   d. Commit:
      - one-line message -> git commit -m "<message>"   (no temp file)
      - message w/ body  -> write tmp/commit_msg.tmp, git commit -F tmp/commit_msg.tmp,
                            then delete tmp/commit_msg.tmp
      Message needs a backtick, $ or " -> use the temp file regardless of length.
   e. git status --short — if anything remains, go back to (a).
   ```
7. Once status is clean, before push: `git log --oneline -5`. Verify — no unrelated bundling,
   no credentials/temp artifacts, no PLAN.md/HANDOFF.md/claude-plans/tmp/commit_msg.tmp,
   gitignore/gitattributes changes are their own `GIT` commit. (No second `git status` — the
   loop already exited on a clean one.)
8. Push once, at the end: `git branch --show-current`, `git push` (`-u origin <branch>` if no
   upstream). Never `--force`/`--force-with-lease` unless explicitly requested.

## Commit message format

```text
<type> (<scope>): <subject>

<body>

<footer>
```
Lines ≤100 chars. Body and footer optional.

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

Body is OPTIONAL — write one only when it records a why or an old-vs-new the subject can't
carry. Subject-only is correct for: fast-path commits, renames/moves, single-file obvious
changes, dependency bumps. Never restate the subject as a body.

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
- Fast-path group → canonical message, no body, no full diff.
- One-line message → `git commit -m`, no temp file.
- Separate `GIT` commit for `.gitignore`/`.gitattributes` changes.
- `.gitattributes` audit only on a line-ending warning or `.bat`/`.cmd` with no `.gitattributes`.
- Never commit `PLAN.md`, `HANDOFF.md`, `claude-plans/`, `tmp/commit_msg.tmp`, real credentials,
  debug/test artifacts.
- Don't auto-ignore unfamiliar files — inspect, use the table.
- Loop until `git status --short` is clean AND pushed — one commit is not done.
- Never invent commit content or BREAKING CHANGE — use the actual diff.
- Push after all commits succeed, then stop.
