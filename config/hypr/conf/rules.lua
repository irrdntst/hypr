-- Window and layer rules.
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--
-- Rules are evaluated top to bottom, so order matters.
-- `hyprctl clients` shows the class/title of any open window.

-- Apps that maximize themselves on launch usually shouldn't.
hl.window_rule({
    name  = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Upstream fix for XWayland drag-and-drop leaving stray input-grabbing windows.
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- The resource monitor (SUPER+Escape) opens as a big floating window rather
-- than rearranging whatever you were looking at.
hl.window_rule({
    name  = "float-monitor",
    match = { class = "^monitor$" },
    float  = true,
    center = true,
    size   = { "monitor_w * 0.7", "monitor_h * 0.7" },
})

-- Modal dialogs ("are you sure?", print, preferences) belong on top of their
-- parent, not tiled into the layout.
hl.window_rule({
    name  = "float-modals",
    match = { modal = true },
    float  = true,
    center = true,
})

-- System dialogs are more useful floating and centered than tiled.
hl.window_rule({
    name  = "float-system-dialogs",
    match = { class = "^(pavucontrol|nm-connection-editor|blueman-manager|org\\.pulseaudio\\.pavucontrol)$" },
    float  = true,
    center = true,
    size   = { 900, 600 },
})

-- GTK/portal file pickers open as their own toplevel.
hl.window_rule({
    name  = "float-file-picker",
    match = { class = "^xdg-desktop-portal-gtk$" },
    float  = true,
    center = true,
    size   = { 1000, 700 },
})

-- Picture-in-picture windows: float, pin to every workspace, keep on top.
hl.window_rule({
    name  = "float-pip",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin   = true,
})

-- Fullscreen video should not be interrupted by the lock screen.
hl.window_rule({
    name  = "no-idle-when-fullscreen",
    match = { fullscreen = true },
    idle_inhibit = "fullscreen",
})

---- Layer rules ----
-- Layers are the non-window surfaces: bars, launchers, notifications.
-- Nothing needed here while blur and animations are off, but this is where
-- such rules go. Example:
-- hl.layer_rule({ name = "blur-bar", match = { namespace = "^waybar$" }, blur = true })
