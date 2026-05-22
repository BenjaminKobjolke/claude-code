---
description: create release notes based on docs/CREATE_NEW_RELEASE.md
---

Create new release notes for the project.

There must be documentation about that in $CLAUDE_PROJECT_DIR/docs/CREATE_NEW_RELEASE.md

If not, ask the user to run /release:setup.

## Step-by-Step Workflow

### 1. Get the Next Version and Build Number

**Important:** the `prebuild` hook bumps **both** `package.json` semver patch and Android `versionCode` on every `npm run build`. So the next AAB will ship as `currentSemver+1patch` / `currentVersionCode+1`.

Read the current semver from `package.json` and bump the patch by one:

```
node -e "const v=require('./package.json').version.split('.');console.log(v[0]+'.'+v[1]+'.'+(+v[2]+1))"
```

Get the next `versionCode`:

```
tools/build_number_show.bat
```

The directory name will be `<nextSemver>_<nextBuildNumber>` — for example `1.0.7_1655`.

If you're authoring notes for a build that will use `--no-bump` (rare), use the current semver as-is (since `--no-bump` skips the package-version bump). The `versionCode` always bumps regardless of the flag.

### 2. Find Changes Since Last Release

This app is split across **three repos** that ship together:

| Repo | Path |
| --- | --- |
| `ai-chat` (this) | `$CLAUDE_PROJECT_DIR` |
| `ai-chat-api` | `D:/wamp64/www/ai-chat-api` |
| `ai-chat-data-server` | `D:/GIT/Intern/ai-chat-data-server` |

All three may contain user-visible changes for this release.

#### 2a. Anchor: last versionCode actually on the appstore

The anchor is the versionCode currently live on the Play Store — **not** the latest local `RELEASE` commit. A locally built/committed version may never have been uploaded.

##### 2a-i. Determine `$APPSTORE_VERSIONCODE`

1. If `$CLAUDE_PROJECT_DIR/appstore-versioncode.txt` is **missing**:
   - Ask the user: *"`appstore-versioncode.txt` is missing. What is the last versionCode that was uploaded to the appstore?"*
   - Write the integer answer to `$CLAUDE_PROJECT_DIR/appstore-versioncode.txt` (single line, no trailing whitespace).
2. Read the integer from the file → `$APPSTORE_VERSIONCODE`.

##### 2a-ii. Detect stale file (latest RELEASE commit ahead of appstore)

```
git log --oneline --grep="^RELEASE" -n 1
```

Parse the `+<N>` suffix from the commit subject (e.g. `RELEASE (android): 1.1.0+935` → `935`). Call this `$LATEST_RELEASE_VERSIONCODE`.

If `$LATEST_RELEASE_VERSIONCODE` ≠ `$APPSTORE_VERSIONCODE`:

- Ask the user: *"Last `RELEASE` commit is `+$LATEST_RELEASE_VERSIONCODE` but `appstore-versioncode.txt` says `$APPSTORE_VERSIONCODE`. Was `+$LATEST_RELEASE_VERSIONCODE` uploaded to the appstore?"*
- If **yes** → overwrite `appstore-versioncode.txt` with `$LATEST_RELEASE_VERSIONCODE` and set `$APPSTORE_VERSIONCODE = $LATEST_RELEASE_VERSIONCODE`.
- If **no** → keep the file as-is; continue with the existing `$APPSTORE_VERSIONCODE`.

##### 2a-iii. Find the anchor commit by versionCode

```
git log --oneline -E --grep="^RELEASE.*\+${APPSTORE_VERSIONCODE}$" -n 1
```

- Take the SHA from the single match.
- **If zero matches:** stop and ask the user to paste the anchor commit SHA directly. Do **not** silently fall back to "latest RELEASE commit" — that defeats the purpose of this anchor.

Capture the SHA and ISO timestamp:

```
git log -1 --format="%H %aI" <sha>
```

Use the ISO timestamp as `$LAST_RELEASE_DATE` for the other repos.

#### 2b. Commits since the anchor

Run in parallel:

```
# ai-chat
git log --oneline <sha>..HEAD

# ai-chat-api
git -C D:/wamp64/www/ai-chat-api log --oneline --since="$LAST_RELEASE_DATE"

# ai-chat-data-server
git -C D:/GIT/Intern/ai-chat-data-server log --oneline --since="$LAST_RELEASE_DATE"
```

#### 2c. Uncommitted work in all three repos

```
git -C $CLAUDE_PROJECT_DIR status --short
git -C $CLAUDE_PROJECT_DIR diff --stat

git -C D:/wamp64/www/ai-chat-api status --short
git -C D:/wamp64/www/ai-chat-api diff --stat

git -C D:/GIT/Intern/ai-chat-data-server status --short
git -C D:/GIT/Intern/ai-chat-data-server diff --stat
```

#### 2d. Synthesize

Combine all three sources into ONE user-facing release note. Backend/data-server commits often map to user-visible behavior — translate them into user language (e.g. "transcription is faster" — not "switched to whisper-large-v3"). Drop pure refactors, lint fixes, version bumps, dependency churn, and internal infra.

If there are zero meaningful user-facing changes across all sources, ask the user whether they want to ship with a minor "Improvements and bug fixes" note or hold the release.

### 3. Create the Release Notes Subdirectory

Folder name: `static/release-notes/<semver>_<buildNumber>/`

Example: `static/release-notes/1.0.3_1638/`

Legacy folders named with just the build number (e.g. `1407`) are still supported by the loader for backward compatibility, but **new** folders must use the `<semver>_<build>` format.

### 4. Create the `en.json` File

```json
{
  "_hint_": "If the language has a formal and an informal way. Then use the informal way.",
  "_hint_2_": "All texts are for a AI chat app. So the translations should be adjusted to this genre. Example: Home in english should be translated to Start in german since a translation like Zuhause doesnt make sense for an app like this",
  "_hint_3_": "SUMMERA and SUMMERA AI are brand names and should not be translated",
  "_hint_text": "Maximum length is 400 characters; if it's too long, you must shorten it, even if that means not adhering 100% to the original language. Count the characters afterwards and adjust the length if its still too long.",
  "text": "Your release notes here"
}
```

**Writing Guidelines:**
- Use **informal tone** (conversational, friendly)
- Write for **end users** (no technical jargon)
- Maximum **400 characters**
- Structure with sections when there are multiple changes:
  - `New:` for new features
  - `Improved:` for enhancements
  - `Fixed:` for bug fixes
- Focus on **user benefits**, not internal implementation
- Be brief and clear

**Examples:**

Single change:
```
New: Quick filter bar to search files by name. Type multiple words separated by space to narrow down results.
```

Multiple changes:
```
New: Quick filter bar with multi-word search
Improved: Lock button to keep filter active when navigating
Fixed: Filter bar positioning on devices with navigation bar
```

### 5. Important Reminders

- **Only create `en.json`** — other languages are produced by `tools/translator_app-release-notes.bat` after the fact.
- Focus on changes visible to end users, not internal refactors.
- Check the release notes *immediately before* the current ones in `static/release-notes/` so you don't repeat features that were already announced.
- The in-app "What's New" screen displays the folder as `Version <semver> (<buildNumber>)` — make sure both halves of the folder name are correct.
- Folder format reference and rendering details live in `docs/frontend/WHATS_NEW.md`.
