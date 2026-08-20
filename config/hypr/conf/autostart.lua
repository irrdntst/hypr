-- Autostart.
-- https://wiki.hypr.land/Configuring/Basics/Autostart/
--
-- hl.exec_cmd() spawns asynchronously — no need for `& disown`.

hl.on("hyprland.start", function()
    -- Status bar and notification daemon.
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")

    -- Wallpaper. Configured in hyprpaper.conf next to this file.
    hl.exec_cmd("hyprpaper")

    -- Idle handling: lock after 10 minutes, screen off after 15.
    -- Timeouts live in hypridle.conf.
    hl.exec_cmd("hypridle")

    -- Clipboard history, read back with SUPER+SHIFT+V.
    hl.exec_cmd("wl-paste --watch cliphist store")

    -- Dark GTK apps.
    hl.exec_cmd("~/.config/hypr/scripts/gtk-theme.sh")

    -- Polkit agent. Without it, GUI apps cannot ask for a password.
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    -- Tray applets from packages/pacman-system.txt. The guard runs inside sh,
    -- so a program that isn't installed is a no-op rather than an error.
    hl.exec_cmd("command -v blueman-applet >/dev/null 2>&1 && blueman-applet")
    hl.exec_cmd("command -v nm-applet     >/dev/null 2>&1 && nm-applet --indicator")
    hl.exec_cmd("command -v udiskie       >/dev/null 2>&1 && udiskie --tray")
end)

-- Things worth adding once the matching packages are installed:
