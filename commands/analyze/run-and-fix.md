---
description: run code analysis, then fix the issues
---

Read CLAUDE.md and check if there is info how to run code analysis.
If not tell user he first has to setup testing using /xida:	esting:setup command

Otherwhise run analyis.
If there is one to fix errors, run that first, then run the analyze code.
Make sure to set the timeout to 20 minutes per bat since some projects might have a lot of tests.

Then run command /xida:nalyze:fix-only

