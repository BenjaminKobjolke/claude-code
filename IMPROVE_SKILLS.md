# Improving Skills Without Wasting Tokens

This guide explains how to make Claude Code commands and their generated Codex
skills cheaper, more predictable, and less likely to fill the main conversation
with repository-search output.

In this repository, `commands/` is the source of truth. Claude reads those files
directly through `~/.claude/commands`, while `tools/sync_commands_to_codex.bat`
generates the corresponding Codex skills.

## Diagnose the token problem first

Separate these costs before changing a skill:

- **Instruction size**: the command body itself remains in context.
- **Exploration cost**: searches and file reads consume tokens while the command runs.
- **Main-context growth**: inline tool results reduce the space left for implementation.
- **Total model cost**: an expensive model may be unnecessary for mechanical research.
- **Duplicate passes**: multiple skills may inspect the same plan, diff, or files.

Shortening the prompt helps, but repository exploration is usually the larger cost.
The strongest improvement is to isolate that exploration and return only a compact
summary.

## Choose the execution shape

| Skill behavior | Recommended execution |
| --- | --- |
| Read-only repository research | `context: fork`, `agent: Explore` |
| Read-only audit that invokes another skill | Forked `general-purpose` agent with write tools disabled |
| Rewrite exactly one supplied file | Forked `general-purpose` agent with strict path validation |
| Needs the current conversation or active plan | Keep inline, or redesign it to accept an explicit file |
| Simple deterministic instruction | Keep inline and avoid agent overhead |

`context: fork` does not provide the subagent with the current conversation. Do not
add it to a skill that says "check the plan above" or otherwise depends on session
history. First save the input to a file and pass that path through `$ARGUMENTS`.

## Use focused frontmatter

A bounded read-only research command can use:

```yaml
---
description: Run a scoped repository check
context: fork
agent: Explore
model: haiku
effort: low
---
```

If the fork must invoke another skill, use `general-purpose`. For an audit that
must remain read-only, remove its write tools:

```yaml
agent: general-purpose
disallowed-tools: Edit, Write, NotebookEdit
```

For file-based commands, add a clear argument hint:

```yaml
argument-hint: <plan-path>
```

Quote hints that use square brackets so YAML treats them as text:

```yaml
argument-hint: "[pathspec]"
```

Use model aliases such as `haiku` instead of fixed model IDs unless a skill needs
a specific version. Omit `background` when compatibility with Claude Code versions
before 2.1.218 is required; those versions already wait for forked skills.

## Replace vague guidance with hard budgets

Instructions such as "search only what is relevant" are too subjective. State
measurable limits instead:

- Maximum number of search calls.
- Maximum displayed matches per search.
- Maximum representative files and relevant lines to read.
- At most one explicitly bounded expansion pass.
- A scope threshold, such as 10 changed files or 500 changed lines.
- A final response word limit and maximum number of cited paths.

Also define a stop condition. For example, stop after finding one implementation
plus corroborating test/config evidence, or two consistent implementations.

Prefer filename or count results before content. Inspect changed hunks before whole
files, count untracked-file lines without loading their contents, and never emit
unrestricted recursive-search output.

## Protect file-based workflows

A skill that rewrites a file should:

1. Require exactly one explicit path.
2. Reject missing paths, multiple paths, directories, wildcards, and wrong extensions.
3. Resolve relative paths from the working directory and rely on normal permissions
   for external absolute paths.
4. Read the complete input before editing.
5. Modify only that file and never begin implementation work.
6. Re-read the result and verify that goals, decisions, constraints, tests, and open
   questions were preserved.

An output cap applies only to the chat summary. Say this explicitly so the agent
does not shorten or truncate the underlying plan to satisfy the response limit.

## Keep secondary skills inside the fork

When a workflow intentionally keeps a second review such as Ponytail, invoke it
inside the same fork. Its searches and reasoning then stay out of the main context.

State what happens if the dependency is unavailable. For audit commands in this
repository, report the gate as incomplete and do not install plugins automatically.
Do not duplicate the secondary skill's work in the main command unless both passes
are intentionally required.

## Keep the returned result compact

The parent conversation usually needs decisions and evidence, not the research
transcript. Limit the result to applicable sections, representative paths, concrete
constraints, and unresolved ambiguity. Omit empty headings and boilerplate.

For a file-rewriting skill, return only:

- The resolved target path.
- The important changes applied.
- The result of any required secondary gate.
- Whether the workflow is complete or blocked.

## Preserve Claude and Codex compatibility

Claude-specific frontmatter such as `context`, `agent`, `model`, `effort`, tool
restrictions, and argument hints applies to the source command. The sync tool rebuilds
Codex `SKILL.md` frontmatter using only the generated name and description. Codex still
receives the command body, so hard search/read/output budgets must live in the body,
not only in Claude metadata.

After changing a command, run:

```bat
tools\sync_commands_to_codex.bat
python tools\sync_commands_to_codex.py --self-test
git diff --check
```

## Verification checklist

- Test missing and invalid arguments without allowing repository reads or writes.
- Test the smallest normal case and confirm the first-pass budget is enough.
- Test conflicting or missing evidence and confirm only one expansion pass occurs.
- Test the over-limit case and confirm the command requests a narrower scope.
- Test staged, unstaged, and untracked files for diff-based audits.
- Confirm read-only commands cannot edit files.
- Confirm file-rewriting commands touch only the explicit target.
- Confirm response limits do not truncate persisted files.
- Compare usage in fresh sessions so earlier context does not distort the result.

## Examples in this repository

- `commands/convention/check.md`: isolated Explore scan with bounded evidence.
- `commands/dry/check.md`: bounded read-only audit with a secondary Ponytail pass.
- `commands/plan/dry.md`: explicit file input, isolated rewrite, and compact handoff.
- `commands/plan/dry-checked.md`: reloads the complete reviewed plan without repeating
  the analysis.

The guiding rule is simple: give each skill the smallest context, tool set, search
budget, and output contract that can still produce a trustworthy result.
