---
description: run code analysis, then fix the issues
---

Read CLAUDE.md and check if there is info how to run code analysis.
If not tell user he first has to setup testing using testing:setup command

Otherwhise run analyis.
This command is the **full-audit path**: run the FULL-codebase analyzer that
scans the whole source tree (e.g. `tools/analyze_code.bat`), NOT the
changed-files variant (`analyze_changed_and_new_files.bat`). The changed-files
bat is for the post-feature loop (see
`/analyze:enforce-post-feature-workflow`) and reports nothing when no source
files differ from git HEAD — which silently looks "clean" in an audit. If the
project documents only a changed-files bat, run the full analyzer bat anyway
and say so.
If there is one to fix errors, run that first, then run the analyze code.
Make sure to set the timeout to 20 minutes per bat since some projects might have a lot of tests.

**WordPress themes/plugins:** do NOT run a PSR-12 fixer bat (e.g.
`fix_php_issues.bat`, which applies php-cs-fixer `@PSR12`) — it reformats
WordPress-standard tabs into spaces across `src/`, `inc/`, `functions.php`. Skip
the fixer bat and run only the analyzer bat; use `tools/phpcbf.bat` (WordPress
standard) for style autofix. See `{cli-code-analyzer-path}/docs/setup/WORDPRESS.md`.

Then run command analysis:fix-only


## Fix the analyzer, not the symptom

If anything goes wrong that is the **analyzer's** fault — false positive, missed
detection, crash, wrong path/encoding handling, an analyzer that is not wired up,
a rule that cannot express the case you need, unclear or wrong output — fix it in
the cli-code-analyzer repo (`D:\GIT\BenjaminKobjolke\cli-code-analyzer`; the path
is also in the project's `tools/config.bat`) instead of working around it here.

Do:
1. Reproduce it directly: `python main.py <args>` inside the analyzer repo.
2. Fix it there (rule, docs, or setup doc), commit it there.
3. Re-run the project's bat to confirm the fix.
4. Tell the user what you changed in the analyzer repo.

Do NOT: disable a rule, add a file exception, hand-edit generated CSVs, wrap the
bat in a filter script, or skip an analyzer to make a report look clean.

Exception: genuinely project-specific config stays in the project —
thresholds and justified exceptions in `code_analysis_rules.json`, and per-project
paths/settings in `tools/config.bat`.

## Pre-existing issues — write them down, do not fix them

A full-codebase run surfaces violations in code the current task never touched.
Those are **out of scope**: do not fix them here, record them in
`open-issues/YYYY_MM_DD.md` (project root, today's date, e.g.
`open-issues/2026_08_29.md`) — create the folder/file if missing, append if it
already exists. Format and details: `/analyze:fix-only` and
`/bugs:plan-fix-prexisting`.

Work them off later with `/bugs:work` (oldest file first).
