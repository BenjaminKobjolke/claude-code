# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

This is a native Claude Code plugin named **xida**. The repo root IS the plugin -- Claude Code loads it via `claude --plugin-dir .`. There is no build step, no dependencies, and no tests to run.

## Plugin Architecture

The plugin system works as follows:

- `.claude-plugin/plugin.json` -- manifest that declares the plugin name (`xida`), version, and metadata. Claude Code reads this to register the plugin.
- `commands/*.md` -- each markdown file becomes a slash command available as `/xida:<filename-without-extension>`. The filename uses `category-name` format (e.g., `git-commit.md` becomes `/xida:git-commit`).
- `resources/` -- static files (coding rules, setup scripts, project guides) that commands reference at runtime via `${CLAUDE_PLUGIN_ROOT}/resources/...`. These are NOT loaded automatically -- commands must explicitly read them.
- `scripts/` -- supporting scripts (currently just the agent-browser Windows patch) referenced by commands via `${CLAUDE_PLUGIN_ROOT}/scripts/...`.

## Key Conventions

### Command cross-references

When one command references another, it uses the full plugin-namespaced format: `/xida:command-name`. Never use the bare `command-name` or old `category:name` format.

### Plugin root variable

Commands that need to read bundled files use `${CLAUDE_PLUGIN_ROOT}` to resolve paths relative to the plugin root. Example: `${CLAUDE_PLUGIN_ROOT}/resources/coding-rules/COMMON_RULES.md`.

### Adding a new command

Create a new `.md` file in `commands/` with a YAML frontmatter `description` field:

```markdown
---
description: Short description shown in command list
---

Command instructions here. Reference other commands as /xida:other-command.
```

The filename determines the slash command name. Use `category-name.md` format to keep commands organized.

### Commit message format

This repo follows the XIDA commit standard (defined in `commands/git-commit.md`):

```
TYPE (scope): subject

body

footer
```

Types: FEATURE, FIX, DOCS, STYLE, TEST, CLEANUP, IMPROVE, TOOLS, GIT, RELEASE, CONTENT, REFACTOR, PERF, CI, CHORE, AI, EXAMPLE.

## Directories Not Part of the Plugin

- `docs/` -- reference documentation and historical design plans. Not loaded by Claude Code.
- `plugins/lsps/` -- separate standalone mini-plugins for PHP language servers (Intelephense, PHPActor). These have machine-specific paths and are loaded independently with their own `--plugin-dir` flag.
