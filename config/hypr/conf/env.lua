-- Environment variables handed to every process Hyprland spawns.
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

---- Cursor ----
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

---- Toolkits ----
-- Qt apps: prefer Wayland, fall back to XWayland, and let Hyprland draw the
-- decorations instead of Qt drawing its own titlebar.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

---- NVIDIA ----
-- https://wiki.hypr.land/Nvidia/
-- These two are the only ones the wiki still requires. Old guides also list
-- GBM_BACKEND, WLR_NO_HARDWARE_CURSORS and XDG_SESSION_TYPE: those are
-- obsolete, do not add them back.
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- Electron / CEF apps (VS Code, Obsidian, Discord) flicker on NVIDIA because
-- they default to XWayland. This makes them run natively on Wayland.
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Hardware video decoding. Needs the libva-nvidia-driver package installed.
-- hl.env("NVD_BACKEND", "direct")

-- Hybrid laptops only (iGPU + dGPU): choose which card Hyprland renders on.
-- Run `ls -l /dev/dri/by-path` and put the card you want first.
-- hl.env("AQ_DRM_DEVICES", "/dev/dri/card1:/dev/dri/card0")
