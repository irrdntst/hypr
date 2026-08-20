#!/usr/bin/env bash
# Install everything and link the configs into ~/.config.
#
#   ./install.sh               everything: all packages, then the symlinks
#   ./install.sh --dry-run     show what would happen, change nothing
#   ./install.sh --links-only  symlinks only, install nothing
#   ./install.sh --restore     undo: drop our links, put the backups back
#
# The flags below narrow the install to one list instead of all of them:
#
#   --packages  core   --optional  extras
#   --system    bluetooth, network, tray   --nvidia  drivers
#
# NVIDIA packages are skipped automatically when no NVIDIA card is present.
# Safe to re-run: links that already point here are left alone.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
RESTORE=0
LINKS_ONLY=0

# Set by the narrowing flags. When none is given, everything is installed.
EXPLICIT=0
WITH_PACKAGES=0
WITH_OPTIONAL=0
WITH_SYSTEM=0
WITH_NVIDIA=0

usage() {
    sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

log()  { printf '%s\n' "$*"; }

version() {
    git -C "$DOTFILES" describe --tags --always --dirty 2>/dev/null || echo "unknown"
}
step() { printf '\n== %s\n' "$*"; }

run() {
    if (( DRY_RUN )); then
        printf '  [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

while (( $# )); do
    case "$1" in
        -n|--dry-run) DRY_RUN=1 ;;
        --packages)   WITH_PACKAGES=1; EXPLICIT=1 ;;
        --optional)   WITH_OPTIONAL=1; EXPLICIT=1 ;;
        --system)     WITH_SYSTEM=1;   EXPLICIT=1 ;;
        --nvidia)     WITH_NVIDIA=1;   EXPLICIT=1 ;;
        --links-only) LINKS_ONLY=1 ;;
        --restore)    RESTORE=1 ;;
        -h|--help)    usage 0 ;;
        *) printf 'unknown option: %s\n\n' "$1" >&2; usage 1 ;;
    esac
    shift
done

install_packages() {
    local list="$1" label="$2"
    step "Installing $label from $(basename "$list")"

    if ! command -v pacman >/dev/null 2>&1; then
        log "  pacman not found — skipping (this list is Arch-only)"
        return
    fi

    local packages=()
    while IFS= read -r line; do
        line="${line%%#*}"                  # strip trailing comments
        line="$(printf '%s' "$line" | tr -d '[:space:]')"
        if [[ -n "$line" ]]; then packages+=("$line"); fi
    done < "$list"

    log "  ${#packages[@]} packages: ${packages[*]}"
    run sudo pacman -S --needed "${packages[@]}"
}

has_nvidia_gpu() {
    # lspci is the readable check; the sysfs vendor id (0x10de is NVIDIA) works
    # even on a system without pciutils installed.
    if command -v lspci >/dev/null 2>&1 && lspci 2>/dev/null | grep -qi nvidia; then
        return 0
    fi
    grep -qxi '0x10de' /sys/bus/pci/devices/*/vendor 2>/dev/null
}

enable_bluetooth() {
    step "Enabling the bluetooth daemon"

    if ! command -v systemctl >/dev/null 2>&1; then
        log "  no systemctl — skipping"
        return
    fi
    if ! command -v bluetoothctl >/dev/null 2>&1 && ! (( DRY_RUN )); then
        log "  bluez is not installed — skipping"
        return
    fi

    run sudo systemctl enable --now bluetooth.service
}

link_configs() {
    step "Linking configs into $CONFIG_HOME"

    run mkdir -p "$CONFIG_HOME"

    local source target name
    for source in "$DOTFILES"/config/*/; do
        source="${source%/}"
        name="$(basename "$source")"
        target="$CONFIG_HOME/$name"

        if [[ -L "$target" ]]; then
            if [[ "$(readlink -f "$target")" == "$source" ]]; then
                log "  $name -> already linked, skipping"
                continue
            fi
            log "  $name -> replacing link to $(readlink "$target")"
            run rm "$target"
        elif [[ -e "$target" ]]; then
            log "  $name -> backing up to $name.bak.$STAMP"
            run mv "$target" "$target.bak.$STAMP"
        else
            log "  $name -> new"
        fi

        run ln -s "$source" "$target"
    done
}

restore_configs() {
    step "Restoring $CONFIG_HOME from backups"

    local source target name backups newest
    for source in "$DOTFILES"/config/*/; do
        source="${source%/}"
        name="$(basename "$source")"
        target="$CONFIG_HOME/$name"

        if [[ -L "$target" && "$(readlink -f "$target")" == "$source" ]]; then
            log "  $name -> removing our link"
            run rm "$target"
        elif [[ -e "$target" ]]; then
            log "  $name -> not ours, leaving it alone"
            continue
        fi

        # Timestamped names sort chronologically, so the last glob match is the
        # most recent backup.
        backups=("$target".bak.*)
        if [[ -e "${backups[0]}" ]]; then
            newest="${backups[-1]}"
            log "  $name -> restoring $(basename "$newest")"
            run mv "$newest" "$target"
        else
            log "  $name -> no backup to restore"
        fi
    done

    log ""
    log "Older backups, if any, are left in place. Remove them with:"
    log "  rm -rf $CONFIG_HOME/*.bak.*"
}

post_install_notes() {
    step "Next steps"
    cat <<'NOTES'
  1. NVIDIA: reboot, then check that DRM modesetting is on:
       cat /sys/module/nvidia_drm/parameters/modeset     # must print Y
  2. Start the session from a tty:
       start-hyprland
  3. Set your monitors in ~/.config/hypr/conf/monitors.lua
     (`hyprctl monitors all` lists the outputs).
  4. The config reloads on save. To reload by hand: hyprctl reload
     To see what Hyprland disliked:  hyprctl configerrors

  If something in the config is broken, Hyprland still gives you
  SUPER+Q (terminal), SUPER+R (run) and SUPER+M (exit).
NOTES
}

log "hypr $(version)"

if (( DRY_RUN )); then
    log "DRY RUN — nothing will be changed."
fi

if (( RESTORE )); then
    restore_configs
    exit 0
fi

# No narrowing flag means the whole thing.
if (( ! EXPLICIT && ! LINKS_ONLY )); then
    WITH_PACKAGES=1
    WITH_OPTIONAL=1
    WITH_SYSTEM=1
    if has_nvidia_gpu; then
        WITH_NVIDIA=1
    else
        log "No NVIDIA card detected — skipping the driver list."
        log "Force it with: ./install.sh --nvidia"
    fi
fi

if (( WITH_PACKAGES )); then
    install_packages "$DOTFILES/packages/pacman.txt" "core packages"
fi

if (( WITH_OPTIONAL )); then
    install_packages "$DOTFILES/packages/pacman-optional.txt" "optional packages"
fi

if (( WITH_SYSTEM )); then
    install_packages "$DOTFILES/packages/pacman-system.txt" "system packages"
    enable_bluetooth
fi

if (( WITH_NVIDIA )); then
    install_packages "$DOTFILES/packages/pacman-nvidia.txt" "NVIDIA packages"
fi

link_configs
post_install_notes
