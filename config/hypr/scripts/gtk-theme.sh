#!/usr/bin/env bash
# Tell GTK apps to be dark.
#
# settings.ini covers apps that read it directly; these gsettings keys cover
# GTK4/libadwaita and anything that asks the XDG settings portal. Run once at
# session start from conf/autostart.lua.

set -euo pipefail

command -v gsettings >/dev/null 2>&1 || exit 0

schema=org.gnome.desktop.interface
gsettings set "$schema" color-scheme  'prefer-dark'
gsettings set "$schema" gtk-theme     'Adwaita-dark'
gsettings set "$schema" icon-theme    'Adwaita'
gsettings set "$schema" cursor-theme  'Adwaita'
gsettings set "$schema" cursor-size   24
