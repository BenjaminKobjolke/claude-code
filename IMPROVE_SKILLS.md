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
| Broad read-only repository research | Fresh spawned subagent, `Explore` |
| Bounded scan with a fixed evidence cap | Fresh spawned subagent, `general-purpose` |
| Read-only audit that invokes another skill | Fresh spawned subagent, write tools disabled |
| Rewrite exactly one supplied file | Keep inline with strict path validation |
| Needs the current conversation or active plan | Keep inline, or redesign it to accept an explicit file |
| Simple deterministic instruction | Keep inline and avoid agent overhead |

**`context: fork` inherits the entire parent conversation** - history, system prompt,
tools, and model. It is a copy of the current session, not a clean slate. A command
that runs late in a long session therefore starts near the context limit before it
reads a single line, which is exactly how a bounded audit still overflows 200k.

There is no `fresh` or `isolated` value; `fork` is the only one. To get a clean
context, drop `context:`/`agent:` from the frontmatter and have the command body spawn
one fresh subagent with a self-contained brief. The command keeps a thin wrapper in the
main thread that gates the request and returns the subagent's report unchanged.

Use `context: fork` only when the skill genuinely needs the session so far. A skill
that says "check the plan above" is better redesigned to take an explicit file path
through `$ARGUMENTS`.

Do not pick `Explore` for a bounded scan. Its own charter is broad fan-out across many
files and directories, which works against a command that caps its evidence.

## Use focused frontmatter

A bounded read-only research command can use:

```yaml
---
description: Run a scoped repository check
model: haiku
effort: low
disallowed-tools: Edit, Write, NotebookEdit
---
```

No `context:` and no `agent:`. The wrapper stays in the main thread; the body spawns
one fresh `general-purpose` subagent and returns its report unchanged. `disallowed-tools`
keeps the wrapper read-only, and the brief restates the tool restriction for the
subagent, which does not inherit the frontmatter.

To gate before spending any context, inject the measurement into the prompt with
`` !`command` ``. The output is substituted before the model runs, so the gate reads
facts instead of calling a tool that can return a large payload. Injection needs no
`allowed-tools` entry:

```markdown
- tracked changes vs HEAD: !`git diff --shortstat HEAD`
- untracked files: !`git ls-files --others --exclude-standard | wc -l`
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

A budget is only real when something other than the model enforces it. The model has
no counter for lines it already read, so a number in prose is intent, not enforcement.
Back every limit with a mechanism:

- a tool parameter: `Grep` `head_limit`, `Read` `limit` and `offset`
  (the defaults are 250 matches and 2000 lines - always override them explicitly);
- a shell truncation: `| head -50` on every command;
- a tool restriction, so the dumping path does not exist. Bash caps nothing: a `cat`
  or an unrestricted `rg` defeats any instruction not to dump.

Prefer a one-line measurement over a listing when gating. `git diff --shortstat` and
`git ls-files --others --exclude-standard | wc -l` size a change in two lines, where
`git status --short` can be thousands in a repository with build output. Gate on the
measurement *before* anything is read, or the gate can no longer refuse in time.

Instructions such as "search only what is relevant" are too subjective. State
measurable limits alongside the mechanism:

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

## Bound secondary skills

When a workflow intentionally keeps a second review such as Ponytail, invoke it inside
the same subagent so its searches and reasoning stay out of the main context.

**A secondary skill does not inherit the primary command's budget.** Limits written for
steps 1-5 do not reach a hand-off in step 6, so that pass scans freely unless the scope
is restated. Name the exact paths in the invocation and forbid anything wider: review
only these paths, do not search the repository, do not read a file outside this list.

Invoke the skill that does the work, not the one that sets a mode. `/ponytail:ponytail`
switches persona and then re-audits from scratch; `/ponytail:ponytail-review` is the
reviewer that returns findings directly.

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
- Confirm the gate refuses an over-limit scope with zero reads and no subagent spawned.
- Confirm a secondary skill pass touches only the paths named in its hand-off.
- Compare usage in a long session as well as a fresh one: a command that inherits
  context only fails once the parent conversation is already large.

## Examples in this repository

- `commands/convention/check.md`: thin wrapper that gates on `$ARGUMENTS`, then hands a
  self-contained brief to one fresh subagent.
- `commands/dry/check.md`: injected one-line size measurement, a gate that spawns
  nothing when the change is too large, then one fresh subagent with a scoped Ponytail
  pass.
- `commands/plan/dry.md`: explicit file input, isolated rewrite, and compact handoff.
- `commands/plan/dry-checked.md`: reloads the complete reviewed plan without repeating
  the analysis.

The guiding rule is simple: give each skill the smallest context, tool set, search
budget, and output contract that can still produce a trustworthy result.
