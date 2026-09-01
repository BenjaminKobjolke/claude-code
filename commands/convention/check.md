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

## Step 2 - delegate to one fresh subagent

Spawn exactly **one** Agent (`subagent_type: general-purpose`, `model: haiku`). Do not
fork this conversation - the scan needs none of it, only the change description. Do not
spawn a second agent. Pass the brief below verbatim with `$ARGUMENTS` substituted.

Return the agent's report as your answer. Add nothing to it.

---

### Scan brief (pass this to the agent)

You are running a bounded, read-only convention scan for this proposed change:
CHANGE_DESCRIPTION. You may not edit any file.

Tools: use only Read, Grep, and Glob. Do not use Bash, WebSearch, or WebFetch.

Every read is capped by a tool parameter, not by your own counting:

- `Grep` always with `head_limit: 20`. Start with `output_mode: files_with_matches`.
  Escalate at most one term to `output_mode: content` with `-C 2`.
- `Read` always with an explicit `limit: 80` and an `offset`. Never read a whole file,
  a whole directory, or a large file in full.

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
