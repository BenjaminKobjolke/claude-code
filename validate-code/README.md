# Code Validation Hook for Claude Code

A post-tool hook that validates code files after Claude Code writes them, reporting LSP errors for Claude to fix.

## Supported tools

- https://github.com/BenjaminKobjolke/intelephense-lsp-mcp
- https://github.com/BenjaminKobjolke/dart-lsp-mcp

## Features

- Validates PHP files using Intelephense LSP
- Validates Dart files using Dart LSP
- Daily rotating logs with 5-day retention
- Configurable validator paths and file exclusions

## Requirements

- **PHP** must be installed and available in your system PATH
- **Composer** must be installed ([getcomposer.org](https://getcomposer.org/))

## Installation

1. Copy this folder to your project as `hooks`, or use the symlink script (Windows, run as Administrator):

```bash
symlink.bat
```

This will prompt for your project path and create a symlink at `<your-project>/hooks`.

2. Install dependencies:

```bash
cd /path/to/your/project/hooks
composer install
```

3. Create your config file:

```bash
cp config_example.php config.php
```

4. Edit `config.php` and adjust the validator paths for your system.

5. Add the hook to your project's `.claude/settings.local.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "php $CLAUDE_PROJECT_DIR/hooks/validate-code.php"
          }
        ]
      }
    ]
  }
}
```

## Configuration

Edit `config.php` to configure validators:

```php
return [
    'validators' => [
        'php' => [
            'check_bat' => 'D:\\path\\to\\intelephense-mcp\\check.bat',
            'extensions' => ['.php'],
            'exclude_paths' => ['hooks', 'vendor'],
        ],
        'dart' => [
            'check_bat' => 'D:\\path\\to\\dart-lsp-mcp\\check.bat',
            'extensions' => ['.dart'],
            'exclude_paths' => [],
        ],
    ],
];
```

### Validator Config Options

| Option | Description |
|--------|-------------|
| `check_bat` | Path to the validator's check script |
| `extensions` | File extensions this validator handles |
| `exclude_paths` | Directory names to skip validation for |

## Logs

Logs are written to `<your_project>/hooks/logs/` with daily rotation:
- Location: `hooks/logs/YYYY-MM-DD.log`
- Retention: 5 days (older logs are automatically deleted)
- Created automatically on first run

## Testing

The hook reads from stdin and will hang if run directly. To test manually, pipe JSON input:

**Windows (PowerShell):**
```powershell
'{"hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":"C:/projects/myapp/src/Example.php"}}' | php hooks/validate-code.php
```

**Linux/macOS:**
```bash
echo '{"hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":"/home/user/projects/myapp/src/Example.php"}}' | php hooks/validate-code.php
```

## Adding New Validators

To add support for a new language:

1. Create a check script that accepts `<file_path> <project_dir>` arguments
2. Output diagnostics in a format containing `Error [` or `Warning [` markers
3. Add the validator config to `config.php`
