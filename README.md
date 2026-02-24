# xida

A native [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin providing Git workflows, code analysis, testing, debugging, handoffs, and multi-language coding standards.

## Installation

### From marketplace (recommended)

**Add the marketplace:**

- `/plugin marketplace add BenjaminKobjolke/claude-code#feature/native-plugin`
- Or: `/plugin` > **Marketplaces** > **+ Add Marketplace** > enter `BenjaminKobjolke/claude-code#feature/native-plugin`

**Enable auto-update:**

- `/plugin` > **Marketplaces** > **xida** > **Enable auto-update**

> Auto-updates run at startup in the background. After an update, open a **new terminal window** for the new version to take effect.

**Install the plugin:**

- `/plugin install xida@xida`
- Or: `/plugin` > **Marketplaces** > **xida** > **Browse plugins** > **xida** > **Install for you (user scope)**

To verify or force an update: `/plugin` > **Installed** > **xida** > **Update now**

### From a local clone

Clone the repo and point Claude Code at it:

```bash
git clone https://github.com/BenjaminKobjolke/claude-code.git
claude --plugin-dir .
```

Or if you keep the plugin repo at a fixed location:

```bash
claude --plugin-dir /path/to/claude-code
```

You can load multiple plugins by repeating the flag:

```bash
claude --plugin-dir /path/to/claude-code --plugin-dir /path/to/another-plugin
```

> **Note:** Restart Claude Code to pick up changes after editing plugin files.

> **Caveat — subdirectory commands (Windows):** Placing command files into subdirectories (e.g. `commands/git/commit.md`) causes Claude Code to register them as `/xida:\git:commit` with a stray backslash before the subdirectory name. This is a Windows-specific bug. Related issues: [#2422](https://github.com/anthropics/claude-code/issues/2422), [#18527](https://github.com/anthropics/claude-code/issues/18527), [#20015](https://github.com/anthropics/claude-code/issues/20015). Until this is fixed upstream, all commands remain as flat files in `commands/` using the `category-name.md` naming convention.

## Commands

All commands are invoked with the `/xida:` prefix.

### Git

| Command            | Description                                                        |
| ------------------ | ------------------------------------------------------------------ |
| `/xida:git-commit` | Commit and push changes following XIDA commit standards            |
| `/xida:git-url`    | Generate plain URLs to view commits on the remote hosting platform |

### Code Analysis

| Command                         | Description                                      |
| ------------------------------- | ------------------------------------------------ |
| `/xida:analyze-setup`           | Set up code analysis scripts for the project     |
| `/xida:analyze-run-and-fix`     | Run code analysis, then fix the issues           |
| `/xida:analyze-fix-only`        | Fix analysis issues without re-running analyzers |
| `/xida:analyze-check-analyzers` | Check if all available analyzers are configured  |

### Testing

| Command                     | Description                                     |
| --------------------------- | ----------------------------------------------- |
| `/xida:testing-setup`       | Set up test scripts for the project             |
| `/xida:testing-run`         | Run tests and fix errors                        |
| `/xida:validate-pre-commit` | Run all configured validators before committing |

### Planning & Implementation

| Command                | Description                                                              |
| ---------------------- | ------------------------------------------------------------------------ |
| `/xida:plan-feature`   | Plan a new feature and store the plan in the project's `plan/` directory |
| `/xida:plan-implement` | Pick up and implement a plan from the `plan/` directory                  |
| `/xida:refactor-plan`  | Create a phased refactoring plan in `PLAN.md`                            |

### Handoffs

| Command                            | Description                                                    |
| ---------------------------------- | -------------------------------------------------------------- |
| `/xida:handoff-create`             | Write `HANDOFF.md` when running out of context                 |
| `/xida:handoff-create-low-context` | Write `HANDOFF.md` with minimal context usage                  |
| `/xida:handoff-continue`           | Continue working from a previously created `HANDOFF.md`        |
| `/xida:handoff-plan`               | Create a handoff for a planned but not yet implemented feature |

### GitHub Releases

| Command                       | Description                                      |
| ----------------------------- | ------------------------------------------------ |
| `/xida:github-setup`          | Set up the GitHub release workflow for a project |
| `/xida:github-create-release` | Create a new GitHub release                      |

### Releases (App Store / Build)

| Command                              | Description                                   |
| ------------------------------------ | --------------------------------------------- |
| `/xida:release-setup`                | Set up the release system for the application |
| `/xida:release-create-release`       | Create a new release build                    |
| `/xida:release-create-release-notes` | Generate release notes from recent changes    |

### Debugging

| Command                    | Description                                 |
| -------------------------- | ------------------------------------------- |
| `/xida:debug-setup`        | Set up the process to build a debug version |
| `/xida:debug-create-debug` | Create a new debug version                  |

### Coding Rules

| Command                            | Description                                                            |
| ---------------------------------- | ---------------------------------------------------------------------- |
| `/xida:coding-rules-add-or-update` | Add or update common and language-specific coding rules in `CLAUDE.md` |

### Flutter

| Command                                  | Description                                                |
| ---------------------------------------- | ---------------------------------------------------------- |
| `/xida:flutter-update-packages`          | Update Flutter packages via FVM, one by one                |
| `/xida:flutter-check-local-dependencies` | Check if local path dependencies have outdated constraints |

### Documentation & Insights

| Command                         | Description                                                    |
| ------------------------------- | -------------------------------------------------------------- |
| `/xida:docs-generate`           | Generate project documentation in markdown                     |
| `/xida:insights-analyze-report` | Analyze a usage report and generate a command improvement plan |
| `/xida:bugs-collect`            | Collect bugs in `BUGS.md`                                      |
| `/xida:issue-next-one`          | Pick up the next open issue                                    |

### Migration

| Command                      | Description                                          |
| ---------------------------- | ---------------------------------------------------- |
| `/xida:migrate-dependencies` | Plan and execute dependency migrations incrementally |

### Browser Automation

| Command               | Description                              |
| --------------------- | ---------------------------------------- |
| `/xida:tools-browser` | Browser automation via agent-browser CLI |

### Notification

| Command              | Description                                                            |
| -------------------- | ---------------------------------------------------------------------- |
| `/xida:notification` | Configure notification sounds and taskbar flash for Claude Code events |

## Bundled Resources

The plugin bundles coding rules and project scaffolding files that commands reference via `${CLAUDE_PLUGIN_ROOT}`.

### Coding Rules (`resources/coding-rules/`)

Language-specific coding standards applied by `/xida:coding-rules-add-or-update`:

- `COMMON_RULES.md` -- applies to all projects
- `FLUTTER_RULES.md` -- Flutter/Dart with FVM
- `CSHARP_RULES.md` -- .NET Framework / Windows Forms
- `PHP_RULES.md` -- PHP 8.4
- `PYTHON_RULES.md` -- Python with uv
- `flutter/IN_APP_DEBUGGER.md` -- Flutter in-app debugger setup (Logarte)

### Setup Files (`resources/setup-files/`)

Project scaffolding scripts (install, update, build, test batch files) for:

- `csharp/` -- icon assets and conversion scripts
- `flutter/` -- install, update, build, and test scripts
- `python/` -- install, update, and test scripts

### Existing Projects (`resources/existing-projects/`)

- `flutter/update_flutter_libraries.md` -- guide for incrementally updating Flutter packages

## Repository Structure

```
.
├── .claude-plugin/          # Plugin manifest & marketplace
│   ├── plugin.json
│   └── marketplace.json
├── commands/                # 33 slash commands (see table above)
├── hooks/                  # Plugin hooks (notification events)
│   └── hooks.json
├── notification/           # Cross-platform notification system
│   ├── notification.sh
│   ├── notification.conf   # Generated by setup (gitignored)
│   └── setup.sh
├── resources/
│   ├── coding-rules/        # Language coding standards
│   ├── setup-files/          # Project scaffolding scripts
│   └── existing-projects/    # Maintenance guides
├── scripts/
│   └── agent-browser-fix/   # Windows patch for agent-browser CLI
├── docs/                    # Reference docs (not part of the plugin)
├── plugins/lsps/            # Separate PHP LSP mini-plugins
│   ├── intelephense/
│   └── phpactor/
└── LICENSE
```

### Directories not part of the plugin

- **`docs/`** -- Claude Code variable reference, Blender MCP setup guide, and historical design documents
- **`plugins/lsps/`** -- Standalone mini-plugins for PHP language servers (Intelephense and PHPActor). These have machine-specific paths and are loaded separately with `--plugin-dir`

## License

MIT -- see [LICENSE](LICENSE).
