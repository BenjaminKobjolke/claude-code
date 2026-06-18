# AI Workflow Rules (All Languages)

See `COMMON_RULES.md` for rules that apply to all languages.

Unlike the per-language `*_RULES.md` files, these rules are **language-independent** and
**always apply**. They are not subject to the "some rules may not apply to this project"
filtering — include them in every project's `CLAUDE.md`.

These rules define the end-to-end workflow an AI agent must follow when planning and
implementing changes. Each step is an existing skill referenced by its slash name; run the
skill rather than reimplementing its behavior.

---

## Feature / Change Workflow

After a plan is proposed and the user approves it, follow this chain:

```
plan approved
  → /plan:dry            check the approved plan for DRY/consolidation BEFORE writing code
  → /plan:dry-checked    reload and review the DRY-adjusted plan
  → /convention:check    scan for existing patterns/components to reuse before implementing
  → implement
  → /dry:check           post-implementation DRY audit on the changed files
  → /verify:after-change run tests + code analysis
```

- **`/plan:dry` runs before any code is written** — it is cheaper to remove duplication in
  the plan than in the diff.
- **`/convention:check` runs before implementing** — reuse existing utilities, components,
  and patterns instead of inventing parallel ones.
- **`/dry:check` and `/verify:after-change` run after implementation** — audit duplication
  and confirm tests/analysis pass.

---

## Bug-Fix Workflow

Bug fixes use a shorter variant (no plan-DRY phase):

```
bugs:fix
  → /verify:after-change
```
