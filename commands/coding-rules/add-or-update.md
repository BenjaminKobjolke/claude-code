---
description: Add or update common and language specific rules to CLAUDE.md
---

Check CLAUDE.md if it contains the path to the coding rules
If not ask the user for the path then store it in CLAUDE.md
Check the MD files in that folder. Always read the common rules file (`COMMON_RULES.md`) and the AI workflow rules file (`AI_RULES.md`) regardless of language. Also read the applicable language-specific, project-type, and supplemental rule files, plus optional addon rules to which the user has opted in. Then update CLAUDE.md with the rules from those files.

Read `COMMON_RULES.md` and `AI_RULES.md` first because they may contain updated instructions for handling the rule files.

Each rule source starts with a `# Version` block. Include that block when copying rules into CLAUDE.md. For every applicable source file, compare its version with the version in the corresponding copied rule block:

- If the copied block has no version or its version is lower than the source version, replace that copied block with the current applicable source content.
- If both versions are equal, leave the copied block unchanged.
- If the copied version is higher than the source version, do not overwrite it; ask the user how to reconcile the unexpected version.

Identify corresponding copied blocks by the rule document title that follows the version block. Keep all copied rule blocks deduplicated and preserve project-specific CLAUDE.md content outside them. If CLAUDE.md contains coding-rule `@import` lines from an earlier run, remove those imports and replace them with the corresponding current rule content and version block.

`AI_RULES.md` is language-independent and always applies — it is NOT subject to the "some rules may not apply to this project" filtering described below. Always include it in full.

For language-specific, project-type, and supplemental rules, include the rules that apply to the current project. Some rules might not apply (for example Twig template rules for a project that is only an API). Include optional addon rules only after the user opts in. If you are unsure which rules apply, ask the user whether to include all candidate rules or only the applicable ones.
