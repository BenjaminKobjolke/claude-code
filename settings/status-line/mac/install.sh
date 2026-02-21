#!/bin/bash
# install.sh - Install Claude Code custom status line
set -euo pipefail

pause_exit() {
    echo ""
    read -rp "Press Enter to exit"
    exit "${1:-0}"
}

echo "Installing Claude Code status line..."

# ── Remote fallback URL ──────────────────────────────────────────
REMOTE_BASE='https://raw.githubusercontent.com/BenjaminKobjolke/claude-code/main/settings/status-line/mac'

# ── Check for python3 ─────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
    echo "  ERROR: python3 is required but not installed."
    echo "  Install it via Xcode Command Line Tools (xcode-select --install) or Homebrew (brew install python3)."
    echo "  Alternatively, see the Manual Installation section in the README."
    pause_exit 1
fi

# ── Paths ───────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)" || SCRIPT_DIR=""  # .../mac/ (empty when piped)
SOURCE_ROOT=""
if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/.." ]; then
    SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"    # .../status-line/
fi
CLAUDE_DIR="$HOME/.claude"
SETTINGS_DIR="$CLAUDE_DIR/settings"
TARGET_ROOT="$SETTINGS_DIR/status-line"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
BACKUP_FILE="$SETTINGS_FILE.bak"
TMP_FILE="$SETTINGS_FILE.tmp"

# ── Ensure .claude directory exists ─────────────────────────────────
mkdir -p "$CLAUDE_DIR"

# ── Cleanup trap ────────────────────────────────────────────────────
cleanup() { rm -f "$TMP_FILE"; }
trap cleanup EXIT

# ── Copy files (skip if already inside .claude) ─────────────────────
COMPANION_FILES="install.sh status-line.sh setup.sh uninstall.sh settings.json"
MAC_TARGET="$TARGET_ROOT/mac"

if [ -n "$SOURCE_ROOT" ] && [ -d "$SOURCE_ROOT" ]; then
    case "$SOURCE_ROOT" in
        "$CLAUDE_DIR"/*)
            echo "  Files already in .claude directory, skipping copy."
            ;;
        *)
            echo "  Copying files to $TARGET_ROOT"
            mkdir -p "$TARGET_ROOT"
            cp -R "$SOURCE_ROOT/"* "$TARGET_ROOT/"
            ;;
    esac
else
    echo "  Downloading files from remote repository..."
    mkdir -p "$MAC_TARGET"
    failed=""
    for file in $COMPANION_FILES; do
        url="$REMOTE_BASE/$file"
        dest="$MAC_TARGET/$file"
        if curl -fsSL "$url" -o "$dest" 2>/dev/null; then
            echo "    Downloaded $file"
        else
            echo "    WARNING: Failed to download $file from $url"
            failed="$failed $file"
        fi
    done
    if [ -n "$failed" ]; then
        echo "  ERROR: Failed to download:$failed. Aborting."
        pause_exit 1
    fi
fi

# Ensure scripts are executable
chmod +x "$MAC_TARGET/status-line.sh" "$MAC_TARGET/setup.sh" "$MAC_TARGET/install.sh" "$MAC_TARGET/uninstall.sh" 2>/dev/null || true

# Resolve target setup.sh path (for wizard prompt later)
TARGET_SETUP="$TARGET_ROOT/mac/setup.sh"

# ── Read statusLine value from bundled settings.json ────────────────
SNIPPET_FILE="$TARGET_ROOT/mac/settings.json"
[ -f "$SNIPPET_FILE" ] || { [ -n "$SCRIPT_DIR" ] && SNIPPET_FILE="$SCRIPT_DIR/settings.json"; }
if [ ! -f "$SNIPPET_FILE" ]; then
    echo "  ERROR: settings.json not found locally or from download. Aborting."
    pause_exit 1
fi
if ! python3 -c "import json,sys; json.load(open(sys.argv[1],encoding='utf-8'))" "$SNIPPET_FILE" 2>/dev/null; then
    echo "  ERROR: settings.json snippet is not valid JSON. Aborting."
    pause_exit 1
fi

# ── Read or initialize settings.json ────────────────────────────────
if [ -f "$SETTINGS_FILE" ]; then
    if ! python3 -c "import json,sys; json.load(open(sys.argv[1],encoding='utf-8'))" "$SETTINGS_FILE" 2>/dev/null; then
        echo "  ERROR: settings.json is not valid JSON. Aborting."
        pause_exit 1
    fi
else
    echo "  Creating new settings.json"
    printf '{}\n' > "$SETTINGS_FILE"
fi

# ── Check if already up to date ───────────────────────────────────
ALREADY_SET=$(python3 -c "
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    data = json.load(f)
with open(sys.argv[2], encoding='utf-8') as f:
    snippet = json.load(f)
sl = data.get('statusLine', {})
expected = snippet.get('statusLine', {})
print('yes' if sl == expected else 'no')
" "$SETTINGS_FILE" "$SNIPPET_FILE" 2>/dev/null || echo "no")

if [ "$ALREADY_SET" = "yes" ]; then
    echo "  $SETTINGS_FILE already up to date."
else
    # ── Merge: set statusLine key ──────────────────────────────────
    python3 -c "
import json, sys

settings_path = sys.argv[1]
tmp_path = sys.argv[2]
snippet_path = sys.argv[3]

with open(settings_path, encoding='utf-8') as f:
    data = json.load(f)
with open(snippet_path, encoding='utf-8') as f:
    snippet = json.load(f)

data['statusLine'] = snippet['statusLine']
patched = json.dumps(data, indent=2) + '\n'

with open(tmp_path, 'w', encoding='utf-8') as f:
    f.write(patched)
" "$SETTINGS_FILE" "$TMP_FILE" "$SNIPPET_FILE"

    # ── Validate temp file ─────────────────────────────────────────
    VALID=$(python3 -c "
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    data = json.load(f)
with open(sys.argv[2], encoding='utf-8') as f:
    snippet = json.load(f)
sl = data.get('statusLine', {})
expected = snippet.get('statusLine', {})
print('yes' if sl == expected else 'no')
" "$TMP_FILE" "$SNIPPET_FILE" 2>/dev/null || echo "no")

    if [ "$VALID" != "yes" ]; then
        echo "  ERROR: validation failed after writing temp file. Aborting."
        pause_exit 1
    fi

    # ── Show diff and confirm ──────────────────────────────────────
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    DIM=$'\033[90m'
    RESET=$'\033[0m'

    echo ""
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
    read -rp "  Apply changes? [Y/n]: " answer
    if [[ "$answer" =~ ^[Nn] ]]; then
        echo "  Skipped. No changes made to settings.json."
        pause_exit 0
    fi

    # ── Backup (2-revision rotation) ────────────────────────────────
    rm -f "$BACKUP_FILE.1"
    [ -f "$BACKUP_FILE" ] && mv "$BACKUP_FILE" "$BACKUP_FILE.1"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo "  Backing up settings.json -> settings.json.bak"

    # ── Apply ───────────────────────────────────────────────────────
    mv "$TMP_FILE" "$SETTINGS_FILE"
    echo "  Done!"
fi

# ── Read current config from status-line.sh ──────────────────────
SL_SCRIPT="$TARGET_ROOT/mac/status-line.sh"
cfg_bar_width=10; cfg_color=dynamic; cfg_filled_char=""
cfg_output_line=""
if [ -f "$SL_SCRIPT" ]; then
    cfg_bar_width=$(grep -oP 'CFG_BAR_WIDTH=\K\d+' "$SL_SCRIPT" 2>/dev/null || echo 10)
    cfg_color=$(grep -oP 'CFG_FILLED_COLOR=\K\S+' "$SL_SCRIPT" 2>/dev/null || echo dynamic)
    cfg_filled_char=$(grep -oP 'CFG_FILLED_CHAR=\K.*' "$SL_SCRIPT" 2>/dev/null || echo "")
    cfg_output_line=$(sed -n '/^cfg_output()/,/^}/{ /printf/p; }' "$SL_SCRIPT" 2>/dev/null || echo "")
fi

case "$cfg_color" in
    dynamic) color_name="Dynamic (green/yellow/red)" ;; 32) color_name="Green" ;; 36) color_name="Cyan" ;; 33) color_name="Yellow" ;; 37) color_name="White" ;;
    *)  color_name="ANSI $cfg_color" ;;
esac

case "$cfg_filled_char" in
    *96*88*) style_name="Block" ;; *96*93*) style_name="Shade" ;; *"="*) style_name="ASCII" ;;
    *)       style_name="Custom" ;;
esac

# Detect layout from cfg_output printf argument order
if echo "$cfg_output_line" | grep -q 'model_name.*progress_bar'; then
    layout_name="Model, Context Progress Bar, Context %, Tokens Used, Cost, Duration"
elif echo "$cfg_output_line" | grep -q 'duration.*model_name'; then
    layout_name="Context Progress Bar, Context %, Tokens Used, Cost, Duration, Model"
elif echo "$cfg_output_line" | grep -q 'cost_str.*model_name' && ! echo "$cfg_output_line" | grep -q 'duration'; then
    if echo "$cfg_output_line" | grep -q 'max_str'; then
        layout_name="Context Progress Bar, Context %, Tokens Used, Cost, Model"
    else
        layout_name="Context Progress Bar, Context %, Cost, Model"
    fi
elif ! echo "$cfg_output_line" | grep -q 'cost_str\|model_name\|duration'; then
    layout_name="Context Progress Bar, Context %"
else
    layout_name="Context Progress Bar, Context %, Tokens Used, Cost, Duration, Model"
fi

# ── Optional: run setup wizard ─────────────────────────────────────
echo ""
echo "  Current settings:"
echo "    Layout:    $layout_name"
echo "    Bar width: $cfg_bar_width"
echo "    Bar style: $style_name"
echo "    Bar color: $color_name"
echo ""
read -rp "  Customize these settings? [y/N]: " run_setup
if [[ "$run_setup" =~ ^[Yy] ]]; then
    bash "$TARGET_SETUP" --from-install
fi

echo ""
echo "Status line installed. Open a new Claude Code session to see it."

pause_exit 0
