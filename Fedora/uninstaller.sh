#!/usr/bin/bash

# ============================================================
# KDE KWallet Auto Open Uninstaller
# Fedora edition - keeps the same removal flow as the Arch/Debian versions
#
# Run with:
#   . ./uninstaller.sh
#
# Optional:
#   . ./uninstaller.sh --keep-dependencies
# ============================================================

if [[ "${1:-}" == "--__kwallet_internal_run" ]]; then
    shift
    PROJECT_DIR="${1:-}"
    DOWNLOADS_DIR="${2:-}"
    shift 2
    set -euo pipefail

    USER_HOME="$HOME"
    BIN_DIR="$USER_HOME/.local/bin"
    AUTOSTART_DIR="$USER_HOME/.config/autostart"
    DEST_SCRIPT="$BIN_DIR/Open-KWallet.sh"
    DEST_DESKTOP="$AUTOSTART_DIR/open-kwallet.desktop"

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

    ui_center_status() {
        local label="$1" colour="$2" message="$3" visible padding
        visible="[$label] $message"
        update_ui_layout
        padding=$(( (TERMINAL_WIDTH - ${#visible}) / 2 ))
        (( padding < 0 )) && padding=0
        printf '%*s%b[%s]%b %s\n' "$padding" '' "$colour" "$label" "$RESET" "$message"
    }

    ui_title() {
        echo
        ui_center_line "═" "$CYAN"
        echo
        ui_center_text "$1" "$WHITE$BOLD"
        ui_center_text "KDE Plasma • KWallet • Safe Removal" "$GREY"
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

    ui_success_title() {
        echo
        ui_center_line "═" "$GREEN"
        echo
        ui_center_text "✓  $1  ✓" "$GREEN$BOLD"
        echo
        ui_center_line "═" "$GREEN"
        echo
    }

    ui_ok()      { ui_status "OK" "$GREEN" "$*"; }
    ui_error()   { ui_status "ERROR" "$RED" "$*" >&2; }
    ui_warning() { ui_status "WARNING" "$ORANGE" "$*"; }
    ui_info()    { ui_status "INFO" "$CYAN" "$*"; }
    ui_skip()    { ui_status "SKIP" "$GREY" "$*"; }
    ui_removed() { ui_status "REMOVED" "$GREEN" "$*"; }

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
        stty sane </dev/tty >/dev/tty 2>/dev/null || true
        printf '%b' "$RESET"
        if command -v tput >/dev/null 2>&1; then
            tput cnorm 2>/dev/null || true
        fi
        if [[ "$TUI_ACTIVE" == true ]] && command -v tput >/dev/null 2>&1; then
            tput rmcup 2>/dev/null || true
            TUI_ACTIVE=false
        fi
    }
    trap restore_terminal EXIT

    wait_for_enter() {
        echo
        ui_center_text "Press Enter to continue..." "$ORANGE$BOLD"
        echo
        IFS= read -r </dev/tty
        clear_terminal_ui
    }

    wait_for_exit() {
        echo
        echo
        ui_center_line "─" "$GREY"
        echo
        echo
        ui_center_text "Press Enter to return to the terminal..." "$ORANGE$BOLD"
        echo
        IFS= read -r </dev/tty
    }

    abandon_uninstaller() {
        trap - EXIT
        restore_terminal
        echo
        printf '%b[ABANDONED]%b Uninstallation abandoned.\n' "$ORANGE" "$RESET"
        printf '%b[INFO]%b Current directory: %s\n' "$CYAN" "$RESET" "$DOWNLOADS_DIR"
        echo
        exit 0
    }

    ask_yes_or_no() {
        local prompt="$1" answer=""
        while true; do
            update_ui_layout
            printf '%*s%b%s%b ' "$(( LEFT_PADDING + 2 ))" '' "$WHITE" "$prompt" "$RESET"
            printf '%b[y]%bes / %b[n]%bo / %b[e]%bxit: ' "$GREEN" "$RESET" "$RED" "$RESET" "$ORANGE" "$RESET"
            IFS= read -r -s -n 1 answer </dev/tty
            case "$answer" in
                y|Y)
                    printf '%by%b  %b✓ Yes%b\n' "$GREEN" "$RESET" "$GREEN" "$RESET"
                    return 0
                    ;;
                n|N)
                    printf '%bn%b  %b✗ No%b\n' "$RED" "$RESET" "$RED" "$RESET"
                    return 1
                    ;;
                e|E)
                    printf '%be%b  %b✗ Exit%b\n' "$ORANGE" "$RESET" "$ORANGE" "$RESET"
                    abandon_uninstaller
                    ;;
                *)
                    echo
                    ui_warning "Press y for yes, n for no, or e to exit."
                    echo
                    ;;
            esac
        done
    }

    # ========================================================
    # Command-Line Options — Fedora/DNF
    # ========================================================

    case "${1:-}" in
        "")
            DNF_REMOVE_OPTIONS=(remove -y)
            REMOVAL_MODE="including unused dependencies"
            ;;
        --keep-dependencies)
            DNF_REMOVE_OPTIONS=(remove --no-autoremove -y)
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
            printf '%b[ERROR]%b Unknown option: %s\n' "$RED" "$RESET" "$1"
            echo
            echo "Usage:"
            echo
            echo "  . ./uninstaller.sh"
            echo "  . ./uninstaller.sh --keep-dependencies"
            echo
            exit 2
            ;;
    esac

    REQUIRED_PACKAGES=(
        bash
        plasma-workspace
        kf6-kwallet
        pam-kwallet
        sddm
        qt6-qttools
    )

    command -v rpm >/dev/null 2>&1 || {
        printf '%b[ERROR]%b rpm was not found. This package is intended for Fedora.\n' "$RED" "$RESET" >&2
        exit 1
    }
    command -v dnf >/dev/null 2>&1 || {
        printf '%b[ERROR]%b dnf was not found. This package is intended for Fedora.\n' "$RED" "$RESET" >&2
        exit 1
    }

    enter_terminal_ui
    ui_title "KDE KWallet Auto Open Uninstaller"
    ui_section "Uninstallation Information"
    ui_center_text "Project" "$WHITE$BOLD"
    ui_center_text "$PROJECT_DIR" "$CYAN"
    echo
    echo
    ui_center_status "IMPORTANT" "$ORANGE" "Current terminal moved to $HOME/Downloads."
    echo
    ui_center_status "INFO" "$CYAN" "Package removal mode: $REMOVAL_MODE"
    echo
    ui_center_status "INFO" "$CYAN" "Press [y]es, [n]o, [e]xit to answer the questions."
    echo
    wait_for_enter

    clear_terminal_ui
    ui_title "KDE KWallet Auto Open Uninstaller"
    ui_section "Choose Packages To Remove"
    PACKAGES_TO_REMOVE=()
    ui_center_text "Select which packages should be removed." "$WHITE"
    echo
    ui_center_status "INFO" "$CYAN" "Nothing will be removed until all questions are answered."
    echo
    echo

    for package in "${REQUIRED_PACKAGES[@]}"; do
        if rpm -q "$package" >/dev/null 2>&1; then
            if ask_yes_or_no "Remove package '$package'?"; then
                PACKAGES_TO_REMOVE+=("$package")
            fi
        else
            ui_skip "$package is not installed."
        fi
        echo
    done

    clear_terminal_ui
    ui_title "KDE KWallet Auto Open Uninstaller"
    ui_section "Selected Actions"
    if (( ${#PACKAGES_TO_REMOVE[@]} > 0 )); then
        ui_center_text "Packages Selected For Removal" "$WHITE$BOLD"
        echo
        for package in "${PACKAGES_TO_REMOVE[@]}"; do
            ui_center_text "• $package" "$ORANGE"
        done
    else
        ui_center_status "SKIP" "$GREY" "No packages selected for removal."
    fi
    echo
    echo
    ui_center_line "─" "$GREY"
    wait_for_enter

    REMOVE_DESKTOP=false
    REMOVE_SCRIPT=false
    REMOVE_PROJECT_DIR=false

    clear_terminal_ui
    ui_title "KDE KWallet Auto Open Uninstaller"
    ui_section "Remove Plasma Autostart Entry"
    if [[ -f "$DEST_DESKTOP" ]]; then
        ui_center_text "Plasma Autostart File" "$WHITE$BOLD"
        echo
        ui_center_text "$DEST_DESKTOP" "$CYAN"
        echo
        echo
        if ask_yes_or_no "Remove open-kwallet.desktop?"; then
            REMOVE_DESKTOP=true
        fi
    else
        ui_center_status "SKIP" "$GREY" "open-kwallet.desktop does not exist."
    fi

    sleep 1
    clear_terminal_ui
    ui_title "KDE KWallet Auto Open Uninstaller"
    ui_section "Remove Installed Script"
    if [[ -f "$DEST_SCRIPT" ]]; then
        ui_center_text "Installed Script" "$WHITE$BOLD"
        echo
        ui_center_text "$DEST_SCRIPT" "$CYAN"
        echo
        echo
        if ask_yes_or_no "Remove Open-KWallet.sh?"; then
            REMOVE_SCRIPT=true
        fi
    else
        ui_center_status "SKIP" "$GREY" "Open-KWallet.sh does not exist."
    fi

    sleep 1
    clear_terminal_ui
    ui_title "KDE KWallet Auto Open Uninstaller"
    ui_section "Remove KDE-KWallet Folder"
    if [[ -d "$PROJECT_DIR" ]]; then
        ui_center_text "Project Folder" "$WHITE$BOLD"
        echo
        ui_center_text "$PROJECT_DIR" "$CYAN"
        echo
        echo
        ui_center_status "WARNING" "$ORANGE" "The project folder will be deleted after everything else."
        echo
        echo
        if ask_yes_or_no "Remove the KDE-KWallet folder?"; then
            REMOVE_PROJECT_DIR=true
        fi
    else
        ui_center_status "SKIP" "$GREY" "KDE-KWallet project folder does not exist."
    fi

    sleep 1
    clear_terminal_ui
    ui_title "KDE KWallet Auto Open Uninstaller"
    ui_section "Applying Your Choices"

    if (( ${#PACKAGES_TO_REMOVE[@]} > 0 )); then
        ui_info "Removing selected packages with DNF..."
        echo
        sudo dnf "${DNF_REMOVE_OPTIONS[@]}" "${PACKAGES_TO_REMOVE[@]}"
        echo
        ui_ok "Selected packages removed."
    else
        ui_skip "No packages selected for removal."
    fi
    echo

    if [[ "$REMOVE_DESKTOP" == true ]]; then
        if [[ -f "$DEST_DESKTOP" ]]; then
            rm -f -- "$DEST_DESKTOP"
            ui_removed "$DEST_DESKTOP"
        else
            ui_skip "open-kwallet.desktop no longer exists."
        fi
    else
        ui_skip "open-kwallet.desktop was kept."
    fi
    echo

    if [[ "$REMOVE_SCRIPT" == true ]]; then
        if [[ -f "$DEST_SCRIPT" ]]; then
            rm -f -- "$DEST_SCRIPT"
            ui_removed "$DEST_SCRIPT"
        else
            ui_skip "Open-KWallet.sh no longer exists."
        fi
    else
        ui_skip "Open-KWallet.sh was kept."
    fi

    clear_terminal_ui
    ui_success_title "Uninstallation Complete"
    ui_center_text "KWallet Auto Open has finished processing your selections." "$GREEN$BOLD"
    echo
    echo
    ui_center_line "─" "$GREY"
    echo
    ui_center_text "Packages" "$WHITE$BOLD"
    if (( ${#PACKAGES_TO_REMOVE[@]} > 0 )); then
        ui_center_text "✓ Selected packages removed" "$GREEN"
    else
        ui_center_text "No packages removed" "$GREY"
    fi
    echo
    echo
    ui_center_text "Plasma Autostart Entry" "$WHITE$BOLD"
    [[ "$REMOVE_DESKTOP" == true ]] && ui_center_text "✓ Removed" "$GREEN" || ui_center_text "Kept" "$GREY"
    echo
    echo
    ui_center_text "Open-KWallet.sh" "$WHITE$BOLD"
    [[ "$REMOVE_SCRIPT" == true ]] && ui_center_text "✓ Removed" "$GREEN" || ui_center_text "Kept" "$GREY"
    echo
    echo
    ui_center_text "KDE-KWallet Project Folder" "$WHITE$BOLD"
    [[ "$REMOVE_PROJECT_DIR" == true ]] && ui_center_text "Scheduled for final removal" "$ORANGE" || ui_center_text "Kept" "$GREY"
    echo
    echo
    ui_center_line "─" "$GREY"
    echo

    if [[ "$REMOVE_PROJECT_DIR" == true ]]; then
        ui_center_text "Removing KDE-KWallet project folder..." "$ORANGE$BOLD"
        echo
        ui_center_status "INFO" "$CYAN" "Terminal will remain in $HOME/Downloads."
        echo

        if [[ -z "$PROJECT_DIR" || "$PROJECT_DIR" == "/" || "$PROJECT_DIR" == "$HOME" || "$PROJECT_DIR" == "$DOWNLOADS_DIR" ]]; then
            ui_error "Refusing to delete unsafe project path: $PROJECT_DIR"
            wait_for_exit
            exit 1
        fi

        [[ -d "$PROJECT_DIR" ]] && rm -rf -- "$PROJECT_DIR"
        echo
        ui_center_status "REMOVED" "$GREEN" "KDE-KWallet project folder removed."
        echo
        ui_center_text "✓ All selected uninstall actions are complete." "$GREEN$BOLD"
        ui_center_text "Current directory: $HOME/Downloads" "$GREY"
        wait_for_exit
        exit 0
    fi

    ui_center_text "✓ All selected uninstall actions are complete." "$GREEN$BOLD"
    echo
    ui_center_text "KDE-KWallet project folder was kept." "$GREY"
    ui_center_text "Current directory: $HOME/Downloads" "$GREY"
    wait_for_exit
    exit 0
fi

# ============================================================
# CURRENT-SHELL WRAPPER
# ============================================================

__KWALLET_SOURCED=false

if [[ -n "${ZSH_VERSION:-}" ]]; then
    case "${ZSH_EVAL_CONTEXT:-}" in
        *:file) __KWALLET_SOURCED=true ;;
    esac
elif [[ -n "${BASH_VERSION:-}" ]]; then
    if [[ "${BASH_SOURCE[0]-}" != "$0" ]]; then
        __KWALLET_SOURCED=true
    fi
fi

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

__KWALLET_SCRIPT_PATH=""
if [[ -n "${ZSH_VERSION:-}" ]]; then
    __KWALLET_SCRIPT_PATH="${(%):-%x}"
elif [[ -n "${BASH_VERSION:-}" ]]; then
    __KWALLET_SCRIPT_PATH="${BASH_SOURCE[0]-}"
fi

if [[ -z "$__KWALLET_SCRIPT_PATH" ]]; then
    printf '\033[1;31m[ERROR]\033[0m Could not determine the uninstaller path.\n'
    unset __KWALLET_SCRIPT_PATH
    return 1
fi

__KWALLET_SCRIPT_DIR="$(cd -- "$(dirname -- "$__KWALLET_SCRIPT_PATH")" && pwd)" || {
    printf '\033[1;31m[ERROR]\033[0m Could not determine the uninstaller directory.\n'
    unset __KWALLET_SCRIPT_PATH
    return 1
}
__KWALLET_SCRIPT_NAME="$(basename -- "$__KWALLET_SCRIPT_PATH")"
__KWALLET_SCRIPT_PATH="$__KWALLET_SCRIPT_DIR/$__KWALLET_SCRIPT_NAME"
__KWALLET_PROJECT_DIR="$__KWALLET_SCRIPT_DIR"
__KWALLET_DOWNLOADS_DIR="$HOME/Downloads"

if [[ ! -f "$__KWALLET_SCRIPT_PATH" ]]; then
    printf '\033[1;31m[ERROR]\033[0m Uninstaller file could not be found:\n  %s\n' "$__KWALLET_SCRIPT_PATH"
    unset __KWALLET_SCRIPT_PATH __KWALLET_SCRIPT_DIR __KWALLET_SCRIPT_NAME __KWALLET_PROJECT_DIR __KWALLET_DOWNLOADS_DIR
    return 1
fi

if [[ ! -d "$__KWALLET_DOWNLOADS_DIR" ]]; then
    printf '\033[1;31m[ERROR]\033[0m Downloads directory does not exist:\n  %s\n' "$__KWALLET_DOWNLOADS_DIR"
    unset __KWALLET_SCRIPT_PATH __KWALLET_SCRIPT_DIR __KWALLET_SCRIPT_NAME __KWALLET_PROJECT_DIR __KWALLET_DOWNLOADS_DIR
    return 1
fi

builtin cd "$__KWALLET_DOWNLOADS_DIR" || {
    printf '\033[1;31m[ERROR]\033[0m Could not move terminal to:\n  %s\n' "$__KWALLET_DOWNLOADS_DIR"
    unset __KWALLET_SCRIPT_PATH __KWALLET_SCRIPT_DIR __KWALLET_SCRIPT_NAME __KWALLET_PROJECT_DIR __KWALLET_DOWNLOADS_DIR
    return 1
}

/usr/bin/bash "$__KWALLET_SCRIPT_PATH" --__kwallet_internal_run "$__KWALLET_PROJECT_DIR" "$__KWALLET_DOWNLOADS_DIR" "$@"
__KWALLET_RESULT=$?
stty sane </dev/tty >/dev/tty 2>/dev/null || true
printf '\033[0m\033[?25h'
unset __KWALLET_SCRIPT_PATH __KWALLET_SCRIPT_DIR __KWALLET_SCRIPT_NAME __KWALLET_PROJECT_DIR __KWALLET_DOWNLOADS_DIR
return "$__KWALLET_RESULT"
