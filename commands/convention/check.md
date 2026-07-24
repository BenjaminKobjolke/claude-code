---
description: Run a scoped, token-efficient convention scan before implementing changes
---

Pre-implementation convention scanner. Run this before making code changes to identify existing patterns, components, and conventions that MUST be reused.

Default to the cheapest useful scan. Do not read whole directories, inspect every similar file, or fill irrelevant checklist sections. Expand only when the first pass does not produce enough evidence to guide the implementation.

Steps:

1. Get the feature or change description from $ARGUMENTS. If not provided, ask the user what they're about to implement.

2. **Classify the change**: Identify the smallest likely area affected by the request, such as UI, backend service, model/schema, translations, styles, tests, build tooling, or documentation.

3. **Start from targeted evidence**:
   - Prefer `rg` over recursive file reads.
   - Search for 2-5 concrete terms from the request: domain nouns, component names, route names, service names, labels, config keys, or test names.
   - Inspect manifests, route/config files, or changed files only when they help locate the relevant area.
   - Read the smallest representative files needed to infer the convention.

4. **Scan only relevant convention types**:
   - UI changes: look for existing components, widgets, templates, view models, form controls, layout patterns, and styles used for similar UI.
   - Backend/service changes: look for service registration, dependency injection, repository/client patterns, error handling, logging, and tests around similar behavior.
   - Data/model changes: look for schema, migration, validation, serialization, naming, and fixture patterns.
   - Translation/content changes: look for key naming, placeholder syntax, fallback behavior, and locale file organization.
   - Tooling/docs changes: look for existing scripts, docs structure, naming, and verification commands.

5. **Deepen only when needed**:
   - If no pattern is found, broaden the search one level and say what was searched.
   - If multiple incompatible patterns are found, cite the candidates and recommend the one closest to the requested change.
   - If enough evidence exists, stop. Cite representative files instead of listing every match.

6. **Check for DRY opportunities**:
   - Note similar implementations that should be reused or extended.
   - Prefer existing abstractions over per-file duplication.
   - Do not propose a new abstraction unless at least two concrete consumers or a clear local pattern justify it.

7. **Report compact findings**:

   ## Convention Check Results

   ### Relevant Conventions Found
   - Summarize only conventions that apply to the requested change.

   ### Files and Patterns to Reuse
   - List representative file paths and reusable components, helpers, scripts, or tests.

   ### Gaps or Ambiguity
   - Mention missing evidence or conflicting patterns. Omit this section if there are none.

   ### Implementation Constraints
   - List concise rules the implementation must follow.

8. Tell the user: "Use these conventions in your implementation. Run /convention:check again after implementation to verify compliance."

This command does NOT make any code changes. It only scans and reports.

Related commands:
- /plan:feature - uses convention checking during planning
- /feedback:implement-new-api-changes - has built-in convention checking
- /dry:check - post-implementation DRY audit
