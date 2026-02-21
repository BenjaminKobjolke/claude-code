# JSON-Native Install/Uninstall for Status Line

## Problem

The current install/uninstall scripts use regex to patch `settings.json`, with a fallback to JSON conversion if regex fails. This is over-engineered and error-prone — edge cases in regex matching can corrupt the file.

## Solution

Replace regex-based patching with pure JSON operations: parse, modify object, serialize. Use `diff -w` for the preview to suppress indentation-only changes caused by the serializer normalizing to 2-space indent.

## Phase 0: Gate — Verify `diff -w`

Before any implementation, verify that `diff -w` and `git diff -w` suppress whitespace and indentation-only changes:

1. Create two temp JSON files with identical content but different indentation
2. `diff -w` must show zero output (exit 0)
3. `git diff --no-index -w` must show zero output (exit 0)
4. Add a real content change, re-run — must show only the content change
5. **If any test fails: STOP. Do not proceed.**

## Design

### Install flow (both platforms)

1. Parse snippet `settings.json` — extract `statusLine` object
2. Parse user `settings.json` (or create `{}`)
3. Check if already up to date — skip if so
4. Merge: `data["statusLine"] = snippet["statusLine"]`
5. Serialize to 2-space indented JSON + trailing newline
6. Write to `.tmp` file
7. Post-write validation: re-read `.tmp`, parse, verify `statusLine` matches
8. Show `diff -w` preview (git diff preferred, fallback to diff)
9. Confirm with user
10. Backup rotation — move `.tmp` to `settings.json`

### Uninstall flow (both platforms)

1. Parse user `settings.json` — check `statusLine` key exists
2. Delete `data["statusLine"]`
3. Serialize to 2-space indented JSON + trailing newline
4. Write to `.tmp` file
5. Post-write validation: re-read `.tmp`, parse, verify `statusLine` absent
6. Show `diff -w` preview
7. Confirm with user
8. Backup rotation — move `.tmp` to `settings.json`

### Diff preview

- Primary: `git diff --no-index --no-color -w -U2 <old> <new>`
- Fallback (mac, no git): `diff -w <old> <new>` with custom formatting
- Must show ONLY visible character changes, never whitespace/indentation-only diffs

### Post-write validation

After writing `.tmp`, re-read and parse:
- **Install:** verify `statusLine.type` and `statusLine.command` match snippet
- **Uninstall:** verify `statusLine` absent, key count is `original - 1`
- On failure: abort, do not apply changes

### What stays the same

- File copy logic, directory detection/deletion, backup rotation (2 revisions)
- Atomic write via `.tmp` + move
- Setup wizard prompt, current config display, colored diff preview
- "Already up to date" check

### What is removed

- All regex patterns and regex-based patching
- All fallback merge logic
- Raw text extraction of statusLine block from snippet
- Line ending normalization (PowerShell)

### Decisions

- **Indentation:** Always normalize to 2-space indent (JSON standard)
- **Validation:** Post-write re-read to catch I/O failures
- **No regex:** JSON parse/modify/serialize only

## Files affected

- `settings/status-line/win/install.ps1`
- `settings/status-line/win/uninstall.ps1`
- `settings/status-line/mac/install.sh`
- `settings/status-line/mac/uninstall.sh`
