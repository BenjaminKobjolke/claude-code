---
description: GIT commit changed and new files according to XIDA standards
effort: low

---

Git commit and push local changes and new files.
Create separate commits for fixes, code improvements and new features.

Before staging, group changed files by logical concern. If changes span multiple unrelated concerns (e.g. a bug fix + a new feature + a style change), propose separate commits and stage only relevant files per commit. Do not bundle unrelated changes into a single commit.

## How to execute the commit

IMPORTANT: Do NOT use the HEREDOC/command-substitution pattern `$(cat <<'EOF' ... EOF)` for commit messages.
Instead, always use a temporary file approach to avoid the "$() command substitution" security prompt:

1. Write the commit message to `tmp/commit_msg.tmp` using the Write tool
2. Run: `git commit -F tmp/commit_msg.tmp`
3. Delete `tmp/commit_msg.tmp` after a successful commit

IMPORTANT: Never prefix git commands with `cd /path &&`. Run all git commands directly (e.g. `git add`, `git commit`, `git push`) without `cd`. The working directory is already correct. Combining `cd` with git triggers a "bare repository attack" security prompt.

Never commit PLAN.md or HANDOFF.md.

Before committing, check if the project has validators configured in CLAUDE.md.
If validators are configured and /validate:pre-commit was not already run in this session, run it automatically before committing — do not just ask, run it.
If validation fails, show the failures and ask the user if they want to fix the issues or proceed with the commit anyway.

Also do not confirm GIT commit message in prompt or slash commands.

Commit changes that you didnt do in this session too. Research those files to figure out what changed.

Make sure to not commit files with credentials, like .env, settings.json. Only if those are just test credentials. Ask the useer if he wants to ignore thosee files.

The user has to call this command again for feature commit and push requests.
Which means to not automatically commit or push no changes the user requested after this commit request.

If you see files showing as modified with only line ending changes (LF vs CRLF), check if the project has a `.gitattributes` file. If not, create one to normalize line endings to LF before committing:

```
# Normalize all text files to LF in the repository
* text=auto eol=lf

# Explicitly mark binary files
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.pdf binary
*.zip binary
*.gz binary
*.tar binary
```

Then run `git add --renormalize .` to fix existing files and commit the `.gitattributes` as a separate GIT commit.

Automatically push at the end.

---

Adhere to the following rules.

# Git commit guidelines

## Format of the commit message

```
<type> (<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

>Any line of the commit message cannot be longer 100 characters! This allows the message to be easier to read on GitHub as well as in various Git tools.

#### Allowed `<type>`

 * **FEATURE** (feature)
 * **FIX** (bug fix)
 * **DOCS** (documentation)
 * **STYLE** (formatting, missing semi-colons, etc.)
 * **TEST** (when creating tests)
 * **CLEANUP** (remove unnecessary code, files)
 * **IMPROVE** (improvement, e.g. enhanced feature)
 * **TOOLS** (build, tools changes etc.)
 * **GIT** (.gitignore changed, Git configuration changed etc.)
 * **RELEASE**  (created a new .exe, .ipa, .apk etc.) There is no need to add the actual released file. But there should be a commit for every release so it is easier for old projects to track down what the last version was, that was sent to the client
 * **CONTENT** (added images, html, pdf, video etc.)
 * **REFACTOR** (code restructuring without changing external behavior)
 * **PERF** (performance improvements)
 * **CI** (CI/CD pipeline changes, GitHub Actions, etc.)
 * **CHORE** (maintenance tasks, dependency updates, configs)
 * **AI** (prompt templates, model configurations, AI agent settings etc.)
 * **EXAMPLE** (sample code, demo projects, usage demonstrations)


Release messages need to have the following format:
```
RELEASE (<scope>): <versionnumber>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

#### Allowed `<scope>`

Scope could be anything specifying place or element of the commit change(s).

Examples:
 * **Component names:** `header`, `sidebar`, `login-form`, `user-profile`
 * **Feature areas:** `auth`, `payments`, `notifications`, `search`
 * **File types:** `api`, `ui`, `database`, `config`
 * **Layers:** `service`, `controller`, `model`, `view`

#### Allowed `<subject>` text

 * use imperative, present tense: _change_ not _changed_ nor _changes_ or _changing_
 * do not capitalize first letter
 * do not append dot (.) at the end

> Subject line contains description of the change.

#### Allowed Message `<body>`

 * just as in <subject> use imperative, present tense: _change_ not _changed_ nor _changes_ or _changing_
 * include motivation for the change and contrast it with previous behavior
 * if commit is list use dash (-) to list items in a separate line

### Message Footer

#### Breaking changes

All breaking changes have to be mentioned in footer with the description of the change, justification and migration notes

```
BREAKING CHANGE: Id editing feature temporarily removed
As a work around, change the id in XML using replace all or friends
```
#### Referencing issues

Closed bugs / feature requests / issues should be listed on a separate line in the footer prefixed with "Closes" keyword like this:
 
    Closes #234

or in case of multiple issues:
 
    Closes #123, #245, #992
    
### Good commit message examples:

```
STYLE (notifications): change notifications

change warning notification colors:
- error notifications are now red
- warning and info notifications are now dark-yellow
```

or

```
FEATURE (editor): add emmet plug-in to editor

- add emmet plug-in to editor
- add emmet plug-in settings

Closes #351
```

Also check .gitmodules if there are submodules.
Then process with the same workflow for those submodules.