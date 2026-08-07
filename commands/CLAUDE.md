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

## frontend-backend-communication

`/frontend-backend-communication:setup` — installs a cross-repo feedback loop between a
backend (API) repo and a frontend/app repo: feedback commands in both repos'
`.claude/commands/` plus CLAUDE.md "Related Projects" links. Templates in
`frontend-backend-communication/setup_files/` (`.md.template` — not plain `.md`, so they
don't register as commands themselves). Reference implementations: turbo-habits-api ↔
turbo-habits-app, erp-api ↔ erp-frontend.

## Future

Document other commands here as they are added.
