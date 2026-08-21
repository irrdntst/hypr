#!/usr/bin/env bash
# Keep the clock from drifting when you dual-boot Windows.
#
#   tools/clock.sh              Linux yields: keep the hardware clock in local time
#   tools/clock.sh --utc        Windows yields: keep it in UTC, print the registry fix
#   tools/clock.sh --check      report the current state
#   tools/clock.sh --dry-run    print what would run
#
# Windows assumes the RTC holds local time; Linux assumes UTC. Whoever boots
# second "corrects" the clock and the other one is wrong next time. One of the
# two has to give way — this picks which.

set -uo pipefail

MODE="local"
DRY_RUN=0
CHECK_ONLY=0
case "${1:-}" in
    --utc)     MODE="utc" ;;
    --check)   CHECK_ONLY=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
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

if ! command -v timedatectl >/dev/null 2>&1; then
    log "timedatectl not found — nothing to do"
    exit 0
fi

state() {
    local rtc synced
    rtc="$(timedatectl show -p LocalRTC --value 2>/dev/null)"
    synced="$(timedatectl show -p NTPSynchronized --value 2>/dev/null)"
    log "hardware clock: $([[ "$rtc" == "yes" ]] && echo 'local time' || echo 'UTC')"
    log "network time synchronised: ${synced:-unknown}"
}

if (( CHECK_ONLY )); then
    state
    exit 0
fi

# Right time first. Writing the RTC before the system clock is correct just
# preserves the error in hardware.
log "enabling network time synchronisation"
run sudo timedatectl set-ntp true || log "could not enable NTP — continuing"

case "$MODE" in
    local)
        log "setting the hardware clock to local time (Windows' assumption)"
        # timedatectl goes through D-Bus and polkit, which times out in some
        # sessions. hwclock writes /etc/adjtime directly and always works.
        if ! run sudo timedatectl set-local-rtc 1 --adjust-system-clock 2>/dev/null; then
            log "timedatectl refused; falling back to hwclock"
            run sudo hwclock --localtime --systohc
        fi
        log "the warning timedatectl prints about local time is expected, not an error"
        ;;
    utc)
        log "setting the hardware clock to UTC (the correct one; Windows must be told)"
        if ! run sudo timedatectl set-local-rtc 0 --adjust-system-clock 2>/dev/null; then
            log "timedatectl refused; falling back to hwclock"
            run sudo hwclock --utc --systohc
        fi
        log ""
        log "Now run this in Windows, in an Administrator command prompt:"
        log '  reg add "HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" \'
        log '      /v RealTimeIsUniversal /t REG_DWORD /d 1 /f'
        log "Until you do, Windows will keep pushing the clock back."
        ;;
esac

(( DRY_RUN )) || state
