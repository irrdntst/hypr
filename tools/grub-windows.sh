#!/usr/bin/env bash
# Make GRUB offer Windows.
#
#   tools/grub-windows.sh             configure and regenerate grub.cfg
#   tools/grub-windows.sh --check     report the state, change nothing
#   tools/grub-windows.sh --dry-run   print what would run
#
# Since GRUB 2.06 os-prober is disabled by default, which is why a dual-boot
# install usually shows no Windows entry until you flip one line.

set -uo pipefail

GRUB_DEFAULTS=/etc/default/grub
GRUB_CFG=/boot/grub/grub.cfg
STAMP="$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
CHECK_ONLY=0
case "${1:-}" in
    --check)   CHECK_ONLY=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    "") ;;
    *) printf 'unknown option: %s\n' "$1" >&2; exit 1 ;;
esac

log() { printf '  %s\n' "$*"; }
run() {
    if (( DRY_RUN )); then
        printf '  [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

# --- is this even a GRUB system? --------------------------------------------
if ! command -v grub-mkconfig >/dev/null 2>&1 || [[ ! -f "$GRUB_DEFAULTS" ]]; then
    log "GRUB is not installed here — skipping (systemd-boot and friends need nothing from this script)"
    exit 0
fi

if ! command -v os-prober >/dev/null 2>&1; then
    log "os-prober is not installed — install it first (packages/pacman-system.txt)"
    exit 0
fi

# --- where is the Windows loader? -------------------------------------------
windows_loader=""
for esp in /boot /efi /boot/efi; do
    candidate="$esp/EFI/Microsoft/Boot/bootmgfw.efi"
    if [[ -f "$candidate" ]]; then
        windows_loader="$candidate"
        break
    fi
done

if [[ -n "$windows_loader" ]]; then
    log "found Windows loader: $windows_loader"
else
    log "no Windows loader under /boot, /efi or /boot/efi"
    log "os-prober can only see Windows when its EFI partition is mounted"
fi

# --- the one setting that matters -------------------------------------------
current="$(grep -E '^[[:space:]]*GRUB_DISABLE_OS_PROBER=' "$GRUB_DEFAULTS" | tail -1)"

if [[ "$current" == *false* ]]; then
    log "GRUB_DISABLE_OS_PROBER is already false"
    needs_edit=0
else
    log "GRUB_DISABLE_OS_PROBER is ${current:-unset} — os-prober output is ignored"
    needs_edit=1
fi

if (( CHECK_ONLY )); then
    grep -c 'Windows' "$GRUB_CFG" >/dev/null 2>&1 &&
        log "grub.cfg currently mentions Windows $(grep -c 'menuentry.*[Ww]indows' "$GRUB_CFG") time(s)"
    exit 0
fi

if (( needs_edit )); then
    log "backing up $GRUB_DEFAULTS to $GRUB_DEFAULTS.bak.$STAMP"
    run sudo cp -a "$GRUB_DEFAULTS" "$GRUB_DEFAULTS.bak.$STAMP"

    if grep -qE '^[#[:space:]]*GRUB_DISABLE_OS_PROBER=' "$GRUB_DEFAULTS"; then
        run sudo sed -i -E \
            's|^[#[:space:]]*GRUB_DISABLE_OS_PROBER=.*|GRUB_DISABLE_OS_PROBER=false|' \
            "$GRUB_DEFAULTS"
    else
        if (( DRY_RUN )); then
            printf '  [dry-run] append GRUB_DISABLE_OS_PROBER=false to %s\n' "$GRUB_DEFAULTS"
        else
            printf '\n# Added by hypr: let os-prober list other operating systems.\nGRUB_DISABLE_OS_PROBER=false\n' \
                | sudo tee -a "$GRUB_DEFAULTS" >/dev/null
        fi
    fi
    log "set GRUB_DISABLE_OS_PROBER=false"
fi

# --- regenerate --------------------------------------------------------------
log "regenerating $GRUB_CFG"
if (( DRY_RUN )); then
    printf '  [dry-run] sudo grub-mkconfig -o %s\n' "$GRUB_CFG"
    exit 0
fi

output="$(sudo grub-mkconfig -o "$GRUB_CFG" 2>&1)"
printf '%s\n' "$output" | sed 's/^/      /'

if printf '%s' "$output" | grep -qi 'windows'; then
    log "Windows entry added"
    exit 0
fi

log "no Windows entry was created. The usual reasons:"
log "  1. Windows Fast Startup leaves the disk in a state Linux will not read."
log "     Turn it off in Windows, and run: powercfg /h off"
log "  2. Windows lives on another disk whose EFI partition is not mounted."
log "  3. The partition is encrypted with BitLocker."
log "See the fallback menu entry in README.md if detection stays stubborn."
