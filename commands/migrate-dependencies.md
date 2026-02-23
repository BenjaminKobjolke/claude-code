---
description: Plan and execute dependency migrations incrementally
---

Migrate dependencies from one package manager or version to another, one at a time, with validation after each step.

Steps:

1. Get the migration type from $ARGUMENTS or ask the user. Common migrations:
   - pip to uv
   - npm to pnpm
   - Major framework version upgrade (e.g. Flutter 3.x to 4.x)
   - Any other package manager or dependency migration

2. Detect platform context:
   - OS (Windows/Linux/Mac)
   - Current package manager and version
   - Language runtime and version
   - Record this in the migration plan

3. Build a dependency inventory:
   - Read existing dependency files (requirements.txt, package.json, pubspec.yaml, etc.)
   - Catalog all direct dependencies with pinned versions
   - Note dev vs runtime dependencies
   - Identify transitive dependencies where relevant

4. Create a migration plan in `docs/DEPENDENCY_MIGRATION.md`:
   - Source: current package manager / versions
   - Target: desired package manager / versions
   - Step-by-step migration order (least risky first)
   - Known incompatibilities or breaking changes

5. Execute the migration incrementally:
   - Migrate one dependency at a time
   - After each dependency: run import/build checks
   - After each successful migration: commit if tests pass (following /xida:git-commit pattern)
   - If a dependency fails: stop, report the error, ask user how to proceed

6. After all dependencies are migrated:
   - Run the full test suite (if configured)
   - Run code analysis (if configured)
   - Update `docs/DEPENDENCY_MIGRATION.md` with final results and any notes for future reference

7. Clean up old dependency files only after user confirms everything works.
