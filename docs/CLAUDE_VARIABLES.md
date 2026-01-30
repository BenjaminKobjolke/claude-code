# Claude Code Variables

Variables and syntax available in Claude Code custom commands (`.claude/commands/` or `.claude/skills/`).

## Environment Variables

| Variable | Description |
|----------|-------------|
| `$CLAUDE_PROJECT_DIR` | Absolute path to the current project root directory |
| `$ARGUMENTS` | All arguments passed when invoking the command |
| `$1`, `$2`, `$3`, ... | Specific argument by position (1-based index) |
| `${CLAUDE_SESSION_ID}` | Current session ID (useful for session-specific files) |

## Usage Examples

### Reference Project Files

```markdown
Check the project rules in $CLAUDE_PROJECT_DIR/CLAUDE.md
Save output to $CLAUDE_PROJECT_DIR/docs/output.md
```

### Use Command Arguments

```markdown
---
name: search
description: Search for a term in the codebase
---

Search the codebase for: $ARGUMENTS
```

### Session-Specific Files

```markdown
Log this to $CLAUDE_PROJECT_DIR/logs/${CLAUDE_SESSION_ID}.log
```

## Shell Command Substitution

Use the `!`command`` syntax to include file contents (preprocessing):

```markdown
# Include content from another file
!`cat ~/.claude/commands/shared-rules.md`

# Include project file content
!`cat $CLAUDE_PROJECT_DIR/CLAUDE.md`

# Run any shell command
!`git -C $CLAUDE_PROJECT_DIR status`
```

The command output replaces the placeholder before Claude sees it.

## Referencing Other Command Files

Use relative markdown links to reference files in the same commands directory:

```markdown
See [other-command.md](other-command.md) for more details.
See [subfolder/command.md](subfolder/command.md) for nested files.
```
