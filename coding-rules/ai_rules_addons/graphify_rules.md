# graphify Knowledge Graph — Usage Rules

Import this file (`@D:\GIT\BenjaminKobjolke\claude-code\coding-rules\ai_rules_addons\graphify_rules.md`)
into a project's `CLAUDE.md` once graphify setup (see `graphify.md`) is done. Do not
paste this text — import it, so fixes here propagate to every project.

## Using the graph

- For codebase questions, run `graphify query "<question>"` first when `graphify-out/graph.json`
  exists. `graphify path "<A>" "<B>"` for relationships; `graphify explain "<concept>"` for a
  focused node. These return a small scoped subgraph vs. reading GRAPH_REPORT.md or raw grep.
- Judge coupling by direction: high **fan-in** + low fan-out (shared base / constants / DTO) is
  healthy; high **fan-out** (>~20 outgoing deps) is god-class risk and a refactor signal.
- Read `graphify-out/GRAPH_REPORT.md` only for broad architecture review, or when
  query/path/explain do not surface enough context.

## Refreshing after a code change

- After a feature or any code change, rebuild via the **directed skill flow**: re-run
  `/graphify <code-dir> --directed`, writing to the project-root `graphify-out/`.
- Do NOT use the bare `graphify update <code-dir>` CLI — it has no `--directed` flag and writes a
  full UNDIRECTED graph into `<code-dir>/graphify-out/` (wrong location), desyncing the live
  graph. If that stray graph appears, delete `<code-dir>/graphify-out/graph.json` (keep `cache/`).
- Verify after rebuild: `graph.json` has `directed: true` and lives in root `graphify-out/`.
