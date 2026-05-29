# Common Rules (All Languages)

These rules apply to all projects, regardless of language. Language-specific rules live in the
corresponding `*_RULES.md` files.

---

## Keep CLAUDE.md in Sync

When working on a project, copy all relevant rules into the project's `CLAUDE.md` file:

- Always include the common rules from `COMMON_RULES.md`
- Also include the language-specific rules for the project's language
- If `CLAUDE.md` already exists, compare and update it to keep rules current and deduplicated

---

## Use Objects for Related Values

When multiple related values must be passed between classes or methods, bundle them into a
dedicated object (e.g., DTO/Settings/Config) instead of passing many parameters. This improves
readability, reduces call-site churn, and makes changes safer.

---

## No Bag-of-Keys Returns at Module Boundaries

When a public method on a manager/repository/service returns data that crosses a module
boundary, the return type must be a typed object (DTO, value object, or domain model) — never
a raw associative array indexed by string keys. Plain `array` returns silently swallow shape
bugs: a missing key reads as `null`, a list-vs-single mix-up reads as "no data", and renames
go undetected by static analysis.

- **Anti-pattern.** `getSettingsValue(...)` returns `array|null`; callers do `$result['value']`,
  `$result['type']`. A consumer mis-indexes `$result[0]['value']` after a refactor; nothing
  flags the change. The function silently returns `null` and downstream defaults take over.
- **Correct pattern.** Return a class — `getSettingsElement(...): ?SettingsElement`. The class
  exposes `getValue()`, `getType()`, `exists()`. Typed, autocompleted, statically checked;
  renames propagate via the IDE.
- **Lists vs single must be obvious from the type and the name.** `getThing(): ?Thing`
  (zero or one) vs `getThings(): ThingList` or `iterable<Thing>`. Never overload the same
  return type to mean both.
- **Distinguish absent from empty.** `null` from a lookup means "not found"; an empty
  collection means "found, but had nothing". A typed return makes this contract explicit;
  a bag-of-keys array hides it.
- **JSON-decoded blobs are arrays too.** The rule applies equally to `json_decode($column, true)`
  results that cross a module boundary — wrap them in a value object before they leave the
  layer that owns the schema.
- **Internal helpers may stay arrays.** This rule targets *public* API on managers and the
  boundary where a domain abstraction starts. Pure-private array juggling inside a single
  method is fine.

---

## Reuse Existing Models Before Inventing Array Shapes

Before designing a new return type or DTO, search the codebase for an existing domain class
that already owns the same data. Most "should this be a DTO?" decisions are actually
"is there already a `Contest` / `User` / `Order` class that should absorb this method?"

- Grep for the table name, the primary key, and the most distinctive column.
- If a model already exists with a constructor that accepts the row shape, use it — don't
  invent a parallel array shape that mirrors the same columns.
- Adding a `getXxxObject()` alongside a legacy `getXxxData()` is acceptable as a migration
  step; keep both only until consumers are migrated, then delete the array-returning version.

---

## Tests Pin the Shape Before the Refactor

When converting a bag-of-keys return to a typed object, write a **characterization test
first** that locks the current behavior using the existing API, run it green against the
unrefactored code, and then refactor. The same test (or a renamed-but-equivalent one) must
remain green afterward.

This converts "I think the new object preserves behavior" into "the test proves it." Pair
with the "Test-Driven Development" rule below — characterization tests are TDD applied to
refactors instead of new features.

---

## Test-Driven Development for Features and Bug Fixes

Follow TDD when implementing features or fixing bugs:

1. Write tests first
2. Run the tests and confirm they fail
3. Implement the change or fix
4. Run the tests again and confirm they pass

---

## Integration Tests

Every project must include integration tests in addition to unit tests. Integration tests verify that
components work correctly together and catch issues that unit tests alone cannot detect.

---

## Test Runner Scripts

Every project must provide the following batch files in the `tools/` directory:

- `tools/run_tests.bat` — runs unit tests
- `tools/run_integration_tests.bat` — runs integration tests

These scripts ensure a consistent way to execute tests across environments.

---

## Prefer Type-Safe Values

Use strong, explicit types instead of loosely typed or stringly typed values (e.g., typed DTOs,
enums, generics, typed settings). This ensures mistakes are caught at compile time or by tests
early in development.

---

## String Constants

Centralize string constants in a dedicated module/class. Do not scatter raw strings across
the codebase. Use language-appropriate patterns for constants and reuse them consistently.

---

## Reusable Tooling

Before building project-specific infrastructure scripts (audits, codemods,
build helpers, lint checks, etc.) for a project, check the matching
language's `*_setup_files/` folder under this `coding-rules` repo for an
existing equivalent. If found, copy or reference it. If not:

1. Build the script in the project and prove it on real data.
2. Copy the script into the right `*_setup_files/tools/` folder.
3. Document it in that language's `*_RULES.md` so the next project picks
   it up automatically.

This keeps cross-project tooling consistent and prevents the same script
from being re-invented in every new project.

---

## README.md is Mandatory

Every project must have a `README.md` file in the root directory. It should include:

- Project name and description
- Installation/setup instructions
- Usage examples
- Dependencies and requirements

---

## Don't Repeat Yourself (DRY)

Avoid code duplication. If the same logic appears in multiple places, extract it into a
reusable function, class, module, or utility.

- Duplicate code is harder to maintain and leads to bugs
- Extract shared logic into helpers or base abstractions
- Use constants for repeated values

---

## Confirm Dependency Versions

Before adding any new package or library, confirm the version with the user to ensure we use
up-to-date dependencies.

- Do not assume which version to use
- Ask the user to verify the latest stable version
- Avoid outdated packages that may have security vulnerabilities or missing features

---

## Error Handling & Logging Strategy

Every project must have a centralized error handler rather than ad-hoc try/catch blocks scattered
throughout the codebase.

- Use structured logging (not `print`/`console.log`/`echo`)
- Log at appropriate levels: debug, info, warning, error
- Include context in log messages (module name, operation, relevant IDs)

---

## Input Validation at Boundaries

Always validate data at system boundaries — API inputs, user input, file uploads, external service
responses.

- Never trust external data; validate before processing
- Use language-appropriate validation libraries (e.g., Pydantic, Zod, FluentValidation)
- Fail fast with clear error messages when validation fails

---

## Maximum File Length — 300 Lines

Split files when they exceed 300 lines to keep code navigable during fast iteration.

- Extract classes, functions, or components into separate modules
- Group related extractions logically (by domain, not by type)
- Exceptions: generated files, configuration files, test files with many similar cases

---

## Naming Conventions

Be consistent within a project. Follow these defaults unless the language or framework dictates
otherwise:

- Files: `snake_case` (or language convention, e.g., `PascalCase` for C# classes)
- Classes: `PascalCase`
- Functions/methods: language convention (`snake_case` for Python/PHP, `camelCase` for Dart/JS/C#)
- Constants: `UPPER_SNAKE_CASE`
- Variables: language convention (`snake_case` for Python/PHP, `camelCase` for Dart/JS/C#)

---

## Security Baseline

Every project must follow these minimum security practices:

- Never commit secrets (`.env`, API keys, credentials, private keys)
- Escape output to prevent XSS/injection attacks
- Use parameterized queries or ORM-provided methods — never concatenate user input into queries
- Validate and sanitize all user input at system boundaries
- Keep dependencies updated to avoid known vulnerabilities

---

## No God Classes

A class that handles too many responsibilities becomes fragile, hard to test, and impossible to
reuse. Keep each class focused on a single purpose.

- **Warning signs**: more than 5 public methods, more than 4 constructor dependencies, or methods that span unrelated domains (e.g., a class that validates input, queries the database, and sends emails)
- Split by responsibility: extract collaborators (e.g., a `Validator`, a `Repository`, a `Notifier`) rather than piling logic into one class
- If you struggle to name the class without using "Manager", "Handler", "Service", or "Helper" as a catch-all, it likely does too much
- This complements the 300-line file rule — a short class can still be a god class if it owns too many concerns

---

## Self-Describing Classes

When behavior depends on which fields or properties a class has — such as search, serialization,
display, validation, or auditing — the class itself must declare those fields through a contract
(interface, abstract method, attribute/annotation, or introspection pattern). Never hardcode field
lists in consuming code.

- **Anti-pattern**: A search service contains a hardcoded list of fields to index for each entity;
  adding a new field requires updating every consumer manually
- **Correct pattern**: Each class implements a contract (e.g., `GetSearchableFields()`,
  `GetDisplayColumns()`) that returns its own relevant fields, so adding a field in one place
  automatically propagates everywhere
- This applies to any cross-cutting concern that operates over class fields: search, filtering,
  export, form generation, diffing, logging, etc.
- Combine with compile-time checks where the language supports them (e.g., sealed interfaces,
  exhaustive matching) to ensure new fields cannot be silently ignored
