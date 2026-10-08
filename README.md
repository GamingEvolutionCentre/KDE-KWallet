# KDE-KWallet

KDE-KWallet is a lightweight login helper for Linux systems that use KDE KWallet. After your desktop session starts, it checks whether the `kdewallet` wallet is open and asks KWallet to open it through KDE's D-Bus interface when needed.

> [!IMPORTANT]
> No passwords are stored in the scripts.

## Version 1

The first packaged release is **v1.0.0**.

Release downloads include a `.tar.gz`, a `.zip`, and `SHA256SUMS.txt` for verification.

## Linux compatibility

The portable installer is distribution-independent. It does not call `pacman`, `apt`, `dnf`, `zypper`, or another package manager.

It supports systems where one of these Qt D-Bus clients is available:

- `qdbus6`
- `qdbus-qt6`
- `qdbus`

The launcher checks the KWallet 6 D-Bus service first and also includes fallbacks for older KWallet service names.

You still need a working KDE KWallet installation on the system. On KDE Plasma this is normally supplied by your distribution's KDE/KWallet packages.

## How it works

After login:

1. Your desktop starts the `open-kwallet.desktop` autostart entry.
2. The entry runs `$HOME/.local/bin/Open-KWallet.sh` (or your `XDG_BIN_HOME`).
3. The script waits for a KWallet D-Bus service.
4. It checks whether `kdewallet` is already open.
5. If it is already open, the script exits.
6. If it is closed, the script asks KWallet to open it.

## Recommended installation on any supported Linux distribution

Download and extract the latest GitHub release, then run:

```bash
chmod +x install.sh
./install.sh
```

The installer creates:

- `$HOME/.local/bin/Open-KWallet.sh`
- `$HOME/.config/autostart/open-kwallet.desktop`

It uses `XDG_BIN_HOME` and `XDG_CONFIG_HOME` when those variables are set.

Log out and back in after installation, or test it directly with:

```bash
$HOME/.local/bin/Open-KWallet.sh
```

## Arch Linux legacy TUI installer

The original interactive installer is still included as `installer.sh`. It uses Arch Linux package names and `pacman`, so use it only on Arch-based systems:

```bash
chmod +x installer.sh
./installer.sh
```

For cross-distribution installs, use `install.sh` instead.

## Uninstall

Portable uninstall:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

This removes only KDE-KWallet's user files. It deliberately leaves your system KDE, KWallet, SDDM, Qt, and other distribution packages untouched.

The original Arch-oriented interactive uninstaller remains available as `uninstaller.sh`.

## GitHub Actions releases

`.github/workflows/release.yml` builds the portable release archives, generates SHA-256 checksums, and creates or updates a GitHub Release.

You can publish a later version from **Actions → Release KDE-KWallet → Run workflow** and enter a semantic version such as `1.1.0`. Pushing a tag such as `v1.1.0` also runs the release workflow.

## Security

This project:

- does not store, request, or process your login password;
- does not include credentials;
- runs as your logged-in user;
- communicates with KWallet through KDE's D-Bus interface.

## Support

If the project helped you, consider starring the repository.
