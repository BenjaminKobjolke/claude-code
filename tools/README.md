# tools

Helper scripts for maintaining this repo.

## sync_commands_to_codex

Syncs `commands/` into Codex skills. Claude reads `commands/` directly (symlinked
into `~/.claude/commands`), but Codex loads **skills** from `~/.codex/skills/<name>/SKILL.md`.
This generator makes the Codex copies.

Run after adding, editing, or removing any command:

```
tools\sync_commands_to_codex.bat
```

or directly:

```
python tools/sync_commands_to_codex.py
```

What it does:

- `commands/<cat>/<name>.md` → `~/.codex/skills/<cat>-<name>/SKILL.md`
  (e.g. `git/commit.md` → `git-commit`). `CLAUDE.md` files are skipped.
- Rewrites frontmatter to `name` + `description`; drops Claude-only keys
  (`effort`, `allowed-tools`, `argument-hint`, `model`). Body copied verbatim.
- Copies non-`.md` resource files in a category (e.g. `build-and-upload/setup-files/`)
  into the generated skill folder so relative links keep working.
- One-way: `commands/` is the source of truth.
- Auto-removes stale skills: every generated folder carries a `.synced-from-claude`
  marker; each run deletes all marked folders first, then regenerates. Codex's own
  `.system/` skills and symlinked skills (no marker) are never touched.

Self-test:

```
python tools/sync_commands_to_codex.py --self-test
```

## agent-browser-fix

Patch for the `agent-browser` CLI. See `agent-browser-fix/patch.bat`.
