# How to Install python-lsp Claude Code Plugin

Use the Windows-compatible fork: https://github.com/BenjaminKobjolke/python-lsp

The original `zircote/python-lsp` does not work on Windows because it spawns `pyright-langserver` without the `.cmd` extension required by Node.js `child_process.spawn` on Windows.

## Quick Steps

### 1. Clone the repo as a marketplace
```bash
git clone https://github.com/BenjaminKobjolke/python-lsp.git "$HOME/.claude/plugins/marketplaces/zircote-python-lsp"
```

### 2. Create marketplace.json
The repo only has `plugin.json` but Claude Code needs a `marketplace.json`. Create `.claude-plugin/marketplace.json`:

```json
{
  "name": "zircote-python-lsp",
  "owner": { "name": "zircote" },
  "metadata": {
    "description": "Python development with Pyright LSP integration, automated hooks for type checking, linting, formatting, testing, and security scanning"
  },
  "plugins": [
    {
      "name": "python-lsp",
      "source": "./",
      "description": "Claude Code plugin for Python development with Pyright LSP",
      "author": { "name": "zircote", "email": "zircote@gmail.com" },
      "homepage": "https://github.com/BenjaminKobjolke/python-lsp",
      "repository": "https://github.com/BenjaminKobjolke/python-lsp",
      "license": "MIT",
      "keywords": ["python", "pyright", "lsp", "ruff", "black", "pytest", "mypy"]
    }
  ]
}
```

### 3. Register in known_marketplaces.json
Add this entry to `~/.claude/plugins/known_marketplaces.json`:

```json
"zircote-python-lsp": {
  "source": {
    "source": "github",
    "repo": "BenjaminKobjolke/python-lsp"
  },
  "installLocation": "C:\Users\XIDA\.claude\plugins\marketplaces\zircote-python-lsp",
  "lastUpdated": "<current ISO date>"
}
```

### 4. Install the plugin
```bash
claude plugin install python-lsp@zircote-python-lsp --scope local
```

### 5. Point installPath at local clone (CRITICAL)
The marketplace copy at `~/.claude/plugins/marketplaces/zircote-python-lsp/.lsp.json` does **not** have the `.cmd` fix — only the local clone does. To ensure the fix is used (and not overwritten by updates), edit `~/.claude/plugins/installed_plugins.json` and change the `installPath` for `python-lsp@zircote-python-lsp` to your local clone path:

```json
"installPath": "D:\GIT\BenjaminKobjolke\python-lsp"
```

### 6. Install Pyright globally via npm (CRITICAL)
The plugin expects `pyright-langserver` on the system PATH but does **not** install it.

```bash
npm install -g pyright
```

Verify it's available:
```bash
pyright-langserver --version
```

**Important:** Installing via `uv add --dev pyright` does NOT work — the LSP plugin cannot find `pyright-langserver` inside the project's `.venv/Scripts/`. The binary must be on the global system PATH, which only `npm install -g` provides.

### 7. Patch the built-in Pyright LSP plugin (CRITICAL)
Claude Code ships a built-in `claude-code-lsps/pyright` plugin that also registers the `"python"` language key. **It takes priority over the fork** and uses `"command": "pyright-langserver"` (without `.cmd`), causing the same `ENOENT` error even when the fork is correctly installed.

You must patch its `.lsp.json`:

**File:** `~/.claude/plugins/marketplaces/claude-code-lsps/pyright/.lsp.json`

Change:
```json
"command": "pyright-langserver"
```
To:
```json
"command": "pyright-langserver.cmd"
```

**Note:** This patch may need to be re-applied after `claude-code-lsps` marketplace updates, as the marketplace may overwrite the file.

### 7b. Patch the cached and marketplace fork copies (CRITICAL)
Claude Code reads `.lsp.json` from its **cache** directory, not from `installPath`. Even though `installPath` points to the local clone with the fix, the cache and marketplace copies still have the original `"pyright-langserver"` (without `.cmd`). You must patch both:

**File 1:** `~/.claude/plugins/cache/zircote-python-lsp/python-lsp/0.1.3/.lsp.json`
**File 2:** `~/.claude/plugins/marketplaces/zircote-python-lsp/.lsp.json`

Change in both:
```json
"command": "pyright-langserver"
```
To:
```json
"command": "pyright-langserver.cmd"
```

**Note:** These patches may need to be re-applied after plugin updates, as the cache/marketplace copies may be regenerated.

### 8. Create `pyrightconfig.json` per project
Each Python project needs a `pyrightconfig.json` so Pyright can find the virtual environment and resolve dependencies:

```json
{
  "pythonVersion": "3.11",
  "venvPath": ".",
  "venv": ".venv",
  "typeCheckingMode": "standard"
}
```

Adjust `pythonVersion` to match your project. Place this file in the project root.

### 9. Restart Claude Code
Restart Claude Code for the plugin and LSP server to take effect. If Pyright was not installed when Claude Code started, the LSP server will be in an error state and **will not recover** within the same session — you must restart.

### 10. Verify the LSP works
After restarting, test in a conversation:

```
Use the LSP tool: documentSymbol on main.py
```

If working, it returns a list of symbols (functions, classes, variables) from the file. If you see an `ENOENT pyright-langserver` error, Pyright is not on your PATH or the built-in plugin hasn't been patched (see step 7). If you see `server is error`, restart Claude Code.

## Windows `.cmd` Fix Details

On Windows, Node.js `child_process.spawn` cannot resolve executables without the `.cmd` extension. The original `zircote/python-lsp` uses `"command": "pyright-langserver"` in `.lsp.json`, which fails with `ENOENT uv_spawn 'pyright-langserver'`. The fork fixes this by using `"command": "pyright-langserver.cmd"` in its local clone, but this fix only takes effect when `installPath` points to the local clone (step 5).

Additionally, the built-in `claude-code-lsps/pyright` plugin registers the same `"python"` language key and takes priority. It must also be patched (step 7).

## Troubleshooting

### `ENOENT: no such file or directory, uv_spawn 'pyright-langserver'`
Four possible causes:
1. Pyright is not installed globally via npm (step 6)
2. The built-in `claude-code-lsps/pyright` plugin hasn't been patched with `.cmd` (step 7)
3. The cached/marketplace fork copies haven't been patched with `.cmd` (step 7b)
4. The `installPath` doesn't point to the local clone with the fix (step 5)

### `server is error` after installing Pyright or after restart
Two possible causes:
1. The LSP server cached its failed state from a previous session. Restart Claude Code.
2. The cached `.lsp.json` at `~/.claude/plugins/cache/zircote-python-lsp/python-lsp/0.1.3/.lsp.json` still has `"pyright-langserver"` without `.cmd`. Claude Code reads from cache, not from `installPath`. Patch it (step 7b) and restart.

### Pyright can't resolve project imports
Ensure `pyrightconfig.json` exists in the project root with correct `venvPath` and `venv` values pointing to your `.venv` directory.

## Why manual steps are needed
The `claude plugin marketplace add` and `claude plugin install` CLI commands use an interactive TUI that doesn't work in non-interactive shell. The repo also ships without a `marketplace.json`, only a `plugin.json`.
