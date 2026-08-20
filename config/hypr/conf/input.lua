-- Keyboard, mouse and touchpad.
-- https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
    input = {
        kb_layout  = "us,ru",
        kb_options = "grp:alt_shift_toggle",

        -- Keybinds keep working on the Cyrillic layout: they are resolved
        -- against the first layout instead of the current symbol.
        resolve_binds_by_sym = false,

        follow_mouse = 1,
        sensitivity  = 0,   -- -1.0 .. 1.0, 0 = raw libinput default

        repeat_rate  = 40,
        repeat_delay = 300,

        numlock_by_default = true,

        touchpad = {
            natural_scroll      = false,
            disable_while_typing = true,
            tap_button_map      = "lrm",
            clickfinger_behavior = true,
            scroll_factor       = 0.8,
        },
    },
})

-- Three-finger horizontal swipe switches workspaces.
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- Per-device overrides. Get the name from `hyprctl devices`.
-- hl.device({ name = "my-gaming-mouse", sensitivity = -0.3, accel_profile = "flat" })
