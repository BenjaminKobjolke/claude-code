# Coding rules moved

The coding rules now live in their own repo, packaged as an installable Claude Code plugin:

https://github.com/BenjaminKobjolke/claude-coding-rules
(local clone: `D:\GIT\BenjaminKobjolke\claude-coding-rules`)

Install:

```
/plugin marketplace add BenjaminKobjolke/claude-coding-rules
/plugin install coding-rules@claude-coding-rules
```

Skills: `/coding-rules:apply` (rules into CLAUDE.md), `/coding-rules:enforce` (audit codebase).
These replace the old `commands/coding-rules/` commands.
