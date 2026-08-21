<h1 align="center">Ampere</h1>

<p align="center">
  A lean Hyprland desktop for Arch — no blur, no shadows, no animations.<br>
  One command installs it, one file holds the colours, and every keybind works.
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
./install.sh
```

One command, no flags: it installs every package list, enables the bluetooth
daemon, and links the configs.

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

Run with no arguments it does everything: packages, the standard
applications, bluetooth and network tooling, NVIDIA drivers when a card is
present, a GRUB entry for Windows, the dual-boot clock fix, paru built from
source, then the symlinks. The flags are there to do *less*.

| Flag | Effect |
| --- | --- |
| `--dry-run`, `-n` | print every action, change nothing |
| `--links-only` | symlinks only, install nothing |
| `--restore` | remove our links and put the backed-up configs back |
| `--packages` / `--system` / `--apps` / `--nvidia` | narrow the install to that one list |
| `--grub` / `--clock` / `--paru` | run just that one system step |
| `--help`, `-h` | usage |

The NVIDIA list is skipped automatically when no NVIDIA card is found — the
check reads `lspci`, falling back to the PCI vendor id in sysfs on systems
without pciutils. Pass `--nvidia` to install it anyway.

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
| `SUPER + Escape` | resource monitor (btop: processes, CPU, RAM, GPU) |
| `SUPER + BackSpace` | lock the screen |
| `SUPER + Q` / `SUPER + SHIFT + Q` | close window / kill the process |
| `SUPER + M` | exit Hyprland |
| `SUPER + V` | toggle floating |
| `SUPER + F` / `SUPER + SHIFT + F` | fullscreen / maximize |
| `SUPER + C` | center window |
| `SUPER + P` | pseudotile (dwindle: keep the window's own size in the layout) |
| `SUPER + SHIFT + P` | pin a floating window to every workspace |
| `SUPER + T` | flip the split direction |
| `SUPER + h/j/k/l`, arrows | move focus |
| `SUPER + SHIFT + h/j/k/l` | move the window |
| `SUPER + Tab` | last window |
| `SUPER + G` | group windows into tabs |
| `SUPER + ALT + h/l` | previous / next tab in the group |
| `SUPER + 1..0` | switch workspace (again returns to the previous one) |
| `SUPER + SHIFT + 1..0` | send window to workspace |
| `SUPER + scroll` | cycle workspaces |
| `SUPER + S` / `SUPER + SHIFT + S` | scratchpad |
| `SUPER + LMB` / `SUPER + RMB` | drag / resize with the mouse |
| `SUPER + ALT + R` | resize mode (`Esc` to leave) |
| `SUPER + SHIFT + V` | clipboard history |
| `Print` / `SHIFT + Print` / `ALT + Print` | screenshot: screen / region / window |
| `SUPER + N` / `SUPER + SHIFT + N` | dismiss notifications / do-not-disturb |
| `SUPER + SHIFT + R` | reload the config |
| volume and media keys | volume, mic, play/pause, next, previous |

Keyboard layout toggles with `Alt + Shift` (`us` ⇄ `ru`).

## Layout

```
config/hypr/hyprland.lua      entry point — nothing but require()
config/hypr/hyprpaper.conf    wallpaper      (hyprlang, not Lua)
config/hypr/hyprlock.conf     lock screen    (generated from the palette)
config/hypr/hypridle.conf     idle timeouts
config/hypr/wallpapers/       the default wallpaper lives here
config/hypr/scripts/          screenshot and GTK theme helpers
config/hypr/conf/
    env.lua                   environment variables, NVIDIA block
    monitors.lua              displays
    look.lua                  palette, decorations, animations
    input.lua                 keyboard, mouse, touchpad
    rules.lua                 window and layer rules
    keybinds.lua              every bind
    autostart.lua             what starts with the session
config/{waybar,wofi,kitty,mako}/
config/gtk-3.0, gtk-4.0/      dark theme for GTK apps
config/mimeapps.list          which program opens what (generated)
share/applications/           desktop entries this repo ships
apps/defaults.env             the standard program for each job
apps/hidden.list              entries to keep out of the launcher
theme/palette.env             the one place colours are defined
theme/templates/              sources for every generated config
tools/render.sh               renders the templates
tools/apps.sh                 audits and prunes the launcher
tools/grub-windows.sh         makes GRUB offer Windows
tools/clock.sh                stops the dual-boot clock drift
tools/paru.sh                 builds the AUR helper from source
install.sh                    symlinks and packages
packages/pacman.txt           hard dependencies — the config breaks without them
packages/pacman-system.txt    bluetooth, network, dual boot, removable drives
packages/pacman-apps.txt      the standard applications
packages/pacman-nvidia.txt    driver and video acceleration
tests/check.lua               offline config check
```

Each `require()` gets its own Lua scope, so a mistake in one file doesn't take
the rest of the config down with it. Machine-specific tweaks go in
`~/.config/hypr/local.lua`, which is loaded last and stays out of git.

## Checking the config without Hyprland

```bash
tests/check.sh
```

One command for everything verifiable off a compositor: the config itself, the
theme, JSON syntax, shell syntax, shellcheck and the executable bits. Missing
tools are reported as skipped, so it runs anywhere. The same script runs in CI
on every push.

The config check underneath it is `tests/check.lua`:

This builds a stub `hl` global mirroring the documented API, then executes the
config against it. Syntax errors, misspelled `hl.*` functions, unknown
dispatchers and unknown config sections all fail the run — no compositor
required.

It also collects every shell command the config runs, keybinds and waybar
click actions alike, and checks that each program is covered by one of the
`packages/*.txt` lists. That is what stops a keybind from quietly calling
something nobody installs.

What it can't do is validate individual option *values* — only Hyprland can.

Configs reload the moment you save them. To reload by hand: `hyprctl reload`.
To see what Hyprland objected to: `hyprctl configerrors`. And if you break the
config badly, Hyprland still hands you emergency binds — `SUPER+Q` for a
terminal, `SUPER+R` to run something, `SUPER+M` to get out.

## Bluetooth and the tray

`./install.sh` installs these and enables the daemon itself. Installing
`bluez` alone does not start it, and `blueman` shows an empty window until it
runs, so the installer does it for you:

```bash
sudo systemctl enable --now bluetooth.service
```

That pulls in three tray applets: `blueman-applet` for bluetooth, `nm-applet`
for the network, and `udiskie` for USB drives. `conf/autostart.lua` launches
each one only if it is actually installed, so the same config works on a
machine with none of them. Waybar gains a bluetooth module that hides itself
when the machine has no controller, and clicking the network module opens
`nm-connection-editor`.

## Wallpaper and monitoring

The wallpaper is a plain gradient generated to match the palette, sitting at
`config/hypr/wallpapers/default.png`. Drop your own image in that directory and
point `hyprpaper.conf` at it, or point `path` at the directory itself to
rotate through every image in it on a timer — the commented block in that file
shows both.

`hyprpaper.conf` is still hyprlang, not Lua: only `hyprland.conf` moved to Lua
in 0.55, the rest of the ecosystem kept its old format.

`SUPER + Escape` opens btop in a floating window: processes, CPU, RAM, disks,
network and, on this machine, the NVIDIA GPU — btop from the Arch repos is
built with GPU support and reads the card through `nvidia-ml`. Waybar's cpu,
ram and gpu readouts open the same window when clicked. For deeper GPU detail
run `nvidia-smi` or install `nvtop`.

## Colours

Every colour lives in [`theme/palette.env`](theme/palette.env) — eight semantic
names plus the sixteen terminal ones. The configs that carry colour are
generated from templates in `theme/templates/`:

```bash
vim theme/palette.env
tools/render.sh           # rewrite the generated configs
tools/render.sh --diff    # or see what would change first
```

That covers `conf/look.lua`, `hyprlock.conf`, waybar, wofi, kitty and mako —
change `ACCENT` once and the focused window border, the bar's clock, the
selection colour and the lock screen all follow. `tests/check.sh` fails if a
generated file drifts from the palette, so an edit made in the wrong place
gets caught rather than silently overwritten later.

Files carry a `GENERATED` header naming the template that produced them.

## Locking, screenshots and the clipboard

`SUPER + BackSpace` locks the screen through `loginctl lock-session`, which hypridle
turns into a hyprlock window. Left alone, the session locks itself after ten
minutes and blanks the display after fifteen — timeouts live in
`hypridle.conf`. Fullscreen windows inhibit all of it, so a film is not
interrupted. There is no automatic suspend; the commented listener at the
bottom of that file adds one.

`Print` grabs the screen, `SHIFT+Print` a region you drag, `ALT+Print` the
focused window. Each one lands on the clipboard *and* in
`~/Pictures/Screenshots`, and raises a notification with the file name.

`SUPER + SHIFT + V` opens the clipboard history in wofi — cliphist records
everything you copy, and picking an entry puts it back on the clipboard.

## Standard applications

One program per job, declared in [`apps/defaults.env`](apps/defaults.env):

| Job | Program |
| --- | --- |
| browser | Firefox |
| files | Dolphin |
| images | imv |
| video and audio | mpv |
| PDF | zathura |
| text | nvim in kitty |
| archives | xarchiver |

`tools/render.sh` turns that into `config/mimeapps.list`, so a link opens in
one browser and an image in one viewer — no "open with" roulette. To swap a
default, change the desktop id there and re-render:

```bash
vim apps/defaults.env
tools/render.sh
tools/apps.sh --check     # confirms each id actually exists on this machine
```

## Keeping the launcher honest

wofi lists every `.desktop` file on the system, including entries whose
program was never installed, ones left behind by a package you removed, and
helpers that are not applications at all.

```bash
tools/apps.sh             # what is listed, and what is stale
tools/apps.sh --prune     # hide the stale ones
tools/apps.sh --restore   # undo all of it
```

An entry counts as stale when the program in its `TryExec`, or the first word
of its `Exec`, is not on `PATH`. Hiding writes a same-named file into
`~/.local/share/applications` with `NoDisplay=true`, which shadows the system
entry — nothing is deleted, and every override is marked so `--restore` knows
which files are ours. Entries that are installed but still do not belong in a
menu are listed in [`apps/hidden.list`](apps/hidden.list).

`--prune` also works in reverse: reinstall a program and it unhides the entry
again. `install.sh` runs it once at the end of an install.

## Dual boot

`install.sh` runs both of these; each is a no-op on a machine that does not
need it.

```bash
tools/grub-windows.sh --check    # what GRUB currently knows
tools/grub-windows.sh            # enable os-prober and regenerate grub.cfg
```

Since GRUB 2.06 `GRUB_DISABLE_OS_PROBER` defaults to `true`, so a perfectly
working dual-boot setup shows no Windows entry until that one line is flipped.
The script backs up `/etc/default/grub`, sets it to `false`, regenerates
`grub.cfg` and tells you whether a Windows entry actually appeared. When it
does not, the usual culprits are Windows Fast Startup (`powercfg /h off`), an
EFI partition that is not mounted, or BitLocker.

If detection stays stubborn, write the entry yourself. Take the UUID of the
partition holding `bootmgfw.efi` from `blkid`, and add to
`/etc/grub.d/40_custom`:

```
menuentry "Windows Boot Manager" --class windows {
    insmod part_gpt
    insmod fat
    insmod chain
    search --no-floppy --fs-uuid --set=root YOUR-UUID
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
```

### The clock

```bash
tools/clock.sh           # Linux yields: hardware clock in local time
tools/clock.sh --utc     # Windows yields: prints the registry command to run
tools/clock.sh --check   # which way it is set now
```

Windows expects the hardware clock to hold local time, Linux expects UTC, and
whichever boots second "fixes" it — so the time is wrong every other boot. One
side has to give way. The default is the Linux side, because it needs nothing
from Windows. `--utc` is the tidier answer if you are willing to set one
registry key, and it survives daylight saving properly.

The script turns on network time sync first, so the correct time is what gets
written to hardware. It also falls back from `timedatectl` to `hwclock` when
the D-Bus call times out, which it does in some sessions.

## The AUR helper

```bash
tools/paru.sh
```

Built from source rather than installed as `paru-bin`: the prebuilt package is
linked against one specific `libalpm`, and once pacman moves ahead of it the
binary stops starting with `libalpm.so.NN: cannot open shared object file`. A
local build always matches the pacman you have.

The script removes a previously installed `paru-bin` first — including
`paru-bin-debug`, which survives `pacman -Rns paru-bin` and then collides with
the source package over `/usr/lib/debug`. It clones into a fresh directory,
because `makepkg` will otherwise reinstall a stale package it built earlier
instead of building the current source. Afterwards it enables `BottomUp`,
`NewsOnUpgrade` and `CleanAfter` in `/etc/paru.conf`.

`makepkg` shows you the PKGBUILD before building. Read it — the AUR is not
moderated.

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

## Versioning

Versions are git tags, `v0.1.0` and up, with the reasoning behind each release
in [CHANGELOG.md](CHANGELOG.md). Nobody tags by hand: add a version heading to
the changelog, push to `main`, and CI runs the checks, creates `v<version>`
and publishes a release with that section as the notes. A version that is
already tagged is left alone, so ordinary pushes do nothing. Semantic versioning, read for a config: major
means you have to relearn or reinstall something, minor means a new capability,
patch means a fix you can ignore. Below `1.0` a minor release may still break
things.

```bash
git describe --tags        # which version you are on
git log --oneline v0.1.0.. # what landed since
```

## What 1.0 means

A fresh Arch machine reaches a working desktop with one command and nothing
added by hand. Everything on the original checklist is in:

- [x] `hyprlock` + `hypridle` — screen lock and idle handling
- [x] `grim` + `slurp` — screenshots
- [x] `cliphist` — clipboard history
- [x] dark GTK theming
- [x] one shared palette file instead of hand-synced copies
- [x] checks running in CI on every push
- [x] one standard program per job, and a launcher that lists only what exists
- [x] dual boot: a Windows entry in GRUB and a clock that stops drifting
- [x] an AUR helper that survives a pacman upgrade
- [x] a full install verified end to end on a clean machine

Ideas that were considered and deliberately left out: Nerd Font icons in
waybar (a glyph the font lacks renders as an empty box; text labels never do),
and Qt theming — though Dolphin now makes that last one an open question: it
is the only Qt app in the set, and outside a Plasma session it comes up in
Breeze light until a colour scheme is written to `~/.config/kdeglobals`.
