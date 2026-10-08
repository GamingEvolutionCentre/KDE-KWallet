#!/usr/bin/env bash

set -euo pipefail

BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
AUTOSTART_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
DEST_SCRIPT="$BIN_DIR/Open-KWallet.sh"
DEST_DESKTOP="$AUTOSTART_DIR/open-kwallet.desktop"

removed=false

if [[ -f "$DEST_DESKTOP" ]]; then
    rm -f -- "$DEST_DESKTOP"
    printf 'Removed %s\n' "$DEST_DESKTOP"
    removed=true
fi

if [[ -f "$DEST_SCRIPT" ]]; then
    rm -f -- "$DEST_SCRIPT"
    printf 'Removed %s\n' "$DEST_SCRIPT"
    removed=true
fi

if [[ "$removed" == false ]]; then
    printf 'KDE-KWallet user files were not installed, or were already removed.\n'
else
    printf 'KDE-KWallet uninstalled. System KWallet/Plasma packages were left untouched.\n'
fi
