# Release-notes recipe — JavaScript / npm (+ Android)

Per-stack recipe read by the `/release:create-release-notes` command (defined in
`claude-code/commands/release/create-release-notes.md`). It fills in the concrete
commands for an npm app (optionally with an Android/Capacitor build). **The
project's own `docs/CREATE_NEW_RELEASE.md` always wins** where it disagrees with
this default.

Lives here (next to the JavaScript setup files) rather than under `commands/` so it
does not register as a slash-command.

**Detect this stack:** a `package.json` at the project root.

---

## 1. Next version & build number

The `prebuild` hook bumps **both** `package.json` semver patch and Android
`versionCode` on every `npm run build`. So the next AAB ships as
`currentSemver+1patch` / `currentVersionCode+1`.

Next semver (current patch + 1):

```
node -e "const v=require('./package.json').version.split('.');console.log(v[0]+'.'+v[1]+'.'+(+v[2]+1))"
```

Next `versionCode`:

```
tools/build_number_show.bat
```

Directory name → `<nextSemver>_<nextBuildNumber>`, e.g. `1.0.7_1655`.

For a `--no-bump` build (rare) use the current semver as-is (it skips the
package-version bump); `versionCode` always bumps.

## 2. Find changes since last release

Anchor = the versionCode currently **live on the store**, not the latest local
`RELEASE` commit (a locally built version may never have been uploaded).

### 2a-i. Determine `$APPSTORE_VERSIONCODE`

1. If `$CLAUDE_PROJECT_DIR/appstore-versioncode.txt` is **missing**:
   - Ask: *"`appstore-versioncode.txt` is missing. What is the last versionCode uploaded to the appstore?"*
   - Write the integer to `appstore-versioncode.txt` (single line, no trailing whitespace).
2. Read the integer → `$APPSTORE_VERSIONCODE`.

### 2a-ii. Detect stale file

```
git log --oneline --grep="^RELEASE" -n 1
```

Parse the `+<N>` suffix (e.g. `RELEASE (android): 1.1.0+935` → `935`) →
`$LATEST_RELEASE_VERSIONCODE`. If it ≠ `$APPSTORE_VERSIONCODE`:

- Ask: *"Last `RELEASE` commit is `+$LATEST_RELEASE_VERSIONCODE` but `appstore-versioncode.txt` says `$APPSTORE_VERSIONCODE`. Was `+$LATEST_RELEASE_VERSIONCODE` uploaded?"*
- **Yes** → overwrite the file with `$LATEST_RELEASE_VERSIONCODE` and use it.
- **No** → keep the file, continue with the existing value.

### 2a-iii. Anchor commit by versionCode

```
git log --oneline -E --grep="^RELEASE.*\+${APPSTORE_VERSIONCODE}$" -n 1
git log -1 --format="%H %aI" <sha>
```

If zero matches: stop and ask the user to paste the anchor SHA. Do **not** fall
back to "latest RELEASE commit". Use the ISO timestamp as `$LAST_RELEASE_DATE`.

### 2b/2c. Commits + uncommitted work

This project may ship from **multiple repos** (configured in the project doc; the
`ai-chat` example uses `ai-chat`, `ai-chat-api` at `D:/wamp64/www/ai-chat-api`,
`ai-chat-data-server` at `D:/GIT/Intern/ai-chat-data-server`). For each repo:

```
git -C <repo> log --oneline <sha>..HEAD          # this repo: <sha>..HEAD
git -C <repo> log --oneline --since="$LAST_RELEASE_DATE"   # sibling repos
git -C <repo> status --short
git -C <repo> diff --stat
```

## 3. Release-notes subdirectory

`static/release-notes/<semver>_<buildNumber>/`, e.g. `static/release-notes/1.0.3_1638/`.
Legacy build-number-only folders (e.g. `1407`) still load, but new folders must use
`<semver>_<build>`.

## 4. `en.json` schema

```json
{
  "_hint_": "If the language has a formal and an informal way. Then use the informal way.",
  "_hint_2_": "All texts are for a AI chat app. So the translations should be adjusted to this genre. Example: Home in english should be translated to Start in german since a translation like Zuhause doesnt make sense for an app like this",
  "_hint_3_": "SUMMERA and SUMMERA AI are brand names and should not be translated",
  "_hint_text": "Maximum length is 400 characters; if it's too long, you must shorten it, even if that means not adhering 100% to the original language. Count the characters afterwards and adjust the length if its still too long.",
  "text": "Your release notes here"
}
```

The actual note is the single **`text`** field; the `_hint_*` fields steer the
translator (genre, brand glossary, informal tone, 400-char cap). Adjust the genre
/ brand / length hints per project.

## 5. Reminders

- **Only create `en.json`** — other languages come from `tools/translator_app-release-notes.bat`.
- The in-app "What's New" screen shows the folder as `Version <semver> (<buildNumber>)` —
  get both halves right. Rendering details: `docs/frontend/WHATS_NEW.md`.
