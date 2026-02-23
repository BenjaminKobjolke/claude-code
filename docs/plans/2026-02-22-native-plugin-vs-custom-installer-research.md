# Native Plugin vs Custom Installer — Research Findings

**Date:** 2026-02-22
**Branch:** `feature/universal-setting-installer`
**Status:** Research — pending decision

## Question

Should we use Claude Code's native plugin system instead of our custom universal installer for settings plugins like `status-line`?

## Native Plugin Capabilities

Based on official documentation at:
- https://code.claude.com/docs/en/plugins
- https://code.claude.com/docs/en/plugins-reference
- https://code.claude.com/docs/en/hooks
- https://code.claude.com/docs/en/statusline

### What native plugins CAN do

| Capability | How |
|---|---|
| Hooks | `hooks/hooks.json` — auto-merged when plugin is enabled |
| Skills/Commands | `skills/` and `commands/` directories |
| MCP servers | `.mcp.json` at plugin root |
| LSP servers | `.lsp.json` at plugin root |
| Agents | `agents/` directory |
| Settings (`agent` key only) | `settings.json` at plugin root |
| Installation | `claude plugin install` or `/plugin install` |
| Uninstallation | `claude plugin uninstall` — removes hooks, skills, agents, MCP, LSP |
| Versioning | Semantic versioning in `plugin.json` |
| Distribution | Plugin marketplaces |

### What native plugins CANNOT do

| Limitation | Details |
|---|---|
| `statusLine` in settings.json | Plugin `settings.json` only supports the `agent` key. Unknown keys silently ignored. |
| Arbitrary settings.json keys | Only `agent` is supported. No `permissions`, `statusLine`, `hooks`, etc. |
| Run code on uninstall | No `PluginUninstall` event exists in the hook lifecycle. |
| Modify `~/.claude/settings.json` directly | Plugins have their own scoped settings, not direct access to user settings. |

### Plugin settings.json — exact docs quote

> Plugins can include a `settings.json` file at the plugin root to apply default configuration when the plugin is enabled. **Currently, only the `agent` key is supported.**

## Workaround: SessionStart Hook for Auto-Merge

A native plugin could ship a `SessionStart` hook that checks and merges `statusLine` into `~/.claude/settings.json` on every session start.

### Plugin structure

```
status-line-plugin/
  .claude-plugin/
    plugin.json
  hooks/
    hooks.json              # SessionStart hook
  scripts/
    ensure-statusline.ps1   # Windows: check & merge statusLine
    ensure-statusline.sh    # macOS: check & merge statusLine
    status-line.ps1         # Runtime status line script
    status-line.sh
  skills/
    setup/
      SKILL.md              # /status-line:setup customization wizard
    uninstall/
      SKILL.md              # /status-line:uninstall manual cleanup
```

### hooks.json

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/ensure-statusline.ps1"
      }]
    }]
  }
}
```

### Pros

- Native install/update UX (`claude plugin install`)
- Automatic hook registration (no manual settings.json merge)
- `${CLAUDE_PLUGIN_ROOT}` provides reliable script paths
- Plugin versioning and marketplace distribution
- Auto-updates via plugin system

### Cons

- SessionStart hook adds latency on every session start (small — just a JSON file read)
- **No uninstall hook** — merged `statusLine` key survives plugin removal
- Users must manually run `/status-line:uninstall` skill before removing the plugin
- The auto-merge logic still needs custom code in the hook script
- `once: true` is per-session, not "once ever" — check runs every session

## Uninstall Gap — Detailed Analysis

The native plugin system has **17 hook events** but none fires on plugin installation or removal:

- `SessionStart` — fires but if plugin is removed, the hook no longer exists and can't run
- `ConfigChange` — fires when settings change but the plugin's hooks are already gone when it's uninstalled
- No `PluginInstall`, `PluginUninstall`, `PluginEnable`, `PluginDisable` events

**Result:** There is no way to automatically clean up `settings.json` keys when a native plugin is uninstalled.

### Possible mitigations

1. **Manual skill:** Ship `/status-line:uninstall` — user runs before removing plugin
2. **Documentation:** Tell users to manually remove the `statusLine` key
3. **External cleanup:** Our custom `/setting:uninstall` command can handle it independently

## Comparison Matrix

| Feature | Custom Installer | Native Plugin | Native + SessionStart |
|---|---|---|---|
| Install statusLine | Yes (deep merge) | No | Yes (auto-merge via hook) |
| Install hooks | Yes (deep merge) | Yes (native) | Yes (native) |
| Install scripts | Yes (download) | Yes (bundled) | Yes (bundled) |
| Clean uninstall | Yes (deep un-merge) | Partial (no statusLine cleanup) | Partial (need manual skill) |
| Update | Yes (full reinstall) | Yes (native) | Yes (native) |
| Discovery | Yes (GitHub API) | Yes (marketplace) | Yes (marketplace) |
| Distribution | GitHub repo | Plugin marketplace | Plugin marketplace |
| User interaction | New terminal window | Native CLI/TUI | Native CLI/TUI |
| Versioning | Manual | Semantic (built-in) | Semantic (built-in) |
| Auto-updates | No | Yes | Yes |

## Options

### Option A: Keep Custom Installer

Continue with the universal installer design. Handles everything: install, update, uninstall with proper settings.json deep merge and un-merge. Single system, no gaps.

**Best for:** Full control, clean uninstall, arbitrary settings.json keys.

### Option B: Native Plugin Only

Convert to native plugin. Use SessionStart hook for statusLine auto-merge. Ship uninstall skill for manual cleanup.

**Best for:** Native UX, marketplace distribution, automatic updates. Acceptable if manual uninstall step is OK.

### Option C: Hybrid (Native Plugin + Custom Uninstaller)

Use native plugin for install (with SessionStart auto-merge), keep custom `/setting:uninstall` for clean settings.json removal.

**Best for:** Best of both worlds, but two systems to maintain.

### Option D: Wait

The native plugin `settings.json` may expand to support more keys (statusLine, permissions, hooks) in the future. Pause and revisit.

**Risk:** May never happen. No roadmap visibility.

## Decision

**Pending.** Researching which approach to pursue.
