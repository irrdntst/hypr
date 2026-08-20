-- Hyprland entry point.
-- Docs: https://wiki.hypr.land/Configuring/Start/
--
-- Everything lives in conf/*.lua. Each require() gets its own Lua scope, so an
-- error in one file does not abort the rest of the config.
-- Order matters: env before the processes that inherit it, autostart last.

require("conf/env")
require("conf/monitors")
require("conf/look")
require("conf/input")
require("conf/rules")
require("conf/keybinds")
require("conf/autostart")

-- Machine-local overrides, not tracked by git. Create ~/.config/hypr/local.lua
-- for anything specific to one machine (monitor layout, extra binds).
local ok, err = pcall(require, "local")
if not ok then
    -- Only complain if the file exists but is broken; a missing file is fine.
    local f = io.open(os.getenv("HOME") .. "/.config/hypr/local.lua", "r")
    if f then
        f:close()
        print("hyprland.lua: local.lua failed to load: " .. tostring(err))
    end
end
