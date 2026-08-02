# AI Workflow Rules (All Languages)

See `COMMON_RULES.md` for rules that apply to all languages.

Unlike the per-language `*_RULES.md` files, these rules are **language-independent** and
**always apply**. They are not subject to the "some rules may not apply to this project"
filtering — import them into every project's `CLAUDE.md` via `@import` (see
§ Keep CLAUDE.md in Sync below).

These rules define the end-to-end workflow an AI agent must follow when planning and
implementing changes. Each step is an existing skill referenced by its slash name; run the
skill rather than reimplementing its behavior.

---

## Keep CLAUDE.md in Sync

When working on a project, reference the shared rules via Claude Code `@import` lines in the
project's `CLAUDE.md`, using absolute paths into this repo's `coding-rules/` folder:

```
@D:\path\to\claude-code\coding-rules\COMMON_RULES.md
@D:\path\to\claude-code\coding-rules\AI_RULES.md
@D:\path\to\claude-code\coding-rules\<LANGUAGE>_RULES.md
```

Above the imports write a line:
You must read those files.
Otherwise those files will not be loaded.

- Always import `COMMON_RULES.md` and `AI_RULES.md`
- Also import the language-specific `*_RULES.md` file(s) for the project's language
- If `CLAUDE.md` already has rule text copy-pasted in, replace it with the import lines instead
- `@import` is a Claude Code feature resolved from `CLAUDE.md` — absolute paths are required so
  it works regardless of the project's working directory

**Project overrides.** If the project deviates from any imported rule — overrides, disables, or
replaces it — state that explicitly in a section **below** the imports in the project's
`CLAUDE.md`. The imports are the shared baseline; that section is where the project records its
exceptions, so the deviation is visible without diffing against the shared rule files.

**Imports must actually be read.** Not every agent/harness auto-expands `@import` — some
receive the literal `@path` text and never see the imported content. To guard against that,
every project's `CLAUDE.md` MUST contain an explicit instruction line **above** the `@import`
lines telling the agent the files must be imported. Paste this line in verbatim:

```
> IMPORTANT: The @import lines below pull in mandatory shared coding rules. If your
> agent/harness does not automatically expand `@import`, you MUST Read each path
> below (in full) before planning or implementing anything.
```

---

## Feature / Change Workflow

After a plan is proposed and the user approves it, follow this chain. The DRY
gate is a precondition for implementing — not just an earlier step.

The approved plan must first exist as an explicit Markdown file. Pass that same
path to both plan-DRY commands.

```
plan approved

run
codex exec --dangerously-bypass-approvals-and-sandbox "FULL PATH TO PLAN - Can you check the plan for DRY opportunities and if you find any, apply them to the original plan file. Add a summary at the end what you changed and why."

run
codex exec --dangerously-bypass-approvals-and-sandbox "FULL PATH TO PLAN $convention-check - If you want to make any changes, apply them to the original plan file. Add a summary at the end what you changed and why."

/plan:dry-checked    reload the DRY and convention adjusted plan

restate Definition-of-Done aloud

implement

run post-implementation DRY audit
codex exec --dangerously-bypass-approvals-and-sandbox "FULL PATH TO PLAN - Can you check the plan for DRY opportunities and if you find any, apply them to the original plan file. Add a summary at the end what you changed and why."

Post-Feature Verification + Post-Implementation Code Analysis (project-specific, below)

```

### DRY gate (precondition for implementing)

Do not write a single line until ALL are true. Restate this gate aloud at the
moment you start implementing — if you cannot, the gate is not cleared:

- [ ] `/plan:dry <plan-file>` adjusted that file and completed its Ponytail pass.
- [ ] `/plan:dry-checked <plan-file>` reloaded the same adjusted plan.
- [ ] `/convention:check` found the existing utilities/patterns to reuse.

The gate survives the `implement` step: if mid-implementation you add a new
helper, type, or pattern the gate would have caught, stop and re-clear it
before continuing.

### Definition of Done — restate aloud before implementing

Before the first edit, state in chat what "done" means for THIS change:

- [ ] Scope: <one line — what changes, what does not>
- [ ] Reuse: <existing function/component this builds on, with path>
- [ ] DRY gate cleared (above)
- [ ] `/dry:check` clean
- [ ] `/verify:after-change` green (tests + analysis)

### Post-implementation DRY audit — paste-in template

Run `/dry:check`, then paste and fill:

```
DRY audit — <change name>
Changed files:     <list>
Duplication found: <none | describe>
Consolidated into: <shared fn/module + path | n/a>
Convention reused: <name + path>
Verdict:           <clean | needs rework>
```

---

## Bug-Fix Workflow

Bug fixes use a shorter variant (no plan-DRY phase):

```
bugs:fix
  → /verify:after-change
```

---

## Optional Addons

These live in `ai_rules_addons/` and are **not** always-on. Each is opt-in per project — ASK
the user whether they want it before wiring it into that project's `CLAUDE.md`.

- [`ai_rules_addons/graphify.md`](ai_rules_addons/graphify.md) — graphify knowledge graph:
  scoped + directed AST build, folder layout, gitignore. One-time setup only — not for
  import. Once set up, the project's `CLAUDE.md` gets a single `@import` line for
  [`ai_rules_addons/graphify_rules.md`](ai_rules_addons/graphify_rules.md) (query/refresh
  rules), never pasted text.
