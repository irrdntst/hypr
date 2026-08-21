#!/usr/bin/env bash
# Build paru from source and set it up.
#
#   tools/paru.sh              build and install paru if it is missing
#   tools/paru.sh --force      rebuild even when paru is already installed
#   tools/paru.sh --dry-run    print what would run
#
# From source rather than paru-bin on purpose: the prebuilt package is linked
# against one specific libalpm, and when pacman moves ahead of it the binary
# stops starting with "libalpm.so.NN: cannot open shared object file". A local
# build always matches the pacman you have.

set -uo pipefail

BUILD_ROOT="${XDG_CACHE_HOME:-$HOME/.cache}/ampere"
BUILD_DIR="$BUILD_ROOT/paru"
PARU_CONF=/etc/paru.conf
STAMP="$(date +%Y%m%d-%H%M%S)"

FORCE=0
DRY_RUN=0
case "${1:-}" in
    --force)   FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    "") ;;
    *) printf 'unknown option: %s\n' "$1" >&2; exit 1 ;;
esac

log() { printf '  %s\n' "$*"; }
run() {
    if (( DRY_RUN )); then
        printf '  [dry-run] %s\n' "$*"
        return 0
    fi
    "$@"
}

if ! command -v pacman >/dev/null 2>&1; then
    log "not an Arch system — skipping"
    exit 0
fi

configure_paru() {
    [[ -f "$PARU_CONF" ]] || return 0

    local wanted=(BottomUp NewsOnUpgrade CleanAfter) changed=0 option
    for option in "${wanted[@]}"; do
        grep -qE "^[[:space:]]*${option}[[:space:]]*$" "$PARU_CONF" && continue
        grep -qE "^#[[:space:]]*${option}[[:space:]]*$" "$PARU_CONF" || continue
        changed=1
    done

    (( changed )) || { log "paru.conf already set up"; return 0; }

    log "enabling BottomUp, NewsOnUpgrade and CleanAfter in $PARU_CONF"
    log "  (backup: $PARU_CONF.bak.$STAMP)"
    run sudo cp -a "$PARU_CONF" "$PARU_CONF.bak.$STAMP"
    for option in "${wanted[@]}"; do
        run sudo sed -i -E "s|^#[[:space:]]*($option)[[:space:]]*$|\\1|" "$PARU_CONF"
    done
}

if command -v paru >/dev/null 2>&1 && (( ! FORCE )); then
    log "paru $(paru --version 2>/dev/null | head -1 | awk '{print $2}') is already installed"
    configure_paru
    exit 0
fi

# A previous paru-bin owns files the source package also ships, and pacman
# refuses the transaction on the conflict. The debug package is separate and
# outlives `pacman -Rns paru-bin`, which is the trap most people hit.
leftovers=()
for package in paru-bin paru-bin-debug; do
    pacman -Qq "$package" >/dev/null 2>&1 && leftovers+=("$package")
done
if (( ${#leftovers[@]} )); then
    log "removing the prebuilt package first: ${leftovers[*]}"
    run sudo pacman -Rns "${leftovers[@]}"
fi

log "installing build prerequisites"
run sudo pacman -S --needed base-devel git

# Always start from a clean tree: makepkg happily reinstalls a stale package
# it built earlier instead of building the current source.
log "cloning the AUR package into $BUILD_DIR"
run rm -rf "$BUILD_DIR"
run mkdir -p "$BUILD_ROOT"
run git clone --depth 1 https://aur.archlinux.org/paru.git "$BUILD_DIR"

log "building — this compiles Rust and takes a few minutes"
log "read the PKGBUILD makepkg shows you before answering yes; AUR is unmoderated"
if (( DRY_RUN )); then
    printf '  [dry-run] makepkg -si in %s\n' "$BUILD_DIR"
else
    ( cd "$BUILD_DIR" && makepkg -si ) || {
        log "the build failed — the output above says why"
        exit 1
    }
fi

if (( ! DRY_RUN )); then
    if command -v paru >/dev/null 2>&1; then
        log "installed: $(paru --version | head -1)"
    else
        log "paru still is not on PATH — something went wrong"
        exit 1
    fi
fi

configure_paru
