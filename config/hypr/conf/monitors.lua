-- Monitors.
-- https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- `hyprctl monitors all` lists every output with its name, modes and scale.

-- Catch-all: any monitor gets its preferred mode, automatic position and scale.
-- This alone is enough for a single-monitor setup.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Explicit setup — copy, uncomment and replace the names with your own.
-- Position is the top-left corner in the virtual layout, in pixels.
-- hl.monitor({ output = "DP-1",  mode = "2560x1440@165", position = "0x0",    scale = 1 })
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "2560x0", scale = 1 })
