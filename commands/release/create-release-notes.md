---
description: create release notes based on docs/CREATE_NEW_RELEASE.md
---

Can you create a new release.
There must be documentation bout that in $CLAUDE_PROJECT_DIR/docs/CREATE_NEW_RELEASE.md

If not ask the user to run /xida:elease:setup

## Step-by-Step Workflow

### 1. Get the Next Build Number

### 2. Find Changes Since Last Release

**Important:** Changes may come from two sources:
- **Uncommitted changes in the current session** - Check what was done during this Claude session
- **Committed changes in git** - Use git log to find changes

To find the last appstore release in git:
```
Bash(git log --oneline --grep="RELEASE:" -n 20)
```
Look for commits like: `RELEASE: v1.0.2.296`

To see commits since the last release:
```
Bash(git log --oneline <last_release_commit>..HEAD)
```

**If there are no commits between last release and HEAD**, the changes are likely uncommitted work done in this session. Document those changes instead.

### 3. Create Release Notes Subdirectory

### 4. Create en.json File


**Writing Guidelines:**
- Use **informal tone** (conversational, friendly)
- Write for **end users** (no technical jargon)
- Maximum **400 characters**
- Structure with sections when multiple changes:
  - "New:" for new features
  - "Improved:" for enhancements
  - "Fixed:" for bug fixes
- Focus on **user benefits**, not technical details
- Be brief and clear

**Examples:**
- Simple (one feature): `"New: Quick filter bar to search files by name. Type multiple words separated by space to narrow down results."`
- Complex (multiple changes):

New: Quick filter bar with multi-word search
Improved: Lock button to keep filter active when navigating
Fixed: Filter bar positioning on devices with navigation bar

Structure:

```
{
  "_hint_": "If the language has a formal and an informal way. Then use the informal way.",
  "_hint_2_": "All texts are for a BASIC APP FUNCTION. So the translations should be adjusted to this genre. Example: Home in english should be translated to Start in german since a translation like Zuhause doesnt make sense for an app like this",
  "_hint_text": "Maximum length is 400 characters; if it's too long, you must shorten it, even if that means not adhering 100% to the original language. Count the characters afterwards and adjust the length if its still too long.",
  "text": "Fixed some bugs."
}
```

BASIC APP function needs to be a very short description of what the app does.
Like "file explorer and media viewer app".


### 5. Important Reminders
- **Only create en.json** - Do not create translations for other languages. Those will be created by another tool.
- Focus on changes visible to end users, not internal code refactoring
- Check the release notes immediately befor ethe current ones so we dont repeat features we might have already mentioned before.