# Setup Blender MCP with Claude Code

## Prerequisites

- [uv](https://docs.astral.sh/uv/) installed (`winget install astral-sh.uv`)
- [Blender](https://www.blender.org/) installed
- Claude Code CLI installed

## 1. Install the Blender MCP Addon

1. Open Blender
2. Go to **Edit > Preferences > Add-ons**
3. Search for "Blender MCP" or install it from the [blender-mcp repository](https://github.com/ahujasid/blender-mcp)
4. Enable the addon
5. In the sidebar (press `N`), find the **BlenderMCP** panel and click **Start MCP Server**
   - This starts a socket server on `localhost:9876`

## 2. Add Blender MCP to Claude Code

Run this command in your terminal:

```bash
claude mcp add --transport stdio --scope user blender-mcp -- uvx blender-mcp
```

On Windows, if Claude Code cannot find `uvx`, use the full path:

```bash
claude mcp add --transport stdio --scope user blender-mcp -- C:\Users\<USERNAME>\.local\bin\uvx.exe blender-mcp
```

Replace `<USERNAME>` with your Windows username.

### Scope Options

| Flag | Effect |
|------|--------|
| `--scope user` | Available in all projects (stored in `~/.claude.json`) |
| `--scope local` | Current project only |

## 3. Verify the Setup

```bash
claude mcp list
```

Expected output:

```
blender-mcp: uvx blender-mcp - ✓ Connected
```

If it shows `✗ Failed to connect`, make sure Blender is running with the MCP server started (step 1).

## 4. Setup for Claude Desktop

Edit `%APPDATA%\Claude\claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "blender": {
      "command": "C:\\Users\\<USERNAME>\\.local\\bin\\uvx.exe",
      "args": ["blender-mcp"]
    }
  }
}
```

Use the full path to `uvx.exe` because Claude Desktop does not inherit the user PATH.

Restart Claude Desktop after saving.

## Usage

1. Start Blender and activate the MCP server in the sidebar panel
2. Start a new Claude Code session
3. Claude Code can now interact with Blender (create objects, modify scenes, run scripts, etc.)

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `Failed to connect` | Ensure Blender is running with MCP server started on `localhost:9876` |
| `uvx not found` | Use the full absolute path to `uvx.exe` in the command |
| Tools not showing up | Start a **new** Claude Code session after adding the MCP server |
| Claude Desktop can't find MCP | Use full path to `uvx.exe` in the config, then fully restart Claude Desktop |
