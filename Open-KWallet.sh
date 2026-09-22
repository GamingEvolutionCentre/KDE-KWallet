#!/bin/bash

# Wait for KWallet's D-Bus service to become available.
for i in {1..30}; do
    if qdbus6 org.kde.kwalletd6 /modules/kwalletd6 \
        org.kde.KWallet.isEnabled >/dev/null 2>&1; then
        break
    fi

    sleep 1
done

# Check whether kdewallet is already open.
IS_OPEN=$(qdbus6 org.kde.kwalletd6 /modules/kwalletd6 \
    org.kde.KWallet.isOpen kdewallet 2>/dev/null)

# Nothing to do if PAM/KWallet already opened it.
if [[ "$IS_OPEN" == "true" ]]; then
    exit 0
fi

# Wallet is closed, so open it.
qdbus6 org.kde.kwalletd6 /modules/kwalletd6 \
    org.kde.KWallet.open kdewallet 0 login >/dev/null
