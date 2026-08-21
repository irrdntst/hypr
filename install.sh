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
#   --packages  core packages
#   --system    bluetooth, network, tray   --nvidia  drivers
#   --apps      browser, files, media, documents
#
# System side, also on by default:
#   --grub   let GRUB offer Windows      --clock  stop dual-boot clock drift
#   --paru   build the AUR helper from source
#
# NVIDIA packages are skipped automatically when no NVIDIA card is present.
# Safe to re-run: links that already point here are left alone.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
STAMP="$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
RESTORE=0
LINKS_ONLY=0

# Set by the narrowing flags. When none is given, everything is installed.
EXPLICIT=0
WITH_PACKAGES=0
WITH_SYSTEM=0
WITH_APPS=0
WITH_NVIDIA=0
WITH_GRUB=0
WITH_CLOCK=0
WITH_PARU=0

usage() {
    sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
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

# Helper scripts do their own dry-run reporting, so pass the flag through
# rather than printing the invocation and skipping the work.
run_script() {
    local script="$1"
    if (( DRY_RUN )); then
        "$script" --dry-run
    else
        "$script"
    fi
}

while (( $# )); do
    case "$1" in
        -n|--dry-run) DRY_RUN=1 ;;
        --packages)   WITH_PACKAGES=1; EXPLICIT=1 ;;
        --system)     WITH_SYSTEM=1;   EXPLICIT=1 ;;
        --apps)       WITH_APPS=1;     EXPLICIT=1 ;;
        --grub)       WITH_GRUB=1;     EXPLICIT=1 ;;
        --clock)      WITH_CLOCK=1;    EXPLICIT=1 ;;
        --paru)       WITH_PARU=1;     EXPLICIT=1 ;;
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

# One symlink: back up whatever is in the way, then point at the repo.
link_entry() {
    local source="$1" target="$2" name="$3"

    if [[ -L "$target" ]]; then
        if [[ "$(readlink -f "$target")" == "$source" ]]; then
            log "  $name -> already linked, skipping"
            return
        fi
        log "  $name -> replacing link to $(readlink "$target")"
        run rm "$target"
    elif [[ -e "$target" ]]; then
        log "  $name -> backing up to $(basename "$target").bak.$STAMP"
        run mv "$target" "$target.bak.$STAMP"
    else
        log "  $name -> new"
    fi

    run ln -s "$source" "$target"
}

link_configs() {
    step "Linking configs into $CONFIG_HOME"

    run mkdir -p "$CONFIG_HOME"

    local source name
    # Directories: config/hypr, config/waybar, ...
    for source in "$DOTFILES"/config/*/; do
        source="${source%/}"
        name="$(basename "$source")"
        link_entry "$source" "$CONFIG_HOME/$name" "$name"
    done

    # Loose files: config/mimeapps.list
    for source in "$DOTFILES"/config/*; do
        [[ -f "$source" ]] || continue
        name="$(basename "$source")"
        link_entry "$source" "$CONFIG_HOME/$name" "$name"
    done

    # The entry was called hypr-text-editor.desktop before 1.0; a dangling
    # link to it would sit in the menu forever.
    local stale="$DATA_HOME/applications/hypr-text-editor.desktop"
    if [[ -L "$stale" && ! -e "$stale" ]]; then
        log "  removing the pre-1.0 hypr-text-editor.desktop link"
        run rm "$stale"
    fi

    # Desktop entries belong under the data dir, not the config dir.
    if compgen -G "$DOTFILES/share/applications/*.desktop" >/dev/null; then
        step "Linking desktop entries into $DATA_HOME/applications"
        run mkdir -p "$DATA_HOME/applications"
        for source in "$DOTFILES"/share/applications/*.desktop; do
            name="$(basename "$source")"
            link_entry "$source" "$DATA_HOME/applications/$name" "$name"
        done
    fi
}

restore_entry() {
    local source="$1" target="$2" name="$3"
    local backups newest

        if [[ -L "$target" && "$(readlink -f "$target")" == "$source" ]]; then
            log "  $name -> removing our link"
            run rm "$target"
        elif [[ -e "$target" ]]; then
            log "  $name -> not ours, leaving it alone"
            return
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
}

restore_configs() {
    step "Restoring $CONFIG_HOME from backups"

    local source name
    for source in "$DOTFILES"/config/*/; do
        source="${source%/}"
        name="$(basename "$source")"
        restore_entry "$source" "$CONFIG_HOME/$name" "$name"
    done

    for source in "$DOTFILES"/config/*; do
        [[ -f "$source" ]] || continue
        name="$(basename "$source")"
        restore_entry "$source" "$CONFIG_HOME/$name" "$name"
    done

    if compgen -G "$DOTFILES/share/applications/*.desktop" >/dev/null; then
        for source in "$DOTFILES"/share/applications/*.desktop; do
            name="$(basename "$source")"
            restore_entry "$source" "$DATA_HOME/applications/$name" "$name"
        done
    fi

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
  4. Standard applications are declared in apps/defaults.env and wired up in
     config/mimeapps.list. Check they resolved:  tools/apps.sh --check
  5. The config reloads on save. To reload by hand: hyprctl reload
     To see what Hyprland disliked:  hyprctl configerrors

  If something in the config is broken, Hyprland still gives you
  SUPER+Q (terminal), SUPER+R (run) and SUPER+M (exit).
NOTES
}

log "Ampere $(version)"

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
    WITH_SYSTEM=1
    WITH_APPS=1
    WITH_GRUB=1
    WITH_CLOCK=1
    WITH_PARU=1
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

if (( WITH_SYSTEM )); then
    install_packages "$DOTFILES/packages/pacman-system.txt" "system packages"
    enable_bluetooth
fi

if (( WITH_APPS )); then
    install_packages "$DOTFILES/packages/pacman-apps.txt" "standard applications"
fi

if (( WITH_NVIDIA )); then
    install_packages "$DOTFILES/packages/pacman-nvidia.txt" "NVIDIA packages"
fi

# --- system side ------------------------------------------------------------
# Each of these is a no-op on a machine that does not need it: no GRUB, no
# Windows, no pacman.
if (( WITH_GRUB )); then
    step "Teaching GRUB about Windows"
    run_script "$DOTFILES/tools/grub-windows.sh"
fi

if (( WITH_CLOCK )); then
    step "Setting the clock up for dual boot"
    run_script "$DOTFILES/tools/clock.sh"
fi

link_configs

# The launcher lists every .desktop file on the system, including ones whose
# program was never installed or has been removed since.
if (( ! LINKS_ONLY )); then
    step "Tidying the application menu"
    run "$DOTFILES/tools/apps.sh" --prune
fi

# Last, because it compiles Rust and wants you to read a PKGBUILD.
if (( WITH_PARU )); then
    step "Installing the AUR helper"
    run_script "$DOTFILES/tools/paru.sh"
fi

post_install_notes
