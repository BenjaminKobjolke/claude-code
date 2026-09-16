---
description: Run a scoped, token-efficient convention scan before implementing changes
model: haiku
effort: low
disallowed-tools: Edit, Write, NotebookEdit
---

Find conventions relevant to this proposed change: $ARGUMENTS

## Step 1 - gate

If `$ARGUMENTS` is empty, stop. Ask for a concrete change description. Do not inspect
the repository and do not spawn anything.

## Step 2 - run the scan once, in a fresh context if the host has one

If the host provides subagents, spawn exactly **one** (`subagent_type: general-purpose`,
`model: haiku`) and pass the brief below verbatim with `$ARGUMENTS` substituted. Do not fork
this conversation - the scan needs none of it, only the change description. Never spawn a
second one.

If the host has no subagent mechanism (Codex and other shell-only hosts), follow the brief
yourself, inline, in this session. Do not report the scan as blocked.

Return the report as your answer. Add nothing to it.

---

### Scan brief (pass this to the agent)

You are running a bounded, read-only convention scan for this proposed change:
CHANGE_DESCRIPTION. You may not edit any file.

**Read-only: never edit, create, or delete a file.** Do not use the web. Use whatever
read/search tools the host has - Claude: `Read`/`Grep`/`Glob`; shell-only hosts: `rg` and
`sed -n 'START,ENDp'`.

Every read is capped, by a tool parameter where one exists and by the shell otherwise:

- At most 20 matches per search (`head_limit: 20`, or `rg ... | head -20`). Start with
  filenames only (`output_mode: files_with_matches`, or `rg -l`); escalate at most one term
  to matching lines with 2 lines of context (`output_mode: content` with `-C 2`, or
  `rg -C 2`).
- Never read more than ~80 lines of a file at a time (`limit: 80` plus an `offset`, or
  `sed -n '1,80p'`). Never read a whole file, a whole directory, or a large file in full.

1. Classify the smallest affected area: UI, backend/service, data/model,
   translations/content, tests, tooling, or documentation.
2. First pass. Derive at most 3 concrete search terms from the change description and
   make at most 3 searches. Read at most 3 representative files. Inspect only
   convention types relevant to the classified area - reusable components, service/DI
   patterns, validation/serialization, translation syntax, tests, or tooling structure.
3. Stop as soon as either one implementation plus corroborating test/config/usage
   evidence, or two consistent implementations, establish the convention.
4. If the evidence is missing or conflicting, run one expansion pass only: at most 2
   more searches and 2 more files. Then stop and report the gap or the conflict.
5. Mention reuse and DRY opportunities visible in that evidence. Do not run a separate
   DRY search, a manifest inventory, or an architecture survey.

Return at most 250 words and cite at most 3 representative paths. Use only these
headings, omitting empty ones:

## Conventions
## Reuse
## Constraints or Gaps

Make no code changes.
