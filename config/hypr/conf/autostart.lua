-- Autostart.
-- https://wiki.hypr.land/Configuring/Basics/Autostart/
--
-- hl.exec_cmd() spawns asynchronously — no need for `& disown`.

hl.on("hyprland.start", function()
    -- Status bar and notification daemon.
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")

    -- Polkit agent. Without it, GUI apps cannot ask for a password.
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)

-- Things worth adding once the matching packages are installed:
--   hl.exec_cmd("hyprpaper")                              -- wallpaper
--   hl.exec_cmd("hypridle")                               -- idle / auto-lock
--   hl.exec_cmd("wl-paste --watch cliphist store")        -- clipboard history
--   hl.exec_cmd("nm-applet --indicator")                  -- network tray icon
