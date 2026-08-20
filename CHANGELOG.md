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

[Unreleased]: https://github.com/irrdntst/hypr/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/irrdntst/hypr/releases/tag/v0.1.0
