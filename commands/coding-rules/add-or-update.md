---
description: Add or update common and language specific rules to CLAUDE.md
---

Check CLAUDE.md if it contains the path to the coding rules
If not ask the user for the path then store it in CLAUDE.md
Check the MD files in that folder. Always read the common rules file (`COMMON_RULES.md`) and the AI workflow rules file (`AI_RULES.md`) regardless of language, plus the file specific to the language or languages of the current project. Then update CLAUDE.md with the rules of those files.

`AI_RULES.md` is language-independent and always applies — it is NOT subject to the "some rules may not apply to this project" filtering described below. Always include it in full.

For the language specific rules it might be that some rules do not apply to the current project. For example twig templates for a project that is just an api might not be accurate. If you are unsure ask the user if you should add all rules or only the rules that apply to the current project.

