#!/usr/bin/bash

# ============================================================
# KDE KWallet Auto Open Uninstaller
# ============================================================
#
# Run with:
#
#   . ./uninstaller.sh
#
# Optional:
#
#   . ./uninstaller.sh --keep-dependencies
#
# ============================================================


# ============================================================
# INTERNAL BASH MODE
# ============================================================

if [[ "${1:-}" == "--__kwallet_internal_run" ]]; then

    shift

    PROJECT_DIR="${1:-}"
    DOWNLOADS_DIR="${2:-}"

    shift 2

    set -euo pipefail


    # ========================================================
    # Paths
    # ========================================================

    USER_HOME="$HOME"

    BIN_DIR="$USER_HOME/.local/bin"
    AUTOSTART_DIR="$USER_HOME/.config/autostart"

    DEST_SCRIPT="$BIN_DIR/Open-KWallet.sh"
    DEST_DESKTOP="$AUTOSTART_DIR/open-kwallet.desktop"


    # ========================================================
    # Colours
    # ========================================================

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


    # ========================================================
    # Terminal UI Layout
    # ========================================================

    UI_WIDTH=88

    TERMINAL_WIDTH=80
    CONTENT_WIDTH=80
    LEFT_PADDING=0

    TUI_ACTIVE=false


    update_ui_layout() {
        local detected_width

        detected_width="$(tput cols 2>/dev/null || printf '80')"

        if [[ "$detected_width" =~ ^[0-9]+$ ]]; then
            TERMINAL_WIDTH="$detected_width"
        else
            TERMINAL_WIDTH=80
        fi

        if (( TERMINAL_WIDTH < 40 )); then
            TERMINAL_WIDTH=40
        fi

        if (( UI_WIDTH >= TERMINAL_WIDTH )); then
            CONTENT_WIDTH=$(( TERMINAL_WIDTH - 4 ))
        else
            CONTENT_WIDTH="$UI_WIDTH"
        fi

        LEFT_PADDING=$(( (TERMINAL_WIDTH - CONTENT_WIDTH) / 2 ))

        if (( LEFT_PADDING < 0 )); then
            LEFT_PADDING=0
        fi
    }


    # ========================================================
    # Alternate Terminal Screen
    # ========================================================

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
        stty sane </dev/tty >/dev/tty 2>/dev/null || true

        printf '%b' "$RESET"

        if command -v tput >/dev/null 2>&1; then
            tput cnorm 2>/dev/null || true
        fi

        if [[ "$TUI_ACTIVE" == true ]] &&
           command -v tput >/dev/null 2>&1; then

            tput rmcup 2>/dev/null || true

            TUI_ACTIVE=false
        fi
    }


    trap restore_terminal EXIT


    # ========================================================
    # Pretty Terminal UI
    # ========================================================

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
        local padding

        update_ui_layout

        padding=$(( (TERMINAL_WIDTH - ${#text}) / 2 ))

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


    ui_center_status() {
        local label="$1"
        local colour="$2"
        local message="$3"

        local visible
        local padding

        visible="[$label] $message"

        update_ui_layout

        padding=$(( (TERMINAL_WIDTH - ${#visible}) / 2 ))

        if (( padding < 0 )); then
            padding=0
        fi

        printf '%*s%b[%s]%b %s\n' \
            "$padding" \
            '' \
            "$colour" \
            "$label" \
            "$RESET" \
            "$message"
    }


    # ========================================================
    # Titles
    # ========================================================

    ui_title() {
        local title="$1"

        echo

        ui_center_line \
            "═" \
            "$CYAN"

        echo

        ui_center_text \
            "$title" \
            "$WHITE$BOLD"

        ui_center_text \
            "KDE Plasma • KWallet • Safe Removal" \
            "$GREY"

        echo

        ui_center_line \
            "═" \
            "$CYAN"

        echo
    }


    ui_section() {
        local title="$1"

        echo

        ui_center_line \
            "─" \
            "$MAGENTA"

        ui_center_text \
            "$title" \
            "$WHITE$BOLD"

        ui_center_line \
            "─" \
            "$MAGENTA"

        echo
    }


    ui_success_title() {
        local title="$1"

        echo

        ui_center_line \
            "═" \
            "$GREEN"

        echo

        ui_center_text \
            "✓  $title  ✓" \
            "$GREEN$BOLD"

        echo

        ui_center_line \
            "═" \
            "$GREEN"

        echo
    }


    # ========================================================
    # Status Messages
    # ========================================================

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


    ui_removed() {
        ui_status \
            "REMOVED" \
            "$GREEN" \
            "$*"
    }


    # ========================================================
    # Enter Prompts
    # ========================================================

    wait_for_enter() {
        echo

        ui_center_text \
            "Press Enter to continue..." \
            "$ORANGE$BOLD"

        echo

        IFS= read -r </dev/tty

        clear_terminal_ui
    }


    # Final Enter prompt.
    #
    # This one DOES NOT clear the alternate screen.
    # After Enter is pressed, the script exits and the EXIT
    # trap restores the user's normal terminal.
    wait_for_exit() {
        echo
        echo

        ui_center_line \
            "─" \
            "$GREY"

        echo
        echo

        ui_center_text \
            "Press Enter to return to the terminal..." \
            "$ORANGE$BOLD"

        echo

        IFS= read -r </dev/tty
    }


    # ========================================================
    # Exit / Abandon
    # ========================================================

    abandon_uninstaller() {
        trap - EXIT

        restore_terminal

        echo

        printf '%b[ABANDONED]%b Uninstallation abandoned.\n' \
            "$ORANGE" \
            "$RESET"

        printf '%b[INFO]%b Current directory: %s\n' \
            "$CYAN" \
            "$RESET" \
            "$DOWNLOADS_DIR"

        echo

        exit 0
    }


    # ========================================================
    # Yes / No / Exit
    #
    # y = yes
    # n = no
    # e = exit
    #
    # No Enter required.
    # ========================================================

    ask_yes_or_no() {
        local prompt="$1"
        local answer=""

        while true; do

            update_ui_layout

            printf '%*s%b%s%b ' \
                "$(( LEFT_PADDING + 2 ))" \
                '' \
                "$WHITE" \
                "$prompt" \
                "$RESET"

            printf '%b[y]%bes / %b[n]%bo / %b[e]%bxit: ' \
                "$GREEN" \
                "$RESET" \
                "$RED" \
                "$RESET" \
                "$ORANGE" \
                "$RESET"

            IFS= read \
                -r \
                -s \
                -n 1 \
                answer \
                </dev/tty

            case "$answer" in

                y|Y)

                    printf '%by%b  %b✓ Yes%b\n' \
                        "$GREEN" \
                        "$RESET" \
                        "$GREEN" \
                        "$RESET"

                    return 0
                    ;;


                n|N)

                    printf '%bn%b  %b✗ No%b\n' \
                        "$RED" \
                        "$RESET" \
                        "$RED" \
                        "$RESET"

                    return 1
                    ;;


                e|E)

                    printf '%be%b  %b✗ Exit%b\n' \
                        "$ORANGE" \
                        "$RESET" \
                        "$ORANGE" \
                        "$RESET"

                    abandon_uninstaller
                    ;;


                *)

                    echo

                    ui_warning \
                        "Press y for yes, n for no, or e to exit."

                    echo
                    ;;

            esac

        done
    }


    # ========================================================
    # Command-Line Options
    # ========================================================

    case "${1:-}" in

        "")

            PACMAN_REMOVE_OPTIONS=(-Rns)

            REMOVAL_MODE="including unused dependencies"

            ;;


        --keep-dependencies)

            PACMAN_REMOVE_OPTIONS=(-R)

            REMOVAL_MODE="remove packages but keeps dependencies"

            ;;


        -h|--help)

            echo "Usage:"
            echo
            echo "  . ./uninstaller.sh"
            echo
            echo "  . ./uninstaller.sh --keep-dependencies"
            echo

            exit 0
            ;;


        *)

            printf '%b[ERROR]%b Unknown option: %s\n' \
                "$RED" \
                "$RESET" \
                "$1"

            echo
            echo "Usage:"
            echo
            echo "  . ./uninstaller.sh"
            echo "  . ./uninstaller.sh --keep-dependencies"
            echo

            exit 2
            ;;

    esac


    # ========================================================
    # Required Packages
    # ========================================================

    REQUIRED_PACKAGES=(
        bash
        plasma-workspace
        kwallet
        kwallet-pam
        sddm
        qt6-tools
    )


    # ========================================================
    # Information Screen
    # ========================================================

    enter_terminal_ui


    ui_title \
        "KDE KWallet Auto Open Uninstaller"


    ui_section \
        "Uninstallation Information"


    ui_center_text \
        "Project" \
        "$WHITE$BOLD"


    ui_center_text \
        "$PROJECT_DIR" \
        "$CYAN"


    echo
    echo


    ui_center_status \
        "IMPORTANT" \
        "$ORANGE" \
        "Current terminal moved to $HOME/Downloads."


    echo


    ui_center_status \
        "INFO" \
        "$CYAN" \
        "Package removal mode: $REMOVAL_MODE"


    echo


    ui_center_status \
        "INFO" \
        "$CYAN" \
        "Press [y]es, [n]o, [e]xit to answer the questions."


    echo


    wait_for_enter


    # ========================================================
    # Package Questions
    # ========================================================

    clear_terminal_ui


    ui_title \
        "KDE KWallet Auto Open Uninstaller"


    ui_section \
        "Choose Packages To Remove"


    PACKAGES_TO_REMOVE=()


    ui_center_text \
        "Select which packages should be removed." \
        "$WHITE"


    echo


    ui_center_status \
        "INFO" \
        "$CYAN" \
        "Nothing will be removed until all questions are answered."


    echo
    echo


    for package in "${REQUIRED_PACKAGES[@]}"; do

        if pacman -Q "$package" >/dev/null 2>&1; then

            if ask_yes_or_no \
                "Remove package '$package'?"; then

                PACKAGES_TO_REMOVE+=("$package")

            fi

        else

            ui_skip \
                "$package is not installed."

        fi

        echo

    done


    # ========================================================
    # Selected Actions
    # ========================================================

    clear_terminal_ui


    ui_title \
        "KDE KWallet Auto Open Uninstaller"


    ui_section \
        "Selected Actions"


    if (( ${#PACKAGES_TO_REMOVE[@]} > 0 )); then

        ui_center_text \
            "Packages Selected For Removal" \
            "$WHITE$BOLD"


        echo


        for package in "${PACKAGES_TO_REMOVE[@]}"; do

            ui_center_text \
                "• $package" \
                "$ORANGE"

        done

    else

        ui_center_status \
            "SKIP" \
            "$GREY" \
            "No packages selected for removal."

    fi


    echo
    echo


    ui_center_line \
        "─" \
        "$GREY"


    wait_for_enter


    # ========================================================
    # Initialise File / Folder Choices
    # ========================================================

    REMOVE_DESKTOP=false
    REMOVE_SCRIPT=false
    REMOVE_PROJECT_DIR=false


    # ========================================================
    # Question 1
    # open-kwallet.desktop
    # ========================================================

    clear_terminal_ui


    ui_title \
        "KDE KWallet Auto Open Uninstaller"


    ui_section \
        "Remove Plasma Autostart Entry"


    if [[ -f "$DEST_DESKTOP" ]]; then

        ui_center_text \
            "Plasma Autostart File" \
            "$WHITE$BOLD"


        echo


        ui_center_text \
            "$DEST_DESKTOP" \
            "$CYAN"


        echo
        echo


        if ask_yes_or_no \
            "Remove open-kwallet.desktop?"; then

            REMOVE_DESKTOP=true

        else

            REMOVE_DESKTOP=false

        fi

    else

        ui_center_status \
            "SKIP" \
            "$GREY" \
            "open-kwallet.desktop does not exist."

    fi


    sleep 1


    # ========================================================
    # Question 2
    # Open-KWallet.sh
    # ========================================================

    clear_terminal_ui


    ui_title \
        "KDE KWallet Auto Open Uninstaller"


    ui_section \
        "Remove Installed Script"


    if [[ -f "$DEST_SCRIPT" ]]; then

        ui_center_text \
            "Installed Script" \
            "$WHITE$BOLD"


        echo


        ui_center_text \
            "$DEST_SCRIPT" \
            "$CYAN"


        echo
        echo


        if ask_yes_or_no \
            "Remove Open-KWallet.sh?"; then

            REMOVE_SCRIPT=true

        else

            REMOVE_SCRIPT=false

        fi

    else

        ui_center_status \
            "SKIP" \
            "$GREY" \
            "Open-KWallet.sh does not exist."

    fi


    sleep 1


    # ========================================================
    # Question 3
    # KDE-KWallet Folder
    # ========================================================

    clear_terminal_ui


    ui_title \
        "KDE KWallet Auto Open Uninstaller"


    ui_section \
        "Remove KDE-KWallet Folder"


    if [[ -d "$PROJECT_DIR" ]]; then

        ui_center_text \
            "Project Folder" \
            "$WHITE$BOLD"


        echo


        ui_center_text \
            "$PROJECT_DIR" \
            "$CYAN"


        echo
        echo


        ui_center_status \
            "WARNING" \
            "$ORANGE" \
            "The project folder will be deleted after everything else."


        echo
        echo


        if ask_yes_or_no \
            "Remove the KDE-KWallet folder?"; then

            REMOVE_PROJECT_DIR=true

        else

            REMOVE_PROJECT_DIR=false

        fi

    else

        ui_center_status \
            "SKIP" \
            "$GREY" \
            "KDE-KWallet project folder does not exist."

    fi


    sleep 1


    # ========================================================
    # Apply Choices
    # ========================================================

    clear_terminal_ui


    ui_title \
        "KDE KWallet Auto Open Uninstaller"


    ui_section \
        "Applying Your Choices"


    # --------------------------------------------------------
    # Remove Packages
    # --------------------------------------------------------

    if (( ${#PACKAGES_TO_REMOVE[@]} > 0 )); then

        ui_info \
            "Removing selected packages..."


        echo


        sudo pacman \
            "${PACMAN_REMOVE_OPTIONS[@]}" \
            -- \
            "${PACKAGES_TO_REMOVE[@]}"


        echo


        ui_ok \
            "Selected packages removed."

    else

        ui_skip \
            "No packages selected for removal."

    fi


    echo


    # --------------------------------------------------------
    # Remove open-kwallet.desktop
    # --------------------------------------------------------

    if [[ "$REMOVE_DESKTOP" == true ]]; then

        if [[ -f "$DEST_DESKTOP" ]]; then

            rm -f -- \
                "$DEST_DESKTOP"


            ui_removed \
                "$DEST_DESKTOP"

        else

            ui_skip \
                "open-kwallet.desktop no longer exists."

        fi

    else

        ui_skip \
            "open-kwallet.desktop was kept."

    fi


    echo


    # --------------------------------------------------------
    # Remove Open-KWallet.sh
    # --------------------------------------------------------

    if [[ "$REMOVE_SCRIPT" == true ]]; then

        if [[ -f "$DEST_SCRIPT" ]]; then

            rm -f -- \
                "$DEST_SCRIPT"


            ui_removed \
                "$DEST_SCRIPT"

        else

            ui_skip \
                "Open-KWallet.sh no longer exists."

        fi

    else

        ui_skip \
            "Open-KWallet.sh was kept."

    fi


    # ========================================================
    # Completion Screen
    # ========================================================

    clear_terminal_ui


    ui_success_title \
        "Uninstallation Complete"


    ui_center_text \
        "KWallet Auto Open has finished processing your selections." \
        "$GREEN$BOLD"


    echo
    echo


    ui_center_line \
        "─" \
        "$GREY"


    echo


    # --------------------------------------------------------
    # Package Summary
    # --------------------------------------------------------

    ui_center_text \
        "Packages" \
        "$WHITE$BOLD"


    if (( ${#PACKAGES_TO_REMOVE[@]} > 0 )); then

        ui_center_text \
            "✓ Selected packages removed" \
            "$GREEN"

    else

        ui_center_text \
            "No packages removed" \
            "$GREY"

    fi


    echo
    echo


    # --------------------------------------------------------
    # Desktop Summary
    # --------------------------------------------------------

    ui_center_text \
        "Plasma Autostart Entry" \
        "$WHITE$BOLD"


    if [[ "$REMOVE_DESKTOP" == true ]]; then

        ui_center_text \
            "✓ Removed" \
            "$GREEN"

    else

        ui_center_text \
            "Kept" \
            "$GREY"

    fi


    echo
    echo


    # --------------------------------------------------------
    # Script Summary
    # --------------------------------------------------------

    ui_center_text \
        "Open-KWallet.sh" \
        "$WHITE$BOLD"


    if [[ "$REMOVE_SCRIPT" == true ]]; then

        ui_center_text \
            "✓ Removed" \
            "$GREEN"

    else

        ui_center_text \
            "Kept" \
            "$GREY"

    fi


    echo
    echo


    # --------------------------------------------------------
    # Project Summary
    # --------------------------------------------------------

    ui_center_text \
        "KDE-KWallet Project Folder" \
        "$WHITE$BOLD"


    if [[ "$REMOVE_PROJECT_DIR" == true ]]; then

        ui_center_text \
            "Scheduled for final removal" \
            "$ORANGE"

    else

        ui_center_text \
            "Kept" \
            "$GREY"

    fi


    echo
    echo


    ui_center_line \
        "─" \
        "$GREY"


    echo


    # ========================================================
    # Delete KDE-KWallet LAST
    # ========================================================

    if [[ "$REMOVE_PROJECT_DIR" == true ]]; then

        ui_center_text \
            "Removing KDE-KWallet project folder..." \
            "$ORANGE$BOLD"


        echo


        ui_center_status \
            "INFO" \
            "$CYAN" \
            "Terminal will remain in $HOME/Downloads."


        echo


        # ----------------------------------------------------
        # Safety Checks
        # ----------------------------------------------------

        if [[ -z "$PROJECT_DIR" ]] ||
           [[ "$PROJECT_DIR" == "/" ]] ||
           [[ "$PROJECT_DIR" == "$HOME" ]] ||
           [[ "$PROJECT_DIR" == "$DOWNLOADS_DIR" ]]; then

            ui_error \
                "Refusing to delete unsafe project path: $PROJECT_DIR"


            wait_for_exit

            exit 1

        fi


        # ----------------------------------------------------
        # Delete Project Folder
        # ----------------------------------------------------

        if [[ -d "$PROJECT_DIR" ]]; then

            rm -rf -- \
                "$PROJECT_DIR"

        fi


        # ----------------------------------------------------
        # Final Status
        # ----------------------------------------------------

        echo


        ui_center_status \
            "REMOVED" \
            "$GREEN" \
            "KDE-KWallet project folder removed."


        echo


        ui_center_text \
            "✓ All selected uninstall actions are complete." \
            "$GREEN$BOLD"


        ui_center_text \
            "Current directory: $HOME/Downloads" \
            "$GREY"


        # ----------------------------------------------------
        # Wait For User Before Returning To Normal Terminal
        # ----------------------------------------------------

        wait_for_exit


        # EXIT trap restores the normal terminal.
        exit 0

    fi


    # ========================================================
    # KDE-KWallet Kept
    # ========================================================

    ui_center_text \
        "✓ All selected uninstall actions are complete." \
        "$GREEN$BOLD"


    echo


    ui_center_text \
        "KDE-KWallet project folder was kept." \
        "$GREY"


    ui_center_text \
        "Current directory: $HOME/Downloads" \
        "$GREY"


    # ========================================================
    # Wait For User Before Returning To Normal Terminal
    # ========================================================

    wait_for_exit


    # EXIT trap restores the normal terminal.
    exit 0

fi


# ============================================================
# CURRENT-SHELL WRAPPER
# ============================================================
#
# This part runs inside the user's current shell.
#
# It moves the real shell to ~/Downloads before the internal
# Bash uninstaller starts.
#
# ============================================================


# ============================================================
# Detect Dot-Sourcing
# ============================================================

__KWALLET_SOURCED=false


# ------------------------------------------------------------
# Zsh
# ------------------------------------------------------------

if [[ -n "${ZSH_VERSION:-}" ]]; then

    case "${ZSH_EVAL_CONTEXT:-}" in

        *:file)

            __KWALLET_SOURCED=true

            ;;

    esac


# ------------------------------------------------------------
# Bash
# ------------------------------------------------------------

elif [[ -n "${BASH_VERSION:-}" ]]; then

    if [[ "${BASH_SOURCE[0]-}" != "$0" ]]; then

        __KWALLET_SOURCED=true

    fi

fi


# ============================================================
# Reject Normal Execution
# ============================================================

if [[ "$__KWALLET_SOURCED" != true ]]; then

    printf '\033[1;31m[ERROR]\033[0m This uninstaller must be run in the current shell.\n'

    echo

    echo "Run:"

    echo

    printf '  \033[1;32m. ./uninstaller.sh\033[0m\n'

    echo

    exit 1

fi


unset __KWALLET_SOURCED


# ============================================================
# Determine Uninstaller Path
# ============================================================

__KWALLET_SCRIPT_PATH=""


# ------------------------------------------------------------
# Zsh
# ------------------------------------------------------------

if [[ -n "${ZSH_VERSION:-}" ]]; then

    __KWALLET_SCRIPT_PATH="${(%):-%x}"


# ------------------------------------------------------------
# Bash
# ------------------------------------------------------------

elif [[ -n "${BASH_VERSION:-}" ]]; then

    __KWALLET_SCRIPT_PATH="${BASH_SOURCE[0]-}"

fi


# ============================================================
# Validate Path
# ============================================================

if [[ -z "$__KWALLET_SCRIPT_PATH" ]]; then

    printf '\033[1;31m[ERROR]\033[0m Could not determine the uninstaller path.\n'

    unset __KWALLET_SCRIPT_PATH

    return 1

fi


# ============================================================
# Convert To Absolute Path
# ============================================================

__KWALLET_SCRIPT_DIR="$(
    cd -- "$(dirname -- "$__KWALLET_SCRIPT_PATH")" &&
    pwd
)" || {

    printf '\033[1;31m[ERROR]\033[0m Could not determine the uninstaller directory.\n'

    unset __KWALLET_SCRIPT_PATH

    return 1

}


__KWALLET_SCRIPT_NAME="$(
    basename -- "$__KWALLET_SCRIPT_PATH"
)"


__KWALLET_SCRIPT_PATH="$__KWALLET_SCRIPT_DIR/$__KWALLET_SCRIPT_NAME"

__KWALLET_PROJECT_DIR="$__KWALLET_SCRIPT_DIR"

__KWALLET_DOWNLOADS_DIR="$HOME/Downloads"


# ============================================================
# Validate Uninstaller File
# ============================================================

if [[ ! -f "$__KWALLET_SCRIPT_PATH" ]]; then

    printf '\033[1;31m[ERROR]\033[0m Uninstaller file could not be found:\n'

    printf '  %s\n' \
        "$__KWALLET_SCRIPT_PATH"

    unset __KWALLET_SCRIPT_PATH
    unset __KWALLET_SCRIPT_DIR
    unset __KWALLET_SCRIPT_NAME
    unset __KWALLET_PROJECT_DIR
    unset __KWALLET_DOWNLOADS_DIR

    return 1

fi


# ============================================================
# Validate Downloads Directory
# ============================================================

if [[ ! -d "$__KWALLET_DOWNLOADS_DIR" ]]; then

    printf '\033[1;31m[ERROR]\033[0m Downloads directory does not exist:\n'

    printf '  %s\n' \
        "$__KWALLET_DOWNLOADS_DIR"

    unset __KWALLET_SCRIPT_PATH
    unset __KWALLET_SCRIPT_DIR
    unset __KWALLET_SCRIPT_NAME
    unset __KWALLET_PROJECT_DIR
    unset __KWALLET_DOWNLOADS_DIR

    return 1

fi


# ============================================================
# Move Real Terminal To ~/Downloads
# ============================================================

builtin cd "$__KWALLET_DOWNLOADS_DIR" || {

    printf '\033[1;31m[ERROR]\033[0m Could not move terminal to:\n'

    printf '  %s\n' \
        "$__KWALLET_DOWNLOADS_DIR"

    unset __KWALLET_SCRIPT_PATH
    unset __KWALLET_SCRIPT_DIR
    unset __KWALLET_SCRIPT_NAME
    unset __KWALLET_PROJECT_DIR
    unset __KWALLET_DOWNLOADS_DIR

    return 1

}


# ============================================================
# Launch Main Uninstaller Using Bash
# ============================================================

/usr/bin/bash \
    "$__KWALLET_SCRIPT_PATH" \
    --__kwallet_internal_run \
    "$__KWALLET_PROJECT_DIR" \
    "$__KWALLET_DOWNLOADS_DIR" \
    "$@"

__KWALLET_RESULT=$?


# ============================================================
# Final Terminal Reset
# ============================================================

stty sane </dev/tty >/dev/tty 2>/dev/null || true

printf '\033[0m\033[?25h'


# ============================================================
# Clean Temporary Variables
# ============================================================

unset __KWALLET_SCRIPT_PATH
unset __KWALLET_SCRIPT_DIR
unset __KWALLET_SCRIPT_NAME
unset __KWALLET_PROJECT_DIR
unset __KWALLET_DOWNLOADS_DIR


# ============================================================
# Return To Current Shell
# ============================================================

return "$__KWALLET_RESULT"