---
description: create release notes based on docs/CREATE_NEW_RELEASE.md
---

Can you create a new release.
There must be documentation bout that in docs/CREATE_NEW_RELEASE.md

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
```
New: Quick filter bar with multi-word search
Improved: Lock button to keep filter active when navigating
Fixed: Filter bar positioning on devices with navigation bar
```

### 5. Important Reminders
- **Only create en.json** - Do not create translations for other languages. Those will be created by another tool.
- Focus on changes visible to end users, not internal code refactoring