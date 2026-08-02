---
description: Add or update common and language specific rules to CLAUDE.md
---

Check CLAUDE.md if it contains the path to the coding rules
If not ask the user for the path then store it in CLAUDE.md
Check the MD files in that folder. Always identify the common rules file (`COMMON_RULES.md`) and the AI workflow rules file (`AI_RULES.md`) regardless of language, plus the file specific to the language or languages of the current project.

Read the COMMON_RULES.md an AI_Rules.md files.
They might contain changes how to handle the rule files.

If CLAUDE.md already has rule text copy-pasted in from an earlier run, replace it with the import lines (dedup).

`AI_RULES.md` is language-independent and always applies — it is NOT subject to the "some rules may not apply to this project" filtering described below. Always import it.

For the language specific rules, import the whole applicable language file(s) rather than cherry-picking rule text — it might be that some rules do not apply to the current project (for example twig templates for a project that is just an API). If a rule does not apply, note that as a project override below the imports (see `COMMON_RULES.md` § Keep CLAUDE.md in Sync) instead of omitting it from the import. If you are unsure which rules apply, ask the user.

