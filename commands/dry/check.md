---
description: Post-implementation DRY audit — check changed files for duplication and consolidation opportunities
---

Audit recent code changes for DRY violations and consolidation opportunities. Run this after implementing a feature or fix.

Steps:

1. **Identify changed files**: Run `git diff --name-only` (staged and unstaged) to see what was modified. If no changes found, ask the user which files to check.

2. **Scan for duplication across changed files**:
   - Are similar code blocks repeated across multiple files?
   - Were multiple templates/files modified with the same pattern?
   - Could a single shared component, CSS rule, or utility replace per-file changes?

3. **Compare against existing shared resources**:
   - Check for existing reusable components, Twig partials, SCSS mixins
   - Check for existing utility functions or helper methods
   - Check for existing CSS classes that could replace inline or per-file styles

4. **Check for over-engineering**:
   - Are there new abstractions that only have one consumer? (premature abstraction)
   - Could the change be simpler?

5. **Report findings**:

   ## DRY Audit Results

   ### Duplication Found
   - List each instance with file paths and line numbers
   - Suggest how to consolidate (shared component, utility, CSS rule, etc.)

   ### Consolidation Opportunities
   - Per-file changes that could be a single shared solution
   - Code that duplicates existing utilities

   ### No Issues Found
   - If the code is already DRY, confirm it

6. If issues are found, ask the user if they want to fix them now.

This command audits and reports. It does NOT auto-fix unless the user asks.

Related commands:
- /plan:dry — check a plan for DRY (before implementation)
- /convention:check — pre-implementation convention scanner
- /simplify — review changed code for reuse and quality
