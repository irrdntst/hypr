-- Keybinds.
-- https://wiki.hypr.land/Configuring/Basics/Binds/
-- Dispatcher list: https://wiki.hypr.land/Configuring/Basics/Dispatchers/
--
-- Bind callbacks run on the compositor event loop. Never put io.popen, sleeps
-- or clipboard tools in a Lua function here — use hl.dsp.exec_cmd() so the
-- command runs outside the callback.

-- Pressing the number of the workspace you are already on returns you to the
-- previous one, i3-style.
hl.config({ binds = { workspace_back_and_forth = true } })

local mod = "SUPER"

local terminal = "kitty"
local menu     = "wofi --show drun"

---- Apps ----
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + R",      hl.dsp.exec_cmd(menu))
-- hyprlauncher is hyprwm's own launcher (package: hyprlauncher). To try it,
-- swap it into the bind above and keep whichever you prefer.

---- Session ----
hl.bind(mod .. " + Q",         hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.kill())
-- Graceful exit. hyprshutdown handles the ordered shutdown when present.
hl.bind(mod .. " + M", hl.dsp.exec_cmd(
    "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- The config reloads on save anyway; this is for when you edit it elsewhere.
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))

---- Window state ----
hl.bind(mod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F",         hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized",  action = "toggle" }))
hl.bind(mod .. " + P",         hl.dsp.window.pseudo({ action = "toggle" }))
hl.bind(mod .. " + C",         hl.dsp.window.center())
hl.bind(mod .. " + SHIFT + P", hl.dsp.window.pin())   -- floating only: show on every workspace
hl.bind(mod .. " + J",         hl.dsp.layout("togglesplit"))  -- dwindle only

---- Focus ----
local directions = { h = "l", j = "d", k = "u", l = "r" }
for key, dir in pairs(directions) do
    hl.bind(mod .. " + " .. key,           hl.dsp.focus({ direction = dir }))
    hl.bind(mod .. " + SHIFT + " .. key,   hl.dsp.window.move({ direction = dir }))
end

hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "d" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "r" }))

hl.bind(mod .. " + Tab", hl.dsp.focus({ last = true }))

---- Groups (tabbed windows) ----
-- A group stacks windows in the space of one, like i3's tabbed container.
hl.bind(mod .. " + G",       hl.dsp.group.toggle())
hl.bind(mod .. " + ALT + h", hl.dsp.group.prev())
hl.bind(mod .. " + ALT + l", hl.dsp.group.next())

---- Workspaces ----
for i = 1, 10 do
    local key = i % 10  -- workspace 10 sits on key 0
    hl.bind(mod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Scratchpad
hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

---- Mouse ----
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

---- Resize mode ----
-- SUPER + ALT + R enters it, arrows/hjkl resize, Escape or Return leaves.
hl.bind(mod .. " + ALT + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
    local step = 40
    local moves = {
        { keys = { "l", "right" }, x =  step, y = 0 },
        { keys = { "h", "left"  }, x = -step, y = 0 },
        { keys = { "j", "down"  }, x = 0, y =  step },
        { keys = { "k", "up"    }, x = 0, y = -step },
    }

    for _, m in ipairs(moves) do
        for _, key in ipairs(m.keys) do
            hl.bind(key, hl.dsp.window.resize({ x = m.x, y = m.y, relative = true }),
                { repeating = true })
        end
    end

    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)

---- Volume ----
-- wpctl ships with wireplumber, so these work out of the box.
-- Volume is capped at 100% so a stray keypress can't blow out your ears.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute",    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),   { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Backlight. Needs brightnessctl (packages/pacman-optional.txt) and a panel
-- that exposes a backlight device — desktop monitors do not.
-- hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
-- hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Media keys. Needs playerctl (packages/pacman-optional.txt).
-- hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
-- hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
-- hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

---- Notifications ----
-- makoctl ships with mako, so these need nothing extra.
hl.bind(mod .. " + N",         hl.dsp.exec_cmd("makoctl dismiss -a"))
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("makoctl mode -t do-not-disturb"))

---- Screenshots ----
-- Needs grim + slurp + wl-clipboard. Uncomment once they're installed.
-- hl.bind("Print",         hl.dsp.exec_cmd("grim - | wl-copy"))
-- hl.bind("SHIFT + Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
