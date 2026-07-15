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

Then run command analysis:fix-only

