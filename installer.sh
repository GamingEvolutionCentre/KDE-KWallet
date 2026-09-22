#!/usr/bin/bash

set -euo pipefail

# ============================================================
# KDE KWallet Auto Open Installer
# ============================================================


# ============================================================
# Colours
# ============================================================

RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'

RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[1;34m'
MAGENTA=$'\033[1;35m'
CYAN=$'\033[1;36m'
WHITE=$'\033[1;37m'
ORANGE=$'\033[1;38;5;208m'
GREY=$'\033[38;5;245m'


# ============================================================
# Terminal UI Layout
# ============================================================

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

    # Prevent bad layouts on very small terminals.
    if (( TERMINAL_WIDTH < 40 )); then
        TERMINAL_WIDTH=40
    fi

    # Automatically shrink the UI if required.
    if (( UI_WIDTH >= TERMINAL_WIDTH )); then
        CONTENT_WIDTH=$(( TERMINAL_WIDTH - 4 ))
    else
        CONTENT_WIDTH="$UI_WIDTH"
    fi

    # Centre the UI block on screen.
    LEFT_PADDING=$(( (TERMINAL_WIDTH - CONTENT_WIDTH) / 2 ))

    if (( LEFT_PADDING < 0 )); then
        LEFT_PADDING=0
    fi
}


# ============================================================
# UI Helpers
# ============================================================

repeat_character() {
    local character="$1"
    local count="$2"
    local result

    printf -v result '%*s' "$count" ''
    result="${result// /$character}"

    printf '%s' "$result"
}


ui_center_text() {
    local text="$1"
    local colour="${2:-$WHITE}"

    local text_length
    local padding

    update_ui_layout

    text_length=${#text}
    padding=$(( (TERMINAL_WIDTH - text_length) / 2 ))

    if (( padding < 0 )); then
        padding=0
    fi

    printf '%*s%b%s%b\n' \
        "$padding" \
        '' \
        "$colour" \
        "$text" \
        "$RESET"
}


ui_center_line() {
    local character="$1"
    local colour="$2"

    update_ui_layout

    printf '%*s%b' \
        "$LEFT_PADDING" \
        '' \
        "$colour"

    repeat_character \
        "$character" \
        "$CONTENT_WIDTH"

    printf '%b\n' "$RESET"
}


ui_status() {
    local label="$1"
    local colour="$2"
    local message="$3"

    update_ui_layout

    printf '%*s%b%-11s%b %s\n' \
        "$(( LEFT_PADDING + 2 ))" \
        '' \
        "$colour" \
        "[$label]" \
        "$RESET" \
        "$message"
}


ui_path() {
    local label="$1"
    local path="$2"

    update_ui_layout

    printf '%*s%b%-13s%b %b%s%b\n' \
        "$(( LEFT_PADDING + 2 ))" \
        '' \
        "$WHITE$BOLD" \
        "$label" \
        "$RESET" \
        "$CYAN" \
        "$path" \
        "$RESET"
}


# ============================================================
# Main Title
# ============================================================

ui_title() {
    local title="$1"

    echo

    ui_center_line "═" "$CYAN"

    echo

    ui_center_text \
        "$title" \
        "$WHITE$BOLD"

    ui_center_text \
        "KDE Plasma • KWallet • Automatic Unlock" \
        "$GREY"

    echo

    ui_center_line "═" "$CYAN"

    echo
}


# ============================================================
# Section Title
# ============================================================

ui_section() {
    local title="$1"

    echo

    ui_center_line "─" "$MAGENTA"

    ui_center_text \
        "$title" \
        "$WHITE$BOLD"

    ui_center_line "─" "$MAGENTA"

    echo
}


# ============================================================
# Status Messages
# ============================================================

ui_ok() {
    ui_status \
        "OK" \
        "$GREEN" \
        "$*"
}


ui_error() {
    ui_status \
        "ERROR" \
        "$RED" \
        "$*" >&2
}


ui_warning() {
    ui_status \
        "WARNING" \
        "$ORANGE" \
        "$*"
}


ui_missing() {
    ui_status \
        "MISSING" \
        "$ORANGE" \
        "$*"
}


ui_info() {
    ui_status \
        "INFO" \
        "$CYAN" \
        "$*"
}


ui_skip() {
    ui_status \
        "SKIP" \
        "$GREY" \
        "$*"
}


# ============================================================
# Success Screen
# ============================================================

ui_success_title() {
    local title="$1"

    echo

    ui_center_line "═" "$GREEN"

    echo

    ui_center_text \
        "✓  $title  ✓" \
        "$GREEN$BOLD"

    echo

    ui_center_line "═" "$GREEN"

    echo
}


# ============================================================
# Alternate Terminal Screen
# ============================================================

enter_terminal_ui() {
    if [[ -t 1 ]] &&
       command -v tput >/dev/null 2>&1; then

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
    # Reset colours.
    printf '%b' "$RESET"

    if [[ "$TUI_ACTIVE" == true ]] &&
       command -v tput >/dev/null 2>&1; then

        # Make sure cursor is visible.
        tput cnorm 2>/dev/null || true

        # Return to original terminal screen.
        tput rmcup 2>/dev/null || true

        TUI_ACTIVE=false
    fi
}


cleanup() {
    # Remove any temporary desktop file left behind.
    if [[ -n "$TEMP_DESKTOP" ]] &&
       [[ -f "$TEMP_DESKTOP" ]]; then

        rm -f -- "$TEMP_DESKTOP" || true
    fi

    restore_terminal
}


# Always restore the original terminal if the installer exits.
trap cleanup EXIT


# ============================================================
# Wait For Enter Before Exiting
# ============================================================

wait_for_exit_to_terminal() {
    echo

    ui_center_line \
        "─" \
        "$GREY"

    echo
    echo

    ui_center_text \
        "Press Enter to return to your terminal..." \
        "$ORANGE$BOLD"

    echo

    # Wait here until Enter is pressed.
    IFS= read -r </dev/tty
}


# ============================================================
# Required Packages
# ============================================================

REQUIRED_PACKAGES=(
    bash
    plasma-workspace
    kwallet
    kwallet-pam
    sddm
    qt6-tools
)


check_and_install_packages() {
    ui_section \
        "Required Packages"

    local missing_packages=()
    local package

    for package in "${REQUIRED_PACKAGES[@]}"; do

        if pacman -Q "$package" >/dev/null 2>&1; then

            ui_ok \
                "$package"

        else

            ui_missing \
                "$package"

            missing_packages+=("$package")

        fi

    done


    if (( ${#missing_packages[@]} > 0 )); then

        echo

        ui_warning \
            "Some required packages are missing."

        echo


        for package in "${missing_packages[@]}"; do

            ui_center_text \
                "• $package" \
                "$ORANGE"

        done


        echo

        ui_info \
            "Installing missing packages with pacman..."

        echo


        sudo pacman \
            -S \
            --needed \
            "${missing_packages[@]}"


        echo

        ui_ok \
            "All missing packages have been installed."

    else

        echo

        ui_ok \
            "All required packages are already installed."

    fi
}


# ============================================================
# Determine Paths
# ============================================================

USER_HOME="$HOME"

SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
    pwd
)"

SOURCE_SCRIPT="$SCRIPT_DIR/Open-KWallet.sh"
SOURCE_DESKTOP="$SCRIPT_DIR/open-kwallet.desktop"

BIN_DIR="$USER_HOME/.local/bin"
AUTOSTART_DIR="$USER_HOME/.config/autostart"

DEST_SCRIPT="$BIN_DIR/Open-KWallet.sh"
DEST_DESKTOP="$AUTOSTART_DIR/open-kwallet.desktop"


show_installation_paths() {
    ui_section \
        "Installation Information"

    ui_path \
        "User" \
        "${USER:-$(id -un)}"

    echo

    ui_path \
        "Home" \
        "$USER_HOME"

    echo

    ui_path \
        "Source" \
        "$SCRIPT_DIR"

    echo

    ui_path \
        "Script" \
        "$DEST_SCRIPT"

    echo

    ui_path \
        "Autostart" \
        "$DEST_DESKTOP"
}


# ============================================================
# Check Repository Files
# ============================================================

check_source_files() {
    ui_section \
        "Repository Files"


    if [[ ! -f "$SOURCE_SCRIPT" ]]; then

        ui_error \
            "Open-KWallet.sh was not found."

        echo

        ui_path \
            "Expected" \
            "$SOURCE_SCRIPT"

        exit 1

    fi


    ui_ok \
        "Open-KWallet.sh found"


    if [[ ! -f "$SOURCE_DESKTOP" ]]; then

        ui_error \
            "open-kwallet.desktop was not found."

        echo

        ui_path \
            "Expected" \
            "$SOURCE_DESKTOP"

        exit 1

    fi


    ui_ok \
        "open-kwallet.desktop found"
}


# ============================================================
# Install Files
# ============================================================

install_files() {
    ui_section \
        "Installing Files"


    # --------------------------------------------------------
    # Create directories
    # --------------------------------------------------------

    ui_info \
        "Creating installation directories..."


    mkdir -p "$BIN_DIR"
    mkdir -p "$AUTOSTART_DIR"


    ui_ok \
        "Installation directories ready"


    echo


    # --------------------------------------------------------
    # Install Open-KWallet.sh
    # --------------------------------------------------------

    ui_info \
        "Installing Open-KWallet.sh"


    ui_path \
        "Destination" \
        "$DEST_SCRIPT"


    install \
        -m 755 \
        "$SOURCE_SCRIPT" \
        "$DEST_SCRIPT"


    ui_ok \
        "Open-KWallet.sh installed"


    echo


    # --------------------------------------------------------
    # Prepare Plasma autostart entry
    # --------------------------------------------------------

    ui_info \
        "Preparing Plasma autostart entry..."


    TEMP_DESKTOP="$(mktemp)"


    sed \
        -e 's/\r$//' \
        -e "s|__OPEN_KWALLET_SCRIPT__|$DEST_SCRIPT|g" \
        "$SOURCE_DESKTOP" > "$TEMP_DESKTOP"


    # --------------------------------------------------------
    # Force Exec path
    # --------------------------------------------------------

    if grep -q '^Exec=' "$TEMP_DESKTOP"; then

        sed \
            -i \
            "s|^Exec=.*$|Exec=$DEST_SCRIPT|" \
            "$TEMP_DESKTOP"

    else

        ui_error \
            "open-kwallet.desktop does not contain an Exec= line."

        exit 1

    fi


    # --------------------------------------------------------
    # Install desktop file
    # --------------------------------------------------------

    install \
        -m 644 \
        "$TEMP_DESKTOP" \
        "$DEST_DESKTOP"


    rm -f -- "$TEMP_DESKTOP"

    TEMP_DESKTOP=""


    ui_ok \
        "Plasma autostart entry installed"


    echo


    # --------------------------------------------------------
    # Run Open-KWallet.sh
    # --------------------------------------------------------

    ui_info \
        "Starting Open-KWallet.sh..."


    "$DEST_SCRIPT"


    ui_ok \
        "Open-KWallet.sh executed successfully"
}


# ============================================================
# Verify Installation
# ============================================================

verify_installation() {
    ui_section \
        "Verification"


    # --------------------------------------------------------
    # Open-KWallet.sh exists
    # --------------------------------------------------------

    if [[ ! -f "$DEST_SCRIPT" ]]; then

        ui_error \
            "Open-KWallet.sh was not installed."

        exit 1

    fi


    ui_ok \
        "Open-KWallet.sh exists"


    # --------------------------------------------------------
    # Executable
    # --------------------------------------------------------

    if [[ ! -x "$DEST_SCRIPT" ]]; then

        ui_error \
            "Open-KWallet.sh is not executable."

        exit 1

    fi


    ui_ok \
        "Open-KWallet.sh is executable"


    # --------------------------------------------------------
    # Desktop file
    # --------------------------------------------------------

    if [[ ! -f "$DEST_DESKTOP" ]]; then

        ui_error \
            "Autostart entry was not installed."

        exit 1

    fi


    ui_ok \
        "open-kwallet.desktop exists"


    # --------------------------------------------------------
    # Exec path
    # --------------------------------------------------------

    EXPECTED_EXEC="$DEST_SCRIPT"

    ACTUAL_EXEC="$(
        sed -n 's/^Exec=//p' "$DEST_DESKTOP" |
        head -n 1 |
        tr -d '\r'
    )"


    if [[ "$ACTUAL_EXEC" != "$EXPECTED_EXEC" ]]; then

        ui_error \
            "Autostart Exec path is incorrect."

        echo


        ui_path \
            "Expected" \
            "Exec=$EXPECTED_EXEC"


        echo


        ui_path \
            "Found" \
            "Exec=$ACTUAL_EXEC"


        exit 1

    fi


    ui_ok \
        "Autostart Exec path is correct"


    # --------------------------------------------------------
    # Desktop syntax
    # --------------------------------------------------------

    if command -v desktop-file-validate >/dev/null 2>&1; then

        if desktop-file-validate "$DEST_DESKTOP"; then

            ui_ok \
                "Desktop file syntax is valid"

        else

            ui_warning \
                "desktop-file-validate reported a problem."

        fi

    else

        ui_skip \
            "Desktop file validation unavailable"

    fi
}


# ============================================================
# Completion
# ============================================================

show_completion() {
    clear_terminal_ui


    ui_success_title \
        "Installation Complete"


    ui_center_text \
        "KWallet Auto Open has been installed successfully." \
        "$GREEN$BOLD"


    echo
    echo


    ui_center_line \
        "─" \
        "$GREY"


    echo


    # --------------------------------------------------------
    # Installed Script
    # --------------------------------------------------------

    ui_center_text \
        "Installed Script" \
        "$WHITE$BOLD"


    ui_center_text \
        "$DEST_SCRIPT" \
        "$CYAN"


    echo
    echo


    # --------------------------------------------------------
    # Plasma Autostart
    # --------------------------------------------------------

    ui_center_text \
        "Plasma Autostart Entry" \
        "$WHITE$BOLD"


    ui_center_text \
        "$DEST_DESKTOP" \
        "$CYAN"


    echo
    echo


    # --------------------------------------------------------
    # Exec Path
    # --------------------------------------------------------

    ui_center_text \
        "Exec Path" \
        "$WHITE$BOLD"


    ui_center_text \
        "$DEST_SCRIPT" \
        "$CYAN"


    echo


    ui_center_line \
        "─" \
        "$GREY"


    echo
    echo


    ui_center_text \
        "✓ Ready to use" \
        "$GREEN$BOLD"
}


# ============================================================
# Main
# ============================================================

main() {

    # --------------------------------------------------------
    # Open alternate terminal screen
    # --------------------------------------------------------

    enter_terminal_ui


    # --------------------------------------------------------
    # Main Header
    # --------------------------------------------------------

    ui_title \
        "KDE KWallet Auto Open Installer"


    # --------------------------------------------------------
    # Installation
    # --------------------------------------------------------

    check_and_install_packages

    show_installation_paths

    check_source_files

    install_files

    verify_installation


    # --------------------------------------------------------
    # Completion Screen
    # --------------------------------------------------------

    show_completion


    # --------------------------------------------------------
    # DO NOT automatically leave the completion screen.
    #
    # The installer remains here until the user presses Enter.
    # --------------------------------------------------------

    wait_for_exit_to_terminal
}


# ============================================================
# Start Installer
# ============================================================

main "$@"


# ============================================================
# Restore Normal Terminal
#
# This happens only after the user presses Enter.
# ============================================================

restore_terminal


# ============================================================
# Disable EXIT Trap
#
# The terminal has already been restored manually.
# ============================================================

trap - EXIT


# ============================================================
# Exit Successfully
# ============================================================

exit