#!/usr/bin/bash

set -euo pipefail

# ============================================================
# KDE KWallet Auto Open Installer
# openSUSE edition - keeps the same install flow as the Fedora version
# ============================================================

RESET=$'\033[0m'
BOLD=$'\033[1m'
RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
MAGENTA=$'\033[1;35m'
CYAN=$'\033[1;36m'
WHITE=$'\033[1;37m'
ORANGE=$'\033[1;38;5;208m'
GREY=$'\033[38;5;245m'

UI_WIDTH=88
TERMINAL_WIDTH=80
CONTENT_WIDTH=80
LEFT_PADDING=0
TUI_ACTIVE=false
TEMP_DESKTOP=""

update_ui_layout() {
    local detected_width
    detected_width="$(tput cols 2>/dev/null || printf '80')"
    if [[ "$detected_width" =~ ^[0-9]+$ ]]; then
        TERMINAL_WIDTH="$detected_width"
    else
        TERMINAL_WIDTH=80
    fi
    (( TERMINAL_WIDTH < 40 )) && TERMINAL_WIDTH=40
    if (( UI_WIDTH >= TERMINAL_WIDTH )); then
        CONTENT_WIDTH=$(( TERMINAL_WIDTH - 4 ))
    else
        CONTENT_WIDTH="$UI_WIDTH"
    fi
    LEFT_PADDING=$(( (TERMINAL_WIDTH - CONTENT_WIDTH) / 2 ))
    (( LEFT_PADDING < 0 )) && LEFT_PADDING=0
}

repeat_character() {
    local character="$1" count="$2" result
    printf -v result '%*s' "$count" ''
    result="${result// /$character}"
    printf '%s' "$result"
}

ui_center_text() {
    local text="$1" colour="${2:-$WHITE}" padding
    update_ui_layout
    padding=$(( (TERMINAL_WIDTH - ${#text}) / 2 ))
    (( padding < 0 )) && padding=0
    printf '%*s%b%s%b\n' "$padding" '' "$colour" "$text" "$RESET"
}

ui_center_line() {
    local character="$1" colour="$2"
    update_ui_layout
    printf '%*s%b' "$LEFT_PADDING" '' "$colour"
    repeat_character "$character" "$CONTENT_WIDTH"
    printf '%b\n' "$RESET"
}

ui_status() {
    local label="$1" colour="$2" message="$3"
    update_ui_layout
    printf '%*s%b%-11s%b %s\n' "$(( LEFT_PADDING + 2 ))" '' "$colour" "[$label]" "$RESET" "$message"
}

ui_path() {
    local label="$1" path="$2"
    update_ui_layout
    printf '%*s%b%-13s%b %b%s%b\n' "$(( LEFT_PADDING + 2 ))" '' "$WHITE$BOLD" "$label" "$RESET" "$CYAN" "$path" "$RESET"
}

ui_title() {
    echo
    ui_center_line "═" "$CYAN"
    echo
    ui_center_text "$1" "$WHITE$BOLD"
    ui_center_text "KDE Plasma • KWallet • Automatic Unlock" "$GREY"
    echo
    ui_center_line "═" "$CYAN"
    echo
}

ui_section() {
    echo
    ui_center_line "─" "$MAGENTA"
    ui_center_text "$1" "$WHITE$BOLD"
    ui_center_line "─" "$MAGENTA"
    echo
}

ui_ok()      { ui_status "OK" "$GREEN" "$*"; }
ui_error()   { ui_status "ERROR" "$RED" "$*" >&2; }
ui_warning() { ui_status "WARNING" "$ORANGE" "$*"; }
ui_missing() { ui_status "MISSING" "$ORANGE" "$*"; }
ui_info()    { ui_status "INFO" "$CYAN" "$*"; }
ui_skip()    { ui_status "SKIP" "$GREY" "$*"; }

ui_success_title() {
    echo
    ui_center_line "═" "$GREEN"
    echo
    ui_center_text "✓  $1  ✓" "$GREEN$BOLD"
    echo
    ui_center_line "═" "$GREEN"
    echo
}

enter_terminal_ui() {
    if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
        if tput smcup 2>/dev/null; then
            TUI_ACTIVE=true
            tput clear 2>/dev/null || true
            tput home 2>/dev/null || true
            tput cnorm 2>/dev/null || true
        fi
    else
        clear 2>/dev/null || true
    fi
    update_ui_layout
}

clear_terminal_ui() {
    if command -v tput >/dev/null 2>&1; then
        tput clear 2>/dev/null || true
        tput home 2>/dev/null || true
    else
        clear 2>/dev/null || true
    fi
    update_ui_layout
}

restore_terminal() {
    printf '%b' "$RESET"
    if [[ "$TUI_ACTIVE" == true ]] && command -v tput >/dev/null 2>&1; then
        tput cnorm 2>/dev/null || true
        tput rmcup 2>/dev/null || true
        TUI_ACTIVE=false
    fi
}

cleanup() {
    if [[ -n "$TEMP_DESKTOP" && -f "$TEMP_DESKTOP" ]]; then
        rm -f -- "$TEMP_DESKTOP" || true
    fi
    restore_terminal
}
trap cleanup EXIT

wait_for_exit_to_terminal() {
    echo
    ui_center_line "─" "$GREY"
    echo
    echo
    ui_center_text "Press Enter to return to your terminal..." "$ORANGE$BOLD"
    echo
    IFS= read -r </dev/tty
}

# ============================================================
# Required Packages — openSUSE
# ============================================================

REQUIRED_PACKAGES=(
    bash
    plasma6-workspace
    kwalletd6
    pam_kwallet6
    sddm
    qt6-tools-qdbus
)

check_and_install_packages() {
    ui_section "Required Packages"

    command -v rpm >/dev/null 2>&1 || {
        ui_error "rpm was not found. This package is intended for openSUSE."
        exit 1
    }

    command -v zypper >/dev/null 2>&1 || {
        ui_error "zypper was not found. This package is intended for openSUSE."
        exit 1
    }

    local missing_packages=()
    local package

    for package in "${REQUIRED_PACKAGES[@]}"; do
        if rpm -q "$package" >/dev/null 2>&1; then
            ui_ok "$package"
        else
            ui_missing "$package"
            missing_packages+=("$package")
        fi
    done

    if (( ${#missing_packages[@]} > 0 )); then
        echo
        ui_warning "Some required packages are missing."
        echo
        for package in "${missing_packages[@]}"; do
            ui_center_text "• $package" "$ORANGE"
        done
        echo
        ui_info "Installing missing packages with Zypper..."
        echo
        sudo zypper --non-interactive install "${missing_packages[@]}"
        echo
        ui_ok "All missing packages have been installed."
    else
        echo
        ui_ok "All required packages are already installed."
    fi
}

# ============================================================
# Determine Paths
# ============================================================

USER_HOME="$HOME"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/Open-KWallet.sh"
SOURCE_DESKTOP="$SCRIPT_DIR/open-kwallet.desktop"
BIN_DIR="$USER_HOME/.local/bin"
AUTOSTART_DIR="$USER_HOME/.config/autostart"
DEST_SCRIPT="$BIN_DIR/Open-KWallet.sh"
DEST_DESKTOP="$AUTOSTART_DIR/open-kwallet.desktop"

show_installation_paths() {
    ui_section "Installation Information"
    ui_path "User" "${USER:-$(id -un)}"
    echo
    ui_path "Home" "$USER_HOME"
    echo
    ui_path "Source" "$SCRIPT_DIR"
    echo
    ui_path "Script" "$DEST_SCRIPT"
    echo
    ui_path "Autostart" "$DEST_DESKTOP"
}

check_source_files() {
    ui_section "Repository Files"
    if [[ ! -f "$SOURCE_SCRIPT" ]]; then
        ui_error "Open-KWallet.sh was not found."
        echo
        ui_path "Expected" "$SOURCE_SCRIPT"
        exit 1
    fi
    ui_ok "Open-KWallet.sh found"

    if [[ ! -f "$SOURCE_DESKTOP" ]]; then
        ui_error "open-kwallet.desktop was not found."
        echo
        ui_path "Expected" "$SOURCE_DESKTOP"
        exit 1
    fi
    ui_ok "open-kwallet.desktop found"
}

install_files() {
    ui_section "Installing Files"
    ui_info "Creating installation directories..."
    mkdir -p "$BIN_DIR" "$AUTOSTART_DIR"
    ui_ok "Installation directories ready"
    echo

    ui_info "Installing Open-KWallet.sh"
    ui_path "Destination" "$DEST_SCRIPT"
    install -m 755 "$SOURCE_SCRIPT" "$DEST_SCRIPT"
    ui_ok "Open-KWallet.sh installed"
    echo

    ui_info "Preparing Plasma autostart entry..."
    TEMP_DESKTOP="$(mktemp)"
    sed -e 's/\r$//' -e "s|__OPEN_KWALLET_SCRIPT__|$DEST_SCRIPT|g" "$SOURCE_DESKTOP" > "$TEMP_DESKTOP"

    if grep -q '^Exec=' "$TEMP_DESKTOP"; then
        sed -i "s|^Exec=.*$|Exec=$DEST_SCRIPT|" "$TEMP_DESKTOP"
    else
        ui_error "open-kwallet.desktop does not contain an Exec= line."
        exit 1
    fi

    install -m 644 "$TEMP_DESKTOP" "$DEST_DESKTOP"
    rm -f -- "$TEMP_DESKTOP"
    TEMP_DESKTOP=""
    ui_ok "Plasma autostart entry installed"
    echo

    ui_info "Starting Open-KWallet.sh..."
    "$DEST_SCRIPT"
    ui_ok "Open-KWallet.sh executed successfully"
}

verify_installation() {
    ui_section "Verification"

    [[ -f "$DEST_SCRIPT" ]] || { ui_error "Open-KWallet.sh was not installed."; exit 1; }
    ui_ok "Open-KWallet.sh exists"

    [[ -x "$DEST_SCRIPT" ]] || { ui_error "Open-KWallet.sh is not executable."; exit 1; }
    ui_ok "Open-KWallet.sh is executable"

    [[ -f "$DEST_DESKTOP" ]] || { ui_error "Autostart entry was not installed."; exit 1; }
    ui_ok "open-kwallet.desktop exists"

    local expected_exec actual_exec
    expected_exec="$DEST_SCRIPT"
    actual_exec="$(sed -n 's/^Exec=//p' "$DEST_DESKTOP" | head -n 1 | tr -d '\r')"
    if [[ "$actual_exec" != "$expected_exec" ]]; then
        ui_error "Autostart Exec path is incorrect."
        echo
        ui_path "Expected" "Exec=$expected_exec"
        echo
        ui_path "Found" "Exec=$actual_exec"
        exit 1
    fi
    ui_ok "Autostart Exec path is correct"

    if command -v desktop-file-validate >/dev/null 2>&1; then
        if desktop-file-validate "$DEST_DESKTOP"; then
            ui_ok "Desktop file syntax is valid"
        else
            ui_warning "desktop-file-validate reported a problem."
        fi
    else
        ui_skip "Desktop file validation unavailable"
    fi
}

show_completion() {
    clear_terminal_ui
    ui_success_title "Installation Complete"
    ui_center_text "KWallet Auto Open has been installed successfully." "$GREEN$BOLD"
    echo
    echo
    ui_center_line "─" "$GREY"
    echo
    ui_center_text "Installed Script" "$WHITE$BOLD"
    ui_center_text "$DEST_SCRIPT" "$CYAN"
    echo
    echo
    ui_center_text "Plasma Autostart Entry" "$WHITE$BOLD"
    ui_center_text "$DEST_DESKTOP" "$CYAN"
    echo
    echo
    ui_center_text "Exec Path" "$WHITE$BOLD"
    ui_center_text "$DEST_SCRIPT" "$CYAN"
    echo
    ui_center_line "─" "$GREY"
    echo
    echo
    ui_center_text "✓ Ready to use" "$GREEN$BOLD"
}

main() {
    enter_terminal_ui
    ui_title "KDE KWallet Auto Open Installer"
    check_and_install_packages
    show_installation_paths
    check_source_files
    install_files
    verify_installation
    show_completion
    wait_for_exit_to_terminal
}

main "$@"
restore_terminal
trap - EXIT
exit 0
