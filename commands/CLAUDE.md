# Commands

Documentation for commands in this directory and their dependencies.

## Ponytail plugin

Some commands run `/ponytail` for a YAGNI / over-engineering check.

Install:

```
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
```

Commands using ponytail:

- `plan/dry.md` — DRY check on a plan, then `/ponytail` YAGNI pass
- `dry/check.md` — post-implementation DRY audit, then `/ponytail` YAGNI pass

## coding-rules plugin

The coding rules and their commands moved to a dedicated plugin repo:
https://github.com/BenjaminKobjolke/claude-coding-rules
(local clone: `D:\GIT\BenjaminKobjolke\claude-coding-rules`)

Install:

```
/plugin marketplace add BenjaminKobjolke/claude-coding-rules
/plugin install coding-rules@claude-coding-rules
```

Skills: `/coding-rules:apply` (was `commands/coding-rules/add-or-update.md`) and
`/coding-rules:enforce` (was `commands/coding-rules/enforce.md`). The old
`commands/coding-rules/` folder and the `coding-rules/` rule files were removed
from this repo; the plugin bundles the rules itself, so projects no longer need
a rules folder path in CLAUDE.md.

## Codex sync

These commands are used by Codex too, not just Claude. Claude reads `commands/`
directly (symlinked into `~/.claude/commands`), but Codex loads **skills** from
`~/.codex/skills/<name>/SKILL.md`.

After adding, editing, or removing any command, run:

```
tools/sync_commands_to_codex.bat
```

This regenerates the Codex copies: each `commands/<cat>/<name>.md` becomes a skill
`~/.codex/skills/<cat>-<name>/SKILL.md` (e.g. `git/commit.md` -> `git-commit`).
The sync is one-way (`commands/` is the source of truth) and auto-removes stale
skills whose source command was renamed or deleted. Codex's own `.system/` skills
and symlinked skills are left untouched.

### Write command bodies host-neutral

The sync copies each command **body byte-for-byte**; only Claude-only *frontmatter* keys are
dropped (`DROP_KEYS` in `sync_commands_to_codex.py`). So a body written against Claude Code's
tool names ships to Codex as a broken skill.

This is not theoretical. `convention/check.md` used to say "use only Read, Grep, and Glob. Do
not use Bash" and "spawn exactly one Agent". Codex has neither Read/Grep/Glob nor subagents -
shell is its only tool, and the skill forbade it. Run as the coding-rules delegate, Codex
declared itself blocked, wrote `## DELEGATE QUESTIONS` into the plan, and returned no findings
at all. A Claude-ism in a delegated command does not degrade the result, it produces nothing.

Rules for every command body:

- **Describe the capability, not the tool.** "Search the repo read-only", not "use Grep".
  Where naming tools helps, name both hosts on one line: "Claude: `Read`/`Grep`/`Glob` -
  shell-only hosts: `rg` / `sed -n 'START,ENDp'`".
- **Never mandate a Claude-only mechanism.** Subagents (`Agent`, `subagent_type`, `Task`),
  plugin skills (`/ponytail:*`), MCP servers and hooks are Claude-side. Make each conditional:
  "if the host provides subagents, run it there; otherwise run the brief inline" / "if
  `/ponytail:ponytail-review` exists, run it; otherwise apply the same judgement yourself and
  say so". Never let the absence of one be a reason to stop.
- **Never forbid a host's only tool.** "Do not use Bash" is fatal in Codex. Forbid the
  *outcome* instead: "read-only: never edit, create or delete a file", "do not use the web".
- **Express budgets as numbers with a shell equivalent.** Not "`head_limit: 20`" alone but "at
  most 20 matches per search (`head_limit: 20`, or `rg ... | head -20`)". Not "`limit: 80` +
  `offset`" alone but "never read more than ~80 lines at a time (`limit: 80` + `offset`, or
  `sed -n`)".
- **Frontmatter `!`command`` substitution is Claude-only.** Codex ships the literal text, so
  every such line needs the "if it still shows the literal command, run exactly that" fallback
  that `dry/check.md` carries.
- Windows paths and `.bat` wrappers are fine - both hosts run on this machine.

The three commands invoked **as** the Codex delegate by `CODING_RULES.md` -
`convention/check.md`, `plan/dry.md`, `dry/check.md` - are the ones where this matters most.

`tools/sync_commands_to_codex.bat` prints a `WARNING:` line per Claude-only phrase it finds in
a body. Treat a warning as a bug in the command, not noise.

## feedback

Cross-repo feedback loop between a backend repo and a frontend repo. The commands are
**global** (they live here, nothing is copied into projects), so an edit in `feedback/` is
live in every project on the next session. Role-agnostic — same names in both repos:

- `/feedback:implement [name]` — process `feedback/*.md`, verify with the workflow the
  project's CLAUDE.md describes, move to `feedback/done/`. If the repo is the backend, write a
  follow-up feedback file into the frontend's `feedback/`.
- `/feedback:write` — write a `yyyy_mm_dd_TITLE.md` request into the counterpart's
  `feedback/`. During planning it is the first plan entry.
- `/feedback:setup` — record the counterpart path in both repos and migrate old per-project
  copies (deletes the old `.claude/commands/feedback/*` files, rewrites old command names in
  CLAUDE.md).

Project-specific facts are read at runtime, never baked in: the counterpart path from
`.claude/related-projects.md` or CLAUDE.md `## Related Projects` (the entry label
`Frontend`/`App` vs `Backend`/`API` tells the repo's role), verify commands and conventions
from CLAUDE.md / CODING_RULES.md. This replaced the earlier
`frontend-backend-communication` template-copy + `fbc-version` sync design. Reference
pairs: turbo-habits-api ↔ turbo-habits-app, erp-api ↔ erp-frontend.

## Multi-step plans

Plan mode produces one large plan. For big features, split it into ordered phase files that a
fresh session implements one at a time, each phase green + committable. Format originated from
the hand-made `android/tickets-app/plans-implementation/`.

```
plan/YYYYMMDD_<feature-name>/
  00-context.md        shared reference (decisions, facts, phase index) — never implemented
  01-<kebab>.md …      phases, ordered by dependency, each with a ## Verify section
  original.md          the source plan if it was a top-level plan/<x>.md (moved by split)
plan/done/YYYYMMDD_<feature-name>/   finished phases
```

- `/plan:multi-step <feature>` — research like `/plan:feature`, write the phase folder directly.
- `/plan:split [path]` — turn an existing plan file (or the current session plan) into a phase folder.
- `/plan:implement-phase [feature] [NN|all]` — implement the next (or given, or all) phase,
  validate, move it to `plan/done/<folder-name>/` (same dated name). When no phase remains the
  leftovers move there too and the source folder is deleted. The feature argument is a partial
  match on the folder name, so the date prefix does not have to be typed.

`/plan:implement` handles single top-level `plan/*.md` files only; folders are for
`/plan:implement-phase`.

## Future

Document other commands here as they are added.
