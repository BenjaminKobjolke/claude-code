---
description: Add or update common and language specific rules to CLAUDE.md
---

Read the coding rules bundled with this plugin from `${CLAUDE_PLUGIN_ROOT}/resources/coding-rules/`.

Read the common rules file (COMMON_RULES.md) and the file specific to the language or languages of the current project. Then update CLAUDE.md with the rules of those files.

Available rule files:
- `${CLAUDE_PLUGIN_ROOT}/resources/coding-rules/COMMON_RULES.md` — applies to all projects
- `${CLAUDE_PLUGIN_ROOT}/resources/coding-rules/FLUTTER_RULES.md` — Flutter/Dart projects
- `${CLAUDE_PLUGIN_ROOT}/resources/coding-rules/CSHARP_RULES.md` — C#/.NET projects
- `${CLAUDE_PLUGIN_ROOT}/resources/coding-rules/PHP_RULES.md` — PHP projects
- `${CLAUDE_PLUGIN_ROOT}/resources/coding-rules/PYTHON_RULES.md` — Python projects
- `${CLAUDE_PLUGIN_ROOT}/resources/coding-rules/flutter/IN_APP_DEBUGGER.md` — Flutter in-app debugger rules

For the language specific rules it might be that some rules do not apply to the current project. For example twig templates for a project that is just an api might not be accurate. If you are unsure ask the user if you should add all rules or only the rules that apply to the current project.
