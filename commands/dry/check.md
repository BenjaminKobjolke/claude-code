---
description: Run a bounded post-implementation DRY audit on changed code
argument-hint: "[pathspec]"
model: haiku
effort: low
disallowed-tools: Edit, Write, NotebookEdit
---

Audit changed code for duplication, missed reuse, and unnecessary complexity. This
command is read-only.

Optional scope: $ARGUMENTS

Changed-scope size:

- tracked changes vs HEAD: !`git diff --shortstat HEAD 2>/dev/null || echo "NOT A GIT REPO"`
- untracked files: !`git ls-files --others --exclude-standard 2>/dev/null | wc -l`

If those two lines already carry values, they were substituted for you - do not re-run
them. If they still show the literal commands, run exactly those two and nothing else.
Both return one line; never substitute `git status --short` or `git diff --stat` here.

Not a git repo (the first line says `NOT A GIT REPO`): the only valid scope is the supplied
pathspec — size it by counting its entries. Without a pathspec, stop and ask for one (a
changed-files list, one path per line). Never widen the scope with git in that case. The
`2>/dev/null || echo` guard exists because a failing frontmatter substitution aborts the
whole command before any of this text loads.

## Step 1 - gate, before reading anything

Read the numbers above. Do not run `git diff`, `git status`, or any search yet.

- More than 10 changed files, or more than 500 changed lines: stop. Report the numbers
  and ask the user to rerun with a narrower pathspec. Spawn nothing, read nothing.
- No changes at all, or a supplied pathspec that matches nothing: stop and say so.
- Otherwise continue to step 2.

## Step 2 - run the audit once, in a fresh context if the host has one

If the host provides subagents, spawn exactly **one** (`subagent_type: general-purpose`,
`model: haiku`) and pass the brief below verbatim, substituting the pathspec if one was
supplied. Do not fork this conversation - the audit needs none of it. Never spawn a second
one.

If the host has no subagent mechanism (Codex and other shell-only hosts), follow the brief
yourself, inline, in this session. Do not report the audit as blocked.

Return the report as your answer. Add nothing to it.

---

### Audit brief (pass this to the agent)

You are running a bounded, read-only DRY audit on the uncommitted changes in this
repository. Scope: PATHSPEC_OR_ALL_CHANGES. You may not edit any file.

**Read-only: never edit, create, or delete a file.** Do not use the web. Use whatever
read/search tools the host has - Claude: `Read`/`Grep`/`Glob` plus `git` through Bash;
shell-only hosts: `rg`, `sed -n 'START,ENDp'` and `git`. Prefer a capped tool over a raw
shell command where the host offers one.

Every read is capped, by a tool parameter where one exists and by the shell otherwise:

- At most 20 matches per search (`head_limit: 20`, or `rg ... | head -20`). Start with
  filenames only (`output_mode: files_with_matches`, or `rg -l`); escalate at most one term
  to matching lines with 2 lines of context (`output_mode: content` with `-C 2`, or
  `rg -C 2`).
- Never read more than ~80 lines of a file at a time (`limit: 80` plus an `offset`, or
  `sed -n '1,80p'`). Never read a whole file.
- Every shell command ends in `| head -50`.
- Read diffs one path at a time: `git diff HEAD -- <path>`. Never diff the whole tree.

Budget: at most 3 searches, at most 3 unchanged reference files. Stop when you can
support a finding with a file and line reference.

1. List the changed paths with `git diff HEAD --name-only` and, if relevant,
   `git ls-files --others --exclude-standard`. For untracked files use `wc -l` to size
   them; do not load a large one. If the repository is not a git repo, skip every git
   command: the scope pathspec IS the changed list, and each listed file is read whole.
2. Read the changed hunks. Read surrounding code only when a hunk is unclear.
3. Look for duplication among the changes, and for existing abstractions the changes
   missed. Do not propose a new abstraction without at least 2 consumers or a clear
   local convention.
4. If the host has `/ponytail:ponytail-review`, run it scoped to exactly the changed paths
   from step 1. State in the invocation: review only these paths, do not search the
   repository, do not read any file outside this list. If it is unavailable, do not install
   it - apply the same YAGNI/KISS judgement to those paths yourself and say in the verdict
   that Ponytail was not available.
5. Report only concrete findings, each with a file and line reference.

Return at most 300 words using only the applicable headings:

## Duplication
## Reuse Opportunities
## YAGNI/KISS
## Verdict

If issues exist, end by asking whether the user wants them fixed. Modify no files.
