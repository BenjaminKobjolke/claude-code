# Release-notes recipe — <STACK NAME>

Skeleton for adding a per-stack recipe consumed by `/release:create-release-notes`.
Copy to `<lang>_setup_files/CREATE_RELEASE_NOTES.md` and fill the `<...>`. Keep it
out of `commands/` so it does not register as a slash-command. **The project's own
`docs/CREATE_NEW_RELEASE.md` always wins** where it disagrees with this default.

**Detect this stack:** <root marker file, e.g. `Cargo.toml` / `go.mod` / `pom.xml`>.

---

## 1. Next version & build number

- Where the version lives and how to read/bump it: <...>
- Where the build number lives and how to get/increment it: <...>
- Resulting folder label format (e.g. `<version>_<build>`): <...>

## 2. Find changes since last release

- What anchors "last release" (git tag, store metadata, newest notes folder): <...>
- Commands to list commits + uncommitted work since the anchor: <...>
- Extra repos that ship together (if any): <...>

## 3. Release-notes subdirectory

- Path + folder-name format: <...>

## 4. `en.json` schema

- The exact JSON shape, and **which key holds the actual note text**: <...>
- Translator hints (`_hint_*`) if the translator reads them: <...>

```json
{ }
```

## 5. Reminders

- **Only create `en.json`** — translations come from <translator bat>.
- Where the in-app release-notes view lives and how it renders: <...>
- Doc reference: `docs/CREATE_NEW_RELEASE.md`.
