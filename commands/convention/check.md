---
description: Scan codebase for existing patterns and conventions before implementing changes
---

Pre-implementation convention scanner. Run this before making code changes to identify existing patterns, components, and conventions that MUST be reused.

Steps:

1. Get the feature or change description from $ARGUMENTS. If not provided, ask the user what they're about to implement.

2. **Identify relevant areas**: Based on the description, determine which parts of the codebase will be affected (UI components, services, templates, translations, etc.).

3. **Scan for existing patterns**:
   - Grep for existing UI components and widgets related to the change (e.g. date_field, hub_link, form partials)
   - Check template patterns — how are similar pages/forms structured?
   - Check translation format — what parameter style does the project use? (e.g. :param vs %param%)
   - Check DI container patterns — how are services registered and injected?
   - Check for reusable Twig components, macros, or partials
   - Check CSS/SCSS for existing utility classes or component styles

4. **Check for DRY opportunities**:
   - Are there similar implementations elsewhere that could be generalized?
   - Would a shared component/rule be better than per-file changes?
   - Are there existing abstractions that should be extended rather than duplicated?

5. **Report findings** as a checklist:

   ## Convention Check Results

   ### Existing Components to Reuse
   - List each component/widget found with file path

   ### Translation Conventions
   - Parameter format used (e.g. :param)
   - Key naming pattern

   ### DI/Service Patterns
   - How services are registered
   - How dependencies are injected

   ### Template Patterns
   - Form structure conventions
   - Layout patterns used

   ### DRY Opportunities
   - Shared solutions vs per-file changes
   - Existing abstractions to extend

6. Tell the user: "Use these conventions in your implementation. Run /convention:check again after implementation to verify compliance."

This command does NOT make any code changes. It only scans and reports.

Related commands:
- /plan:feature — uses convention checking during planning
- /feedback:implement-new-api-changes — has built-in convention checking
- /dry:check — post-implementation DRY audit
