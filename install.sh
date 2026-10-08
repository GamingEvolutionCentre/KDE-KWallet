#!/usr/bin/env bash

set -euo pipefail

PROJECT_NAME="KDE-KWallet"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/Open-KWallet.sh"
SOURCE_DESKTOP="$SCRIPT_DIR/open-kwallet.desktop"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
AUTOSTART_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
DEST_SCRIPT="$BIN_DIR/Open-KWallet.sh"
DEST_DESKTOP="$AUTOSTART_DIR/open-kwallet.desktop"

fail() {
    printf '%s\n' "ERROR: $*" >&2
    exit 1
}

if [[ "$(uname -s)" != "Linux" ]]; then
    fail "$PROJECT_NAME supports Linux only."
fi

[[ -f "$SOURCE_SCRIPT" ]] || fail "Missing $SOURCE_SCRIPT"
[[ -f "$SOURCE_DESKTOP" ]] || fail "Missing $SOURCE_DESKTOP"

if ! command -v bash >/dev/null 2>&1; then
    fail "bash is required."
fi

QDBUS_FOUND=""
for candidate in qdbus6 qdbus-qt6 qdbus; do
    if command -v "$candidate" >/dev/null 2>&1; then
        QDBUS_FOUND="$candidate"
        break
    fi
done

if [[ -z "$QDBUS_FOUND" ]]; then
    cat >&2 <<'MSG'
WARNING: No qdbus command was found.
Install your distribution's Qt D-Bus command-line tools so one of these commands exists:
  qdbus6, qdbus-qt6, or qdbus

The files will still be installed, but KWallet cannot be opened until qdbus is available.
MSG
else
    printf 'Found D-Bus client: %s\n' "$QDBUS_FOUND"
fi

mkdir -p "$BIN_DIR" "$AUTOSTART_DIR"
cp -- "$SOURCE_SCRIPT" "$DEST_SCRIPT"
chmod 755 "$DEST_SCRIPT"

TMP_DESKTOP="$(mktemp)"
trap 'rm -f -- "$TMP_DESKTOP"' EXIT

sed \
    -e 's/\r$//' \
    -e "s|^Exec=.*$|Exec=$DEST_SCRIPT|" \
    "$SOURCE_DESKTOP" > "$TMP_DESKTOP"

cp -- "$TMP_DESKTOP" "$DEST_DESKTOP"
chmod 644 "$DEST_DESKTOP"

printf '\n%s installed successfully.\n' "$PROJECT_NAME"
printf 'Launcher:  %s\n' "$DEST_SCRIPT"
printf 'Autostart: %s\n' "$DEST_DESKTOP"
printf '\nLog out and back in to Plasma, or run:\n  %q\n' "$DEST_SCRIPT"
