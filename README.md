<h1 align="center">hypr</h1>

<p align="center">
  A lean Hyprland setup for Arch — no blur, no shadows, no animations.<br>
  Just a compositor that gets out of the way.
</p>

<p align="center">
  <code>hyprland</code> · <code>waybar</code> · <code>wofi</code> · <code>kitty</code> · <code>mako</code>
</p>

---

Every effect that costs a frame is off by default. Borders are one pixel, gaps
are four, windows appear the instant you ask for them. If you later decide you
want motion back, a fast animation preset is sitting commented out at the
bottom of `conf/look.lua` — one uncomment away.

Written in **Lua**, not hyprlang: since Hyprland 0.55 hyprlang is deprecated and
the entry point is `~/.config/hypr/hyprland.lua`.
See the [configuration docs](https://wiki.hypr.land/Configuring/Start/).

## Quick start

```bash
git clone https://github.com/irrdntst/hypr ~/dotfiles
cd ~/dotfiles
./install.sh --packages --nvidia
```

Reboot, then from a tty:

```bash
start-hyprland
```

That's it. `SUPER+Return` opens a terminal, `SUPER+R` the launcher,
`SUPER+M` exits.

<details>
<summary><b>What the installer actually does</b></summary>

<br>

`install.sh` symlinks `config/*` into `~/.config/`. Anything already sitting
there is moved to `<name>.bak.<timestamp>` — nothing is ever deleted silently.
Re-running it is safe: links that already point here are left alone.

| Flag | Effect |
| --- | --- |
| `--dry-run`, `-n` | print every action, change nothing |
| `--packages` | install the core packages with pacman |
| `--nvidia` | install the NVIDIA packages |
| `--help`, `-h` | usage |

It honours `XDG_CONFIG_HOME`, so you can rehearse the whole thing in a
throwaway directory before touching your real config:

```bash
XDG_CONFIG_HOME=/tmp/hyprtest ./install.sh
```

</details>

## Keybinds

`SUPER` is the modifier throughout.

| Keys | Action |
| --- | --- |
| `SUPER + Return` | terminal (kitty) |
| `SUPER + R` | launcher (wofi) |
| `SUPER + Q` / `SUPER + SHIFT + Q` | close window / kill the process |
| `SUPER + M` | exit Hyprland |
| `SUPER + V` | toggle floating |
| `SUPER + F` / `SUPER + SHIFT + F` | fullscreen / maximize |
| `SUPER + C` | center window |
| `SUPER + J` | flip the split direction |
| `SUPER + h/j/k/l`, arrows | move focus |
| `SUPER + SHIFT + h/j/k/l` | move the window |
| `SUPER + Tab` | last window |
| `SUPER + 1..0` | switch workspace |
| `SUPER + SHIFT + 1..0` | send window to workspace |
| `SUPER + scroll` | cycle workspaces |
| `SUPER + S` / `SUPER + SHIFT + S` | scratchpad |
| `SUPER + LMB` / `SUPER + RMB` | drag / resize with the mouse |
| `SUPER + ALT + R` | resize mode (`Esc` to leave) |
| media keys | volume, mic, brightness, playback |

Keyboard layout toggles with `Alt + Shift` (`us` ⇄ `ru`).

## Layout

```
config/hypr/hyprland.lua      entry point — nothing but require()
config/hypr/conf/
    env.lua                   environment variables, NVIDIA block
    monitors.lua              displays
    look.lua                  palette, decorations, animations
    input.lua                 keyboard, mouse, touchpad
    rules.lua                 window and layer rules
    keybinds.lua              every bind
    autostart.lua             what starts with the session
config/{waybar,wofi,kitty,mako}/
install.sh                    symlinks and packages
packages/                     pacman package lists
tests/check.lua               offline config check
```

Each `require()` gets its own Lua scope, so a mistake in one file doesn't take
the rest of the config down with it. Machine-specific tweaks go in
`~/.config/hypr/local.lua`, which is loaded last and stays out of git.

## Checking the config without Hyprland

```bash
lua tests/check.lua
```

This builds a stub `hl` global mirroring the documented API, then executes the
config against it. Syntax errors, misspelled `hl.*` functions, unknown
dispatchers and unknown config sections all fail the run — no compositor
required. It can't validate individual option *values*; only Hyprland can.

Configs reload the moment you save them. To reload by hand: `hyprctl reload`.
To see what Hyprland objected to: `hyprctl configerrors`. And if you break the
config badly, Hyprland still hands you emergency binds — `SUPER+Q` for a
terminal, `SUPER+R` to run something, `SUPER+M` to get out.

## NVIDIA

Two environment variables carry the whole thing (`conf/env.lua`):
`LIBVA_DRIVER_NAME=nvidia` and `__GLX_VENDOR_LIBRARY_NAME=nvidia`, plus
`ELECTRON_OZONE_PLATFORM_HINT=auto` to stop Electron apps from flickering.

Older guides also recommend `GBM_BACKEND`, `WLR_NO_HARDWARE_CURSORS` and
`XDG_SESSION_TYPE`. Those are obsolete — don't add them back.

`nvidia_drm modeset=1` is already enabled on Arch. Verify with:

```bash
cat /sys/module/nvidia_drm/parameters/modeset   # prints Y
```

If the cursor flickers or vanishes, uncomment `no_hardware_cursors` in
`conf/look.lua`. Full details on the [Hyprland NVIDIA page](https://wiki.hypr.land/Nvidia/).

## Roadmap

The skeleton is deliberately bare. Placeholders are already commented in place
for the next layer:

- [ ] `hyprlock` + `hypridle` — screen lock and idle handling
- [ ] `hyprpaper` — wallpapers
- [ ] `grim` + `slurp` — screenshots (binds waiting in `keybinds.lua`)
- [ ] `cliphist` — clipboard history
- [ ] one shared palette file instead of four hand-synced copies
- [ ] Nerd Font icons in waybar instead of text labels
