#!/usr/bin/env bash
# Symlink these dotfiles into ~/.config, backing up whatever is already there.
#
#   ./install.sh --dry-run     show what would happen, change nothing
#   ./install.sh               link the configs
#   ./install.sh --packages    also install the core packages with pacman
#   ./install.sh --optional    also install the optional extras
#   ./install.sh --nvidia      also install the NVIDIA packages
#
# Safe to re-run: links that already point here are left alone.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
WITH_PACKAGES=0
WITH_OPTIONAL=0
WITH_NVIDIA=0

usage() {
    sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

log()  { printf '%s\n' "$*"; }
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
        --packages)   WITH_PACKAGES=1 ;;
        --optional)   WITH_OPTIONAL=1 ;;
        --nvidia)     WITH_NVIDIA=1 ;;
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

if (( DRY_RUN )); then
    log "DRY RUN — nothing will be changed."
fi

if (( WITH_PACKAGES )); then
    install_packages "$DOTFILES/packages/pacman.txt" "core packages"
fi

if (( WITH_OPTIONAL )); then
    install_packages "$DOTFILES/packages/pacman-optional.txt" "optional packages"
fi

if (( WITH_NVIDIA )); then
    install_packages "$DOTFILES/packages/pacman-nvidia.txt" "NVIDIA packages"
fi

link_configs
post_install_notes
