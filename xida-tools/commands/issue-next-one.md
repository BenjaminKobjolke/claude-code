read issues/OPEN_ISSUES.md

Create one todo out of that document.
There is no need to handle the complete file.
Just group the todos by functionality and select one. 


Then create a plan to implement it.
First check if /doc folder has a matching documentation that could help you solve the issue.

After you are done remove the complete todos from ISSUES_OPEN.md and move them to ISSUES_COMPLETE.md
Make sure to copy the whole header style.
Example:
## #3: Bug: Orange dot
<!-- GITEA_ISSUE:3 -->

Also create a new file in issues/needs-testing/
Name it with a the same number as the gitea issue.
Like 003_ followed by a brief name of what to test like Login
So a valid filename is 003_TestLogin.md.
And describe the bug and how it should work now.
This file should also start with the gite header like
## #3: Bug: Orange dot
<!-- GITEA_ISSUE:3 -->