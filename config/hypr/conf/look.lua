-- Look and feel. Tuned for responsiveness, not for screenshots:
-- no blur, no shadows, no rounding, no animations.
-- https://wiki.hypr.land/Configuring/Basics/Variables/
--
-- Palette (kept in sync by hand with waybar/style.css, kitty and mako):
--   bg #16181d   surface #1e2128   border #2a2e38
--   text #d4d6dd   muted #7a8091   accent #7aa2c7   urgent #c06a6a

hl.config({
    general = {
        gaps_in     = 2,
        gaps_out    = 4,
        border_size = 1,

        col = {
            active_border   = "rgb(7aa2c7)",
            inactive_border = "rgb(2a2e38)",
        },

        -- Drag borders and gaps to resize. Costs nothing, saves a keybind.
        resize_on_border        = true,
        extend_border_grab_area = 10,

        layout = "dwindle",
    },

    decoration = {
        rounding = 0,

        -- The two most expensive effects in Hyprland. Both off.
        blur   = { enabled = false },
        shadow = { enabled = false },
    },

    -- Animations off: every window action is applied on the next frame.
    animations = { enabled = false },

    dwindle = {
        -- New splits keep the orientation of the window they came from.
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper = 0,       -- no anime mascot
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        background_color        = 0x16181d,
    },

    -- Uncomment ONLY if the cursor flickers or disappears on NVIDIA.
    -- Software cursors cost a full frame redraw on every mouse move.
    -- cursor = { no_hardware_cursors = 1 },
})

-- If you ever want motion back without giving up responsiveness, delete the
-- `animations` block above and uncomment this. Everything stays under ~150ms.
--
-- hl.config({ animations = { enabled = true } })
-- hl.curve("snappy", { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })
-- hl.animation({ leaf = "global",     enabled = true, speed = 3, bezier = "snappy" })
-- hl.animation({ leaf = "windows",    enabled = true, speed = 3, bezier = "snappy", style = "popin 90%" })
-- hl.animation({ leaf = "fade",       enabled = true, speed = 3, bezier = "snappy" })
-- hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "snappy", style = "fade" })
