---
description: Rewrite an explicit plan file for DRY, KISS, and YAGNI
argument-hint: <plan-path>
context: fork
agent: general-purpose
model: haiku
effort: low
---

Review and rewrite exactly one plan file: $ARGUMENTS

1. Require one explicit path, quoted when it contains spaces. Reject missing paths, multiple paths, directories, wildcard characters, and files without a `.md` extension. Resolve relative paths from the current working directory. Absolute paths, including paths outside the repository, are allowed subject to normal filesystem permissions.
2. Read the complete plan. Do not inspect the repository, follow references, or read any other file.
3. Identify concrete duplication, consolidation opportunities, premature abstractions, and unnecessary complexity. Preserve the plan's goal, decisions, constraints, compatibility requirements, test coverage, and resolved or unresolved questions.
4. If improvements are warranted, make one coherent in-place rewrite of that file. Consolidate repeated steps and shared work, but do not invent requirements or implement any part of the plan. Never modify another file. If the plan is already clean, leave it unchanged.
5. Run `/ponytail:ponytail` inside this same fork against the rewritten plan. Apply warranted YAGNI/KISS improvements to the same file only. If Ponytail is unavailable, do not install it; report that the YAGNI gate is incomplete.
6. Re-read the final plan and confirm its intent and required verification were preserved.

Return a chat summary of at most 200 words with the resolved path, the consolidations applied, the Ponytail result, and whether the DRY gate is complete. This cap applies only to the chat response; never truncate or summarize the plan file to satisfy it.
