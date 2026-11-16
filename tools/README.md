# tools

Helper scripts for maintaining this repo.

## sync_commands_to_codex

Syncs the installed command categories into Codex skills. Claude reads each selected
category through a link in `~/.claude/commands`; Codex loads **skills** from
`~/.codex/skills/<name>/SKILL.md`. Both use the saved selection from
`tools/installed_categories.json` when it exists. Without a selection file, all categories
are synced, preserving the previous behavior.

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
- Categories that were deselected are removed from Codex during this cleanup. Run the
  installer below to change the saved category selection.

Self-test:

```
python tools/sync_commands_to_codex.py --self-test
```

## install_commands

Choose which command categories to install into Claude Code. The installer shows each
category's description from `commands/categories.json`, remembers your choices in the
per-machine `tools/installed_categories.json`, and links selected categories into
`~/.claude/commands`. Run it once per machine, then again whenever you want to change
the selection or install a newly added category:

```
tools\install_commands.bat
```

- On the first run, every category defaults to yes. Later runs use the saved choice as
  each prompt's default; press Enter to keep it.
- Re-running updates category links and removes deselected category links. It does not
  remove real folders or files you added under `~/.claude/commands`.
- The installer can start the Codex sync after saving your choices. You can also run the
  sync separately with `tools\sync_commands_to_codex.bat`.
- Restart Claude Code afterwards to pick up the commands.
- Check the installer with `python tools/install_commands.py --self-test`.

## agent-browser-fix

Patch for the `agent-browser` CLI; it covers the Node wrapper and the `.cmd`/`.ps1` launchers. See `agent-browser-fix/patch.bat`.
