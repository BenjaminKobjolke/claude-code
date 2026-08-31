---
description: Fix a bug using test-driven development — write failing test first, then fix
---

Fix a bug using strict TDD discipline: failing test first, then minimal fix, then verify.

Steps:

1. Get the bug description from $ARGUMENTS. If not provided, ask the user to describe the bug.

2. **Understand the bug**: Search the codebase for the relevant code. Identify:
   - Where the bug manifests
   - What the expected behavior should be
   - What the actual (broken) behavior is

3. **Write a failing test**: Create a test that reproduces the exact bug.
   - The test should pass when the bug is fixed and fail with the current code
   - Follow the project's existing test patterns and conventions
   - If the project has no test infrastructure, tell the user and suggest /testing:setup

4. **Confirm test fails**: Run the test suite. The new test MUST fail. If it passes, the test doesn't reproduce the bug — revise it.

5. **Implement the minimal fix**: Make the smallest code change that fixes the bug.
   - Check existing project patterns before writing new code (/convention:check principles)
   - Do not refactor or improve surrounding code — only fix the bug

6. **Confirm test passes**: Run the full test suite. The new test must now pass, and no existing tests should break. If tests still fail, iterate on the fix.

7. **Verify**: Run /validate:pre-commit to check nothing else broke. Also check:
   - DI container includes any new services
   - Translation keys use project format conventions
   - No raw HTML where project widgets exist

8. Present the final diff to the user and tell them they can commit with /git:commit.

Related commands:
- /bugs:fix — structured bug fix from open-issues/ (now includes TDD steps)
- /bugs:collect — document bugs for later fixing
- /testing:run — run tests independently
