# graphify Knowledge Graph (Optional Addon)

**Optional.** Before adding this to a project, ASK the user whether they want to use graphify.
Only wire it into the project's `CLAUDE.md` if they say yes.

graphify turns a code folder into a queryable knowledge graph — god nodes, communities,
cross-file relationships, fan-in/fan-out. The build is AST-only: no LLM, no API cost. Use it to
orient before grep and to spot god classes.

---

## One-time setup

1. **Install the Claude Code integration** (writes a generic graphify section into `CLAUDE.md`
   plus PreToolUse hooks that consult the graph before grep/read):
   ```
   /graphify claude install
   ```
2. **Check `.claude/settings.json` for the Windows slash bug.** On Windows the installer writes
   the hook command with backslash paths, e.g. `C:\\Users\\<you>\\.local\\bin\\graphify.EXE`.
   Claude Code runs PreToolUse hooks through Git Bash, which strips the backslashes →
   `C:Users<you>.local...` → `command not found` on every Bash/Read/Glob. Fix: open
   `.claude/settings.json` and replace the backslashes in the hook `command`(s) with forward
   slashes — `C:/Users/<you>/.local/bin/graphify.EXE` (Git Bash accepts drive paths with `/`).
   Also dedupe: the installer may write a redundant backslash `Bash` entry alongside a correct
   `Bash|Grep` one — keep exactly two entries (`Bash|Grep`, `Read|Glob`), forward slashes.
   Then confirm it runs: `"C:/Users/<you>/.local/bin/graphify.EXE" hook-guard search`.
   Note: Claude Code may permission-block edits to `.claude/settings.json` — the user may need
   to explicitly request/approve the fix. Hooks written mid-session don't load until the user
   opens `/hooks` once or restarts the session.
   (Non-Windows hosts are unaffected — skip this step.)
3. **Build the first graph — scoped and directed.** Point it at the folder that holds the
   source code, NOT the repo root:
   ```
   /graphify <code-dir> --directed        # e.g. src/  app/  lib/  internal/
   ```
   - `<code-dir>` = the single folder with the code. Scoping keeps `vendor/`, `node_modules/`,
     build output, and tests out of the graph. A repo-root build drowns the signal in deps.
   - `--directed` is **required**. Without it the graph is undirected and total edge count blends
     incoming and outgoing — you cannot tell a healthy shared base (high fan-**in**) from a god
     class (high fan-**out**).
4. **Replace the generic `CLAUDE.md` section** the installer wrote with a single
   `@import` line:
   ```
   @D:\GIT\BenjaminKobjolke\claude-code\coding-rules\ai_rules_addons\graphify_rules.md
   ```
   Do not paste the rules text — import `graphify_rules.md` so fixes there propagate
   to every project without a manual re-sync.
5. **gitignore the output** — build artifacts + cache, never committed:
   ```
   graphify-out/
   <code-dir>/graphify-out/
   ```

## Folder layout (know which is which)

- `graphify-out/` at the **project root** = the **live graph** (`graph.json`, `GRAPH_REPORT.md`,
  `graph.html`). The only one queries read. Keep it `directed=True`.
- `<code-dir>/graphify-out/` = **AST cache only** (`cache/`). Scratch that speeds re-extraction.
  Never the live graph under the documented flow. Do not query it.

## What the graph knows (and does not)

- Knows: code structure — classes, methods, calls, references, extends/implements, plus
  fan-in/fan-out and community / god-node structure.
- Does NOT know: business rules, API response shape, or rendered template/view output. It is a
  snapshot — stale until rebuilt. Constants referenced by string can appear as isolated nodes
  (AST limitation, not a missing dependency).

---

## Rules for the project's CLAUDE.md

See `graphify_rules.md` in this folder — `@import` it (step 4 above), never copy its
text in.
