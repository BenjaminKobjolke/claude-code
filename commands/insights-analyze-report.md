---
description: Analyze a usage report HTML and generate a command improvement plan
---

Analyze a Claude Code usage report and cross-reference it against existing commands to find gaps and improvement opportunities.

Steps:

1. Get the report path from $ARGUMENTS. If not provided, ask the user for the path to their report HTML file.

2. Read the HTML report file and extract key data:
   - Top activities by session count
   - Friction points (bugs, wrong approaches, errors)
   - Tool error counts (Command Failed, User Rejected)
   - Session patterns and handoff frequency
   - Most common workflows

3. Read all command `.md` files under `commands/` to build an inventory of existing commands:
   - List each command with its description
   - Note which activity categories each command covers
   - Identify which friction points each command could mitigate

4. Cross-reference activities vs commands:
   - Which top activities have no supporting command?
   - Which activities have commands but could be better supported?
   - Are there commands that map to rarely-used activities?

5. Cross-reference friction points vs commands:
   - Which friction points could be reduced by a new command?
   - Which existing commands could be enhanced to catch common errors?
   - What validation gaps exist in the current workflow?

6. Generate a report at `$CLAUDE_PROJECT_DIR/docs/COMMAND_IMPROVEMENT_PLAN.md` with these sections:
   - **Summary**: Key findings from the usage data
   - **New Commands Needed**: Commands to create, with rationale from usage data
   - **Existing Commands to Enhance**: Specific improvements with before/after
   - **Redundant Commands**: Commands with low/no usage that could be consolidated
   - **Integration Opportunities**: Commands that should reference each other
   - **Priority Order**: Ranked by expected impact (sessions affected x friction reduced)

7. Present the findings to the user. Do NOT auto-implement any changes. Let the user decide what to act on.
