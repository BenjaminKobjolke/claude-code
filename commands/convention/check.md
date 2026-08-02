---
description: Run a scoped, token-efficient convention scan before implementing changes
context: fork
agent: Explore
model: haiku
effort: low
---

Find conventions relevant to this proposed change: $ARGUMENTS

This is a read-only, bounded scan. If `$ARGUMENTS` is empty, do not inspect the repository; ask for a concrete change description.

1. Classify the smallest affected area: UI, backend/service, data/model, translations/content, tests, tooling, or documentation.
2. Run the first pass:
   - Derive at most 3 concrete search terms from the request.
   - Make at most 3 targeted search calls. Prefer Grep/Glob or `rg`, request filenames or counts first, and cap displayed matches at 10. Never dump unrestricted recursive output.
   - Read at most 3 representative files and at most 200 relevant lines total. Do not read whole directories or large files in full.
   - Inspect only convention types relevant to the classified area, such as reusable components, service/DI patterns, validation/serialization, translation syntax, tests, or tooling structure.
3. Stop when either one implementation plus corroborating test/config/usage evidence, or two consistent implementations, establish the convention.
4. If evidence is missing or conflicting, run one expansion pass only: at most 2 more searches, 2 more files, and 150 more relevant lines. Then stop and report the gap or conflict.
5. Mention reuse and DRY opportunities found in this evidence. Do not perform a separate DRY search, broad manifest inventory, or unrelated architecture survey.

Return at most 250 words and cite no more than 3 representative paths. Use only these headings, omitting empty ones:

## Conventions
## Reuse
## Constraints or Gaps

Do not make any code changes.
