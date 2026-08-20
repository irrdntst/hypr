# Changelog

Notable changes to this config, newest first. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/) adapted to a config:

- **major** — a change that breaks an existing setup: keybinds you had to
  relearn, a config file that moved, a package you must install by hand.
- **minor** — new capability: a program joins the stack, a feature appears.
- **patch** — fixes and adjustments that change nothing you have to know about.

While the version stays at `0.x`, minor releases are allowed to break things.
See [Road to 1.0](README.md#road-to-10) for what the first stable release means.

## [Unreleased]

## [0.2.0] — 2026-08-20

Everything on the road to 1.0 except a verified clean install.

### Added

- **One palette** in `theme/palette.env`, with `tools/theme.sh` rendering
  `look.lua`, `hyprlock.conf`, waybar, wofi, kitty and mako from templates.
  Change `ACCENT` once instead of editing four files and missing one.
- **Screen lock**: hyprlock styled from the palette on `SUPER+L`, hypridle
  locking after 10 minutes idle and blanking the display after 15. Fullscreen
  windows inhibit both.
- **Screenshots** on `Print`, `SHIFT+Print` and `ALT+Print` — screen, region
  and focused window — each landing on the clipboard, in
  `~/Pictures/Screenshots`, and in a notification.
- **Clipboard history** through cliphist, browsed with wofi on
  `SUPER+SHIFT+V`.
- **Dark GTK apps**: `gtk-3.0`/`gtk-4.0` settings plus the gsettings keys that
  GTK4 and the XDG portal read, applied at session start. Adwaita cursor set
  through `XCURSOR_THEME`.
- **`tests/check.sh`** — one command for every off-compositor check: config,
  theme drift, JSON, shell syntax, shellcheck, executable bits.
- **CI** running those checks on every push.

### Changed

- The config check now follows a program launched behind a terminal's `-e`,
  reads waybar `exec` values, and verifies that scripts the config references
  exist in the repo and are executable.
- `wl-clipboard` moved from optional to core; the screenshot and clipboard
  features depend on it.

### Notes

Nerd Font icons in waybar were dropped rather than deferred: an unavailable
glyph renders as an empty box, text labels never do.

## [0.1.0] — 2026-08-20

The skeleton: a working Hyprland desktop, installed by one command.

### Added

- **Hyprland config in Lua**, split into `conf/*.lua` modules loaded with
  `require()` so an error in one file cannot take down the rest. Written
  against the 0.55+ API, where hyprlang is deprecated.
- **The stack**: waybar, wofi, kitty and mako, all sharing one palette.
- **Look**: no blur, no shadows, no rounding, no animations — every effect
  that costs a frame is off. A fast animation preset waits commented out in
  `conf/look.lua`.
- **73 keybinds**: windows, workspaces, groups (tabbed containers), a
  scratchpad, a resize submap, volume keys, notification controls.
- **NVIDIA support** following the current wiki: two environment variables
  plus the Electron fix, and none of the obsolete advice.
- **Wallpaper** through hyprpaper, with a gradient generated to match the
  palette.
- **Resource monitor** on `SUPER+Escape`: btop with CPU, RAM, GPU and
  processes, in a floating window. Waybar's cpu, ram and gpu readouts open it
  on click.
- **Bluetooth, network and USB**: bluez, blueman, NetworkManager and udiskie,
  with tray applets started only when they are actually installed.
- **`install.sh`** — installs everything with no flags, detects NVIDIA rather
  than asking, backs up whatever it replaces, and can undo itself with
  `--restore`.
- **`tests/check.lua`** — runs the config against a stub `hl` API without a
  compositor, and verifies every program the config invokes is covered by a
  package list.

[Unreleased]: https://github.com/irrdntst/hypr/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/irrdntst/hypr/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/irrdntst/hypr/releases/tag/v0.1.0
