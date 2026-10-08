#!/usr/bin/env bash

set -u

WALLET_NAME="${KWALLET_NAME:-kdewallet}"
WAIT_SECONDS="${KWALLET_WAIT_SECONDS:-30}"

find_qdbus() {
    local candidate
    for candidate in qdbus6 qdbus-qt6 qdbus; do
        if command -v "$candidate" >/dev/null 2>&1; then
            command -v "$candidate"
            return 0
        fi
    done
    return 1
}

QDBUS="$(find_qdbus || true)"

if [[ -z "$QDBUS" ]]; then
    printf 'KDE-KWallet: qdbus was not found (tried qdbus6, qdbus-qt6, qdbus).\n' >&2
    exit 1
fi

SERVICE=""
OBJECT_PATH=""

find_kwallet_service() {
    local service path
    local -a candidates=(
        'org.kde.kwalletd6|/modules/kwalletd6'
        'org.kde.kwalletd5|/modules/kwalletd5'
        'org.kde.kwalletd|/modules/kwalletd'
    )

    local entry
    for entry in "${candidates[@]}"; do
        service="${entry%%|*}"
        path="${entry#*|}"

        if "$QDBUS" "$service" "$path" org.kde.KWallet.isEnabled >/dev/null 2>&1; then
            SERVICE="$service"
            OBJECT_PATH="$path"
            return 0
        fi
    done

    return 1
}

for ((second = 0; second < WAIT_SECONDS; second++)); do
    if find_kwallet_service; then
        break
    fi
    sleep 1
done

if [[ -z "$SERVICE" || -z "$OBJECT_PATH" ]]; then
    printf 'KDE-KWallet: no supported KWallet D-Bus service became available.\n' >&2
    exit 1
fi

IS_OPEN="$("$QDBUS" "$SERVICE" "$OBJECT_PATH" org.kde.KWallet.isOpen "$WALLET_NAME" 2>/dev/null || true)"

if [[ "$IS_OPEN" == "true" ]]; then
    exit 0
fi

"$QDBUS" "$SERVICE" "$OBJECT_PATH" \
    org.kde.KWallet.open "$WALLET_NAME" 0 login >/dev/null
