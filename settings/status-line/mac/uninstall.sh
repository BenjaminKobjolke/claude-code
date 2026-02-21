#!/bin/bash
# uninstall.sh - Uninstall Claude Code custom status line
set -euo pipefail

pause_exit() {
    echo ""
    read -rp "Press Enter to exit"
    exit "${1:-0}"
}

echo "Uninstalling Claude Code status line..."

# ── Check for python3 ─────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
    echo "  ERROR: python3 is required but not installed."
    echo "  Install it via Xcode Command Line Tools (xcode-select --install) or Homebrew (brew install python3)."
    pause_exit 1
fi

# ── Paths ───────────────────────────────────────────────────────────
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
BACKUP_FILE="$SETTINGS_FILE.bak"
TMP_FILE="$SETTINGS_FILE.tmp"
STATUS_LINE_DIR="$CLAUDE_DIR/settings/status-line"

# ── Cleanup trap ────────────────────────────────────────────────────
cleanup() { rm -f "$TMP_FILE"; }
trap cleanup EXIT

# ── Detect installation ─────────────────────────────────────────────
HAS_KEY="no"
HAS_DIR="no"

if [ -d "$STATUS_LINE_DIR" ]; then
    HAS_DIR="yes"
fi

if [ -f "$SETTINGS_FILE" ]; then
    HAS_KEY=$(python3 -c "
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    data = json.load(f)
print('yes' if 'statusLine' in data else 'no')
" "$SETTINGS_FILE" 2>/dev/null || echo "no")
fi

if [ "$HAS_KEY" = "no" ] && [ "$HAS_DIR" = "no" ]; then
    echo "  Status line is not installed. Nothing to do."
    pause_exit 0
fi

# ── Show what will be removed ────────────────────────────────────────
echo ""
echo "  Found:"
[ "$HAS_KEY" = "yes" ] && echo "    - statusLine key in $SETTINGS_FILE"
[ "$HAS_DIR" = "yes" ] && echo "    - Directory $STATUS_LINE_DIR"
echo ""

# ── Remove statusLine key from settings.json ─────────────────────────
if [ "$HAS_KEY" = "yes" ]; then
    # ── Remove statusLine key via JSON ─────────────────────────────
    python3 -c "
import json, sys

settings_path = sys.argv[1]
tmp_path = sys.argv[2]

with open(settings_path, encoding='utf-8') as f:
    data = json.load(f)

orig_count = len(data)
data.pop('statusLine', None)
patched = json.dumps(data, indent=2) + '\n'

with open(tmp_path, 'w', encoding='utf-8') as f:
    f.write(patched)
" "$SETTINGS_FILE" "$TMP_FILE"

    # ── Validate temp file ─────────────────────────────────────────
    VALID=$(python3 -c "
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    data = json.load(f)
with open(sys.argv[2], encoding='utf-8') as f:
    orig = json.load(f)
print('yes' if 'statusLine' not in data and len(data) == len(orig) - 1 else 'no')
" "$TMP_FILE" "$SETTINGS_FILE" 2>/dev/null || echo "no")

    if [ "$VALID" != "yes" ]; then
        echo "  ERROR: validation failed after writing temp file. Aborting."
        pause_exit 1
    fi

    # ── Show diff ────────────────────────────────────────────────────
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    DIM=$'\033[90m'
    RESET=$'\033[0m'

    echo "  ${DIM}${SETTINGS_FILE}${RESET}"
    echo ""

    if command -v git &>/dev/null; then
        git diff --no-index --no-color -w -U2 "$SETTINGS_FILE" "$TMP_FILE" 2>/dev/null | while IFS= read -r line; do
            case "$line" in
                ---*|+++*|diff*|index*) continue ;;
                @@*)  printf '  %s%s%s\n' "$DIM"   "$line" "$RESET" ;;
                -*)   printf '  %s%s%s\n' "$RED"   "$line" "$RESET" ;;
                +*)   printf '  %s%s%s\n' "$GREEN" "$line" "$RESET" ;;
                *)    printf '  %s%s%s\n' "$DIM"   "$line" "$RESET" ;;
            esac
        done
    else
        diff -w --old-line-format="  ${RED}-%l${RESET}
" --new-line-format="  ${GREEN}+%l${RESET}
" --unchanged-line-format="" "$SETTINGS_FILE" "$TMP_FILE" || true
    fi

    echo ""
    read -rp "  Remove statusLine from settings.json? [Y/n]: " answer
    if [[ "$answer" =~ ^[Nn] ]]; then
        echo "  Skipped. statusLine key was not removed."
    else
        # ── Backup (2-revision rotation) ─────────────────────────────
        rm -f "$BACKUP_FILE.1"
        [ -f "$BACKUP_FILE" ] && mv "$BACKUP_FILE" "$BACKUP_FILE.1"
        cp "$SETTINGS_FILE" "$BACKUP_FILE"
        echo "  Backing up settings.json -> settings.json.bak"

        # ── Apply atomically ─────────────────────────────────────────
        mv "$TMP_FILE" "$SETTINGS_FILE"
        echo "  Removed statusLine from settings.json."
    fi
fi

# ── Remove status-line directory ─────────────────────────────────────
if [ "$HAS_DIR" = "yes" ]; then
    echo ""
    read -rp "  Delete $STATUS_LINE_DIR ? [Y/n]: " answer
    if [[ "$answer" =~ ^[Nn] ]]; then
        echo "  Skipped. Directory was not removed."
    else
        if rm -rf "$STATUS_LINE_DIR" 2>/dev/null; then
            echo "  Deleted $STATUS_LINE_DIR"
        else
            echo "  Could not delete $STATUS_LINE_DIR (files may be in use)."
            echo "  Close all Claude Code sessions and try again, or delete it manually."
        fi
    fi
fi

echo ""
echo "Status line uninstalled."

pause_exit 0
