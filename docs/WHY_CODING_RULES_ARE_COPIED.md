# Why Coding Rules Are Copied Instead of Imported

Project coding rules are copied into each project's `CLAUDE.md` instead of being referenced
through Claude Code `@import` lines.

## Why imports were rejected

`@import` expansion is not reliable across every agent and harness that reads `CLAUDE.md`.
Some environments expand the referenced file automatically, while others expose only the literal
`@path` line to the agent. In the latter case, the shared rules are silently absent from the
agent's context.

Adding an instruction telling the agent to read the imported paths did not fully solve the
problem. It still depended on the harness noticing and following that instruction before planning
or implementation. Absolute import paths also tied project instructions to one repository
location and machine layout.

Silent rule omission is more dangerous than having an outdated visible copy. Therefore, the rule
text must be present directly in `CLAUDE.md` so every supported agent receives the same baseline
instructions without relying on import expansion.

## How copied rules stay current

Every rule source begins with a `# Version` block. The version must be increased whenever that
source file changes.

The `coding-rules:add-or-update` command compares each source version with the corresponding
copied rule block in the project's `CLAUDE.md`:

- A missing or lower copied version is replaced with the current source content.
- An equal version is left unchanged.
- A copied version higher than the source is not overwritten automatically and requires user
  reconciliation.

This makes synchronization explicit and detectable while keeping the complete rules available in
the project's instruction context.

## Scope of this decision

This decision applies only to loading shared coding-rule Markdown into project `CLAUDE.md` files.
It does not prohibit imports used by programming languages, build systems, stylesheets, or other
tools.

The decision can be revisited if every supported agent and harness guarantees consistent,
portable, and observable expansion of rule-file imports.
