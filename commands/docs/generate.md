---
description: Generate project documentation in markdown
---

Generate markdown documentation for the project following existing conventions.

Steps:

1. Check for existing docs structure: docs/ folder, README.md, CLAUDE.md, any other .md files.

2. Determine what to generate from $ARGUMENTS or ask the user. Options:
   - API documentation
   - Architecture overview
   - Setup / getting started guide
   - Changelog from git history
   - Any other specific documentation need

3. Read relevant source code and existing docs to understand the project structure and conventions.

4. Generate the documentation in markdown, matching the project's existing style and tone.

5. If the target file already exists, show a diff of the changes and ask the user for confirmation before overwriting. Never silently overwrite existing docs.

6. Save the generated documentation and tell the user the file path.
