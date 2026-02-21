#!/bin/bash
# install.sh - Interactive setting installer launcher (macOS)
# Discovers available settings from remote repo, presents selection menu,
# downloads and runs the chosen setting's installer interactively.
set -euo pipefail

SETTING_NAME="${1:-}"
REPO='BenjaminKobjolke/claude-code'
BRANCH='main'
DIR='settings'
REPO_API="https://api.github.com/repos/$REPO/contents/$DIR?ref=$BRANCH"
REPO_RAW="https://raw.githubusercontent.com/$REPO/$BRANCH/$DIR"

# ── Check dependencies ───────────────────────────────────────────
if ! command -v curl &>/dev/null; then
    echo "ERROR: curl is required but not installed."
    exit 1
fi
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 is required but not installed."
    echo "  Install via: xcode-select --install  or  brew install python3"
    exit 1
fi

# ── Discover available settings ──────────────────────────────────
echo "Discovering available settings..."
API_RESPONSE=$(curl -fsSL "$REPO_API") || {
    echo "ERROR: Failed to fetch settings list from GitHub API."
    exit 1
}

SETTINGS=$(echo "$API_RESPONSE" | python3 -c "
import sys, json
entries = json.load(sys.stdin)
dirs = [e['name'] for e in entries if e['type'] == 'dir']
for d in dirs:
    print(d)
") || {
    echo "ERROR: Failed to parse API response."
    exit 1
}

if [ -z "$SETTINGS" ]; then
    echo "No settings found in the remote repository."
    exit 1
fi

# Convert to array (compatible with Bash 3.2 on macOS)
SETTINGS_ARR=()
while IFS= read -r line; do
    SETTINGS_ARR+=("$line")
done <<< "$SETTINGS"

# ── Select setting ───────────────────────────────────────────────
SELECTED=""

if [ -n "$SETTING_NAME" ]; then
    FOUND=false
    for s in "${SETTINGS_ARR[@]}"; do
        if [ "$s" = "$SETTING_NAME" ]; then
            FOUND=true
            break
        fi
    done
    if $FOUND; then
        SELECTED="$SETTING_NAME"
    else
        echo "ERROR: Setting '$SETTING_NAME' not found."
        echo ""
        echo "Available settings:"
        for s in "${SETTINGS_ARR[@]}"; do
            echo "  - $s"
        done
        exit 1
    fi
else
    echo ""
    echo "Available settings:"
    for i in "${!SETTINGS_ARR[@]}"; do
        echo "  [$((i + 1))] ${SETTINGS_ARR[$i]}"
    done
    echo ""
    read -rp "Select a setting to install (1-${#SETTINGS_ARR[@]}): " CHOICE
    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "${#SETTINGS_ARR[@]}" ]; then
        echo "Invalid selection."
        exit 1
    fi
    SELECTED="${SETTINGS_ARR[$((CHOICE - 1))]}"
fi

echo ""
echo "Installing '$SELECTED'..."

# ── Download installer to temp ───────────────────────────────────
URL="$REPO_RAW/$SELECTED/mac/install.sh"
TEMP_DIR="/tmp/claude-setting-launcher-$SELECTED"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
TEMP_FILE="$TEMP_DIR/install.sh"

cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

curl -fsSL "$URL" -o "$TEMP_FILE" || {
    echo "ERROR: Failed to download installer from:"
    echo "  $URL"
    exit 1
}

if [ ! -s "$TEMP_FILE" ]; then
    echo "ERROR: Downloaded installer is empty or missing."
    exit 1
fi

chmod +x "$TEMP_FILE"

# ── Run interactively ────────────────────────────────────────────
rc=0
bash "$TEMP_FILE" || rc=$?
exit $rc
