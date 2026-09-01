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

- tracked changes vs HEAD: !`git diff --shortstat HEAD`
- untracked files: !`git ls-files --others --exclude-standard | wc -l`

If those two lines already carry values, they were substituted for you - do not re-run
them. If they still show the literal commands, run exactly those two and nothing else.
Both return one line; never substitute `git status --short` or `git diff --stat` here.

## Step 1 - gate, before reading anything

Read the numbers above. Do not run `git diff`, `git status`, or any search yet.

- More than 10 changed files, or more than 500 changed lines: stop. Report the numbers
  and ask the user to rerun with a narrower pathspec. Spawn nothing, read nothing.
- No changes at all, or a supplied pathspec that matches nothing: stop and say so.
- Otherwise continue to step 2.

## Step 2 - delegate to one fresh subagent

Spawn exactly **one** Agent (`subagent_type: general-purpose`, `model: haiku`). Do not
fork this conversation - the audit needs none of it. Do not spawn a second agent. Pass
the brief below verbatim, substituting the pathspec if one was supplied.

Return the agent's report as your answer. Add nothing to it.

---

### Audit brief (pass this to the agent)

You are running a bounded, read-only DRY audit on the uncommitted changes in this
repository. Scope: PATHSPEC_OR_ALL_CHANGES. You may not edit any file.

Tools: use only Read, Grep, Glob, and `git` through Bash. Do not use WebSearch or
WebFetch. Do not `cat`, `rg`, or `find` through Bash - Grep and Glob replace them and
they cap their own output.

Every read is capped by a tool parameter, not by your own counting:

- `Grep` always with `head_limit: 20`. Start with `output_mode: files_with_matches`.
  Escalate at most one term to `output_mode: content` with `-C 2`.
- `Read` always with an explicit `limit: 80` and an `offset`. Never read a whole file.
- Any Bash command ends in `| head -50`.
- Read diffs one path at a time: `git diff HEAD -- <path>`. Never diff the whole tree.

Budget: at most 3 searches, at most 3 unchanged reference files. Stop when you can
support a finding with a file and line reference.

1. List the changed paths with `git diff HEAD --name-only` and, if relevant,
   `git ls-files --others --exclude-standard`. For untracked files use `wc -l` to size
   them; do not load a large one.
2. Read the changed hunks. Read surrounding code only when a hunk is unclear.
3. Look for duplication among the changes, and for existing abstractions the changes
   missed. Do not propose a new abstraction without at least 2 consumers or a clear
   local convention.
4. Run `/ponytail:ponytail-review` scoped to exactly the changed paths from step 1.
   State in the invocation: review only these paths, do not search the repository, do
   not read any file outside this list. If Ponytail is unavailable, do not install it;
   report that the YAGNI gate is incomplete.
5. Report only concrete findings, each with a file and line reference.

Return at most 300 words using only the applicable headings:

## Duplication
## Reuse Opportunities
## YAGNI/KISS
## Verdict

If issues exist, end by asking whether the user wants them fixed. Modify no files.
