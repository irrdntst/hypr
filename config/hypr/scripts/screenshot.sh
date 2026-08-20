#!/usr/bin/env bash
# Screenshot to both the clipboard and a file.
#
#   screenshot.sh full     the whole output
#   screenshot.sh region   drag a rectangle
#   screenshot.sh window   the focused window
#
# Bound to Print, SHIFT+Print and ALT+Print in conf/keybinds.lua.

set -euo pipefail

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y%m%d-%H%M%S).png"

case "${1:-full}" in
    region)
        # slurp exits non-zero when you press Escape; that is a cancel,
        # not a failure.
        geometry="$(slurp)" || exit 0
        grim -g "$geometry" "$file"
        ;;
    window)
        geometry="$(hyprctl activewindow -j |
            jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
        grim -g "$geometry" "$file"
        ;;
    full)
        grim "$file"
        ;;
    *)
        printf 'usage: %s [full|region|window]\n' "${0##*/}" >&2
        exit 1
        ;;
esac

wl-copy < "$file"
notify-send -i "$file" "Screenshot" "${file/#$HOME/~}"
