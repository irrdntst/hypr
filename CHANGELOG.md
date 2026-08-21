# Changelog

Notable changes to Ampere, newest first. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/) adapted to a config:

- **major** — a change that breaks an existing setup: keybinds you had to
  relearn, a config file that moved, a package you must install by hand.
- **minor** — new capability: a program joins the stack, a feature appears.
- **patch** — fixes and adjustments that change nothing you have to know about.

While the version stays at `0.x`, minor releases are allowed to break things.
See [Road to 1.0](README.md#road-to-10) for what the first stable release means.

## [Unreleased]

### Changed

- **Dolphin replaces Thunar as the file manager.** `FILE_MANAGER` in
  `apps/defaults.env` is now `org.kde.dolphin.desktop`, so `inode/directory`
  in the generated `config/mimeapps.list` follows. `dolphin` joined
  `packages/pacman-apps.txt`, and the Thunar-only thumbnailer stack
  (`tumbler`, `ffmpegthumbnailer`) was swapped for the KDE one Dolphin
  actually uses: `kdegraphics-thumbnailers` and `ffmpegthumbs`. `gvfs` stays
  for the GTK apps' trash and network locations.
- Dolphin is the first Qt app in the standard set, and this config still does
  no Qt theming: outside a Plasma session it opens in Breeze light while
  everything else is dark. Writing a colour scheme to `~/.config/kdeglobals`
  is the fix, and it is not done yet.

### Removed

- `thunar`, `thunar-volman` and `thunar-archive-plugin`. The archive plugin
  put "Extract here" in the file manager's context menu; Dolphin takes that
  from `ark`, which is not installed because `xarchiver` remains the declared
  archiver. Archives still open in xarchiver on double-click, through
  `mimeapps.list`.

## [1.0.0] — 2026-08-21

The config has a name: **Ampere**. A fresh Arch machine reaches a working
desktop with one command and nothing added by hand.

### Fixed

- **Two keybinds never worked.** Hyprland matches keys case-insensitively, so
  `SUPER+L` (lock) and `SUPER+l` (focus right) were one combination, as were
  `SUPER+J` (flip split) and `SUPER+j` (focus down). In both pairs the
  navigation bind won and the other was dead. Lock moved to
  `SUPER+BackSpace`, flip-split to `SUPER+T`.
- `tests/check.lua` now normalises every bind — modifiers sorted, key
  upper-cased, submaps scoped separately — and fails on a collision, so this
  class of bug cannot come back silently.
- The README keybind table was missing `SUPER+P` and still advertised the old
  lock and split keys.

### Changed

- **Renamed to Ampere** across the installer banner, release titles and the
  text-editor desktop entry. `install.sh` removes the dangling pre-1.0
  `hypr-text-editor.desktop` link, and `tools/apps.sh` still recognises
  overrides written under the old marker.
- **One package list fewer.** `pacman-optional.txt` is gone: `playerctl` and
  the Noto fonts moved to the core list because active binds and correct text
  rendering need them, `pavucontrol` joined the applications, and
  `brightnessctl`, `nvtop`, `qt5-wayland` and `pipewire-alsa` were dropped —
  nothing referenced them. The `--optional` flag went with the list.
- Media keys (play/pause, next, previous) are bound for real instead of
  sitting commented out. Backlight keys were removed rather than left dead:
  this is a desktop, and a monitor exposes no backlight device.
- Waybar's volume module opens `pavucontrol` on click again.
- Focus binds are generated from an ordered list rather than `pairs()`, so the
  config produces the same result every load.

### Removed

- Commented-out binds and package references that no longer pointed anywhere:
  the hyprlauncher note, the backlight binds, the empty "worth adding" list in
  autostart.

## [0.4.0] — 2026-08-21

The system side: dual boot, the clock, and an AUR helper that keeps working.

### Added

- **`tools/grub-windows.sh`** — flips `GRUB_DISABLE_OS_PROBER`, which GRUB
  2.06 turned off by default, and regenerates `grub.cfg` so Windows appears in
  the menu. Backs up `/etc/default/grub`, reports whether an entry was really
  created, and names the three things that usually prevent it: Fast Startup,
  an unmounted EFI partition, BitLocker. `os-prober` and `ntfs-3g` joined the
  system package list, and README carries a hand-written menu entry for when
  detection fails anyway.
- **`tools/clock.sh`** — stops the time jumping by a few hours every other
  boot. Turns on network sync first so the correct time is what reaches the
  hardware clock, then sets the RTC to local time (the default, needs nothing
  from Windows) or to UTC with `--utc`, printing the registry command that
  teaches Windows to agree.
- **`tools/paru.sh`** — builds paru from source instead of installing
  `paru-bin`, whose prebuilt binary breaks with
  `libalpm.so.NN: cannot open shared object file` as soon as pacman moves
  ahead of it. Removes a leftover `paru-bin-debug` first, since it outlives
  `pacman -Rns paru-bin` and then collides over `/usr/lib/debug`; clones into
  a clean directory so `makepkg` cannot reinstall a stale build; enables
  `BottomUp`, `NewsOnUpgrade` and `CleanAfter` afterwards.

All three run as part of a plain `./install.sh`, and each is a no-op where it
does not apply — no GRUB, no Windows, no pacman. `--grub`, `--clock` and
`--paru` narrow a run to one of them.

## [0.3.0] — 2026-08-21

One program per job, and a launcher that only lists what exists.

### Added

- **Standard applications.** `apps/defaults.env` names the program for each
  job — Firefox, Thunar, imv, mpv, zathura, nvim, xarchiver — and
  `config/mimeapps.list` is generated from it, so a link always opens in the
  same browser and an image in the same viewer. `packages/pacman-apps.txt`
  installs them; `tools/apps.sh --check` confirms each declared entry exists.
- **`tools/apps.sh`** — audits the application menu and hides entries whose
  program is not installed, using standard `NoDisplay` overrides in
  `~/.local/share/applications`. Every override is marked, `--restore` undoes
  all of them, and re-running `--prune` unhides anything that came back.
  `apps/hidden.list` covers entries that are installed but are not
  applications. `install.sh` runs a prune at the end of an install.
- A text-editor desktop entry in `share/applications/`, so text files open in
  nvim inside kitty without cluttering the launcher.
- Releases are cut by CI. A new version heading here becomes a tag and a
  GitHub release once the checks pass; no one tags by hand.

### Changed

- `tools/theme.sh` is now `tools/render.sh`: it renders from
  `apps/defaults.env` as well as `theme/palette.env`.
- `install.sh` links loose files and desktop entries, not just directories, so
  `mimeapps.list` and `share/applications/` land in the right places. `--restore`
  covers them too.

### Fixed

- GTK apps stayed light. Two causes: naming `Adwaita-dark` as the theme leaves
  GTK on the light default unless `gnome-themes-extra` is installed, and the
  session script wrote gsettings keys whose schema
  (`gsettings-desktop-schemas`) was not in the package list, so it failed
  before setting anything. `settings.ini` now asks for plain Adwaita plus
  `prefer-dark`, which is dark with no extra package, both packages joined the
  core list, and the script checks for the schema and for the theme before
  using either.

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

[Unreleased]: https://github.com/irrdntst/hypr/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/irrdntst/hypr/compare/v0.4.0...v1.0.0
[0.4.0]: https://github.com/irrdntst/hypr/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/irrdntst/hypr/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/irrdntst/hypr/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/irrdntst/hypr/releases/tag/v0.1.0
