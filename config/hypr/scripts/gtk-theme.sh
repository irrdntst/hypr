#!/usr/bin/env bash
# Tell GTK apps to be dark.
#
# Two mechanisms, because GTK3 and GTK4 disagree about where the truth lives:
#   - gtk-3.0/settings.ini and gtk-4.0/settings.ini are read directly by the
#     toolkit and are what actually darken the GTK apps.
#   - the gsettings keys below are what GTK4/libadwaita and the XDG settings
#     portal look at.
#
# Run once at session start from conf/autostart.lua.

set -uo pipefail

command -v gsettings >/dev/null 2>&1 || exit 0

schema=org.gnome.desktop.interface

# gsettings needs the schema installed (package: gsettings-desktop-schemas).
# Without it every set below fails, so bail out rather than spew errors.
if ! gsettings list-schemas 2>/dev/null | grep -qx "$schema"; then
    printf '%s: %s is not installed, skipping gsettings\n' \
        "${0##*/}" "gsettings-desktop-schemas" >&2
    exit 0
fi

# Adwaita-dark is a separate theme shipped by gnome-themes-extra. When it is
# missing, naming it anyway leaves GTK on the *light* default, so fall back to
# plain Adwaita, whose dark variant settings.ini selects.
theme=Adwaita
for dir in "$HOME/.themes" /usr/share/themes /usr/local/share/themes; do
    if [[ -d "$dir/Adwaita-dark" ]]; then
        theme=Adwaita-dark
        break
    fi
done

gsettings set "$schema" color-scheme 'prefer-dark'
gsettings set "$schema" gtk-theme    "$theme"
gsettings set "$schema" icon-theme   'Adwaita'
gsettings set "$schema" cursor-theme 'Adwaita'
gsettings set "$schema" cursor-size  24
