# chawal

My Hyprland rice (Arch Linux, Hyprland 0.56 with the Lua config): configs,
themes, icons and fonts, linked into `$HOME` with GNU Stow. Catppuccin Mocha
and Latte, one Waybar, one eww daemon, swaync notifications, a rofi control hub.

- [Install](#install)
- [Packages](#packages)
- [Layout](#layout)
- [How theming and state work](#how-theming-and-state-work)
- [Keybinds](#keybinds)
- [Rofi control hub](#rofi-control-hub)
- [Quick-settings panel](#quick-settings-panel)
- [Themes (Mocha / Latte)](#themes-mocha--latte)
- [Right-edge gauges](#right-edge-gauges)
- [Troubleshooting and rollback](#troubleshooting-and-rollback)

## Install

**The repo must live at `~/dotfiles`.** Stow makes relative links
(`~/.config/hypr -> ../dotfiles/config-hypr/.config/hypr`), and `stow.sh` only
accepts links of that form, so a clone anywhere else breaks them. A few files
also hold an absolute `/home/ushtro/...` path: see
[hard-coded paths](#hard-coded-paths).

```sh
git clone https://github.com/anubhab7111/chawal ~/dotfiles
cd ~/dotfiles
sudo pacman -S --needed stow          # then the packages below
./stow.sh                             # link every package into $HOME
sudo ./system/install.sh              # udev rule (needs root)
~/.config/rice/bin/rice-theme bootstrap
```

Then log out and back in (a session started before the Qt environment variable
existed will not have it).

- `stow.sh` links each `config-*` and `home-*` directory into `$HOME`. A real
  file already at a target path is moved to a timestamped folder under
  `~/.dotfiles-backup/` first, never deleted. Running it again is safe.
- `system/install.sh` installs `system/etc/udev/rules.d/70-dri-stable.rules`
  into `/etc` (stable `/dev/dri/intel-igpu` and `/dev/dri/nvidia-dgpu` names;
  Hyprland picks the Intel iGPU as primary through them, see
  `config-hypr/.config/hypr/modules/env.lua`). `stow.sh` never links `system/`
  into `$HOME`. It is only for the dual-GPU laptop this was built on; skip it
  on other hardware and drop the `AQ_DRM_DEVICES` line from `env.lua`.
- `rice-theme bootstrap` creates the state directory and the slot links
  described below. Autostart runs it at every login too, so you only need it by
  hand the first time (and after pulling changes that add a slot).

## Packages

Names are Arch packages; `(AUR)` ones come from the AUR (for example with
`yay -S`).

| Area | Packages |
|---|---|
| Compositor | `hyprland` `hyprlock` `hypridle` `hyprsunset` `hyprshot` `hyprpicker` `xdg-desktop-portal-hyprland` `polkit-kde-agent` |
| Bar, widgets | `waybar-git` (AUR; the 0.15.0 release sends legacy dispatches that the Lua parser rejects) `eww` (AUR) `swaync` |
| Launchers, wallpaper | `rofi` `awww` (wallpaper daemon; plays gifs) `mpvpaper` (video wallpapers) `cliphist` `wl-clipboard` `imv` |
| Terminal, shell | `alacritty` `tmux` `yazi` `btop` `cava` `fastfetch` `starship` `neovim` |
| Audio, media | `pamixer` `playerctl` `pwvucontrol` (AUR) `brightnessctl` |
| Network, Bluetooth | `networkmanager` `network-manager-applet` `iw` (the Wi-Fi name in the quick settings) `bluez` `bluez-utils` `blueman` |
| Capture | `grim` `slurp` `wf-recorder` |
| Power, night light | `wlogout` `tlp` `tlp-pd` (profiles; enable `tlp.service`) `batsignal` `darkman` |
| Theming | `qt6ct` `kvantum` `kvantum-theme-catppuccin-git` (AUR) `catppuccin-gtk-theme-mocha` and `catppuccin-gtk-theme-latte` (AUR) `bibata-cursor-theme` (AUR) `nwg-look` `ttf-jetbrains-mono-nerd` |
| Icons | `candy-icons`, installed by hand into `~/.local/share/icons/` (it is what `gtk-icon-theme` in each theme names) |
| Apps the binds start | `thunar`, `firefox`, `chromium`, `vscodium`, `obsidian`, `zapzap` (AUR), `claude-desktop` (change them at the top of `config-hypr/.config/hypr/modules/binds.lua`) |

Packages by phase of the build-out, for reference: the Lua Hyprland config and
`rice-*` scripts need only the compositor, bar and launcher rows; the rofi hub
adds `cliphist`; the quick-settings panel adds `eww` and `swaync`; the Latte
theme adds the Latte GTK theme; Qt theming adds the three Qt packages; power
profiles add `tlp-pd`; battery warnings add `batsignal`.

## Layout

Each top-level directory is a GNU Stow package: `config-*` packages hold one
directory under `.config`, `home-*` packages hold one dotfile or directory
directly under `$HOME`.

- `config-hypr` — Hyprland (Lua: `hyprland.lua` plus `modules/`), hyprlock, hypridle
- `config-waybar` — bar
- `config-swaync` — notifications and the control centre
- `config-rofi` — launcher and the control hub theme (`config-wofi` is a leftover, unused)
- `config-wlogout` — the power grid (`layout`, `style.css`; its icons are per theme)
- `config-eww` — quick-settings panel and the right-edge gauges
- `config-rice` — the `rice-*` scripts (`~/.config/rice/bin`)
- `config-theming` — the themes (`themes/mocha`, `themes/latte`) and the `current` slot
- `config-nwg-look`, `config-gtk-2.0`, `config-gtk-3.0`, `config-gtk-4.0`,
  `config-gtkrc`, `config-gtkrc-2.0`, `home-gtkrc-20` (`~/.gtkrc-2.0`) — GTK
- `config-qt6ct`, `config-kvantum` — Qt
- `config-alacritty`, `config-tmux` — terminal
- `config-btop`, `config-cava`, `config-fastfetch`, `config-starship.toml`, `config-yazi`, `config-imv` — tools
- `config-darkman`, `home-darkman-hooks` — darkman (night-light hook for Kolkata)
- `home-fonts`, `home-icons`, `home-themes`, `home-xinitrc`
- `system` — files that need root (`system/install.sh`); never linked into `$HOME`

### Hard-coded paths

A few files contain an absolute `/home/ushtro/` (eww and Qt cannot expand `~`
in these places): `config-eww/.config/eww/eww.css`,
`config-qt6ct/.config/qt6ct/qt6ct.conf`, the wallpaper lines in
`config-theming/.config/theming/themes/*/wallpaper.conf`, and the GTK
bookmarks and `~/.gtkrc-2.0`. On another user name, replace that prefix
(`grep -rl /home/ushtro config-* home-*`).

## How theming and state work

Nothing tracked in git is ever edited at runtime. Everything that changes
lives in `~/.local/state/rice` and in gitignored **slot links** inside the
stowed packages.

- A theme is a directory in `config-theming/.config/theming/themes/<name>`
  with one file per consumer: `waybar-colors.css` (also used by swaync and eww),
  `rofi-colors.rasi`, `hyprland.lua`, `hyprlock-colors.conf`,
  `alacritty-colors.toml`, `btop.theme`, `cava.theme`, `tmux-colors.conf`,
  `obsidian-colors.css`, `qt6ct-colors.conf`, `kde-colors.colors`, plus
  `wallpaper.conf`, `gtk-icon-theme`, `gtk-theme`, `color-scheme`,
  `kvantum-theme`, and `wlogout-icons/` (the power-grid icons, drawn from each
  theme's palette by `tools/gen-wlogout-icons.py`; re-run it after a palette
  edit). wlogout reads the colours and icons straight from
  `~/.config/theming/current`, so it needs no slot link of its own.
- `~/.local/state/rice/theme` holds the active name; `~/.local/state/rice/current`
  links to its directory, and `~/.config/theming/current` links to that.
- `rice-theme bootstrap` points the slots at `current`: `waybar/colors.css`,
  `swaync/colors.css`, `cava/themes/rice`, `btop/themes/rice.theme`,
  `rofi/themes/colors.rasi`, `tmux/colors.conf`, `qt6ct/colors/rice.conf`, the
  GTK4 css links, and the Kvantum and KDE settings. All of these are in
  `.gitignore`, which is why `git status` stays clean after a switch.
- `rice-theme apply NAME` re-points everything, then reloads what can be
  reloaded live (Hyprland, Waybar, eww, swaync, tmux, cava, neovim, Obsidian,
  the wallpaper). `toggle` flips Mocha and Latte, `get` prints the active
  theme, `list` the available ones.
- The Hyprland Lua config reads its palette through `~/.config/theming/current`
  and falls back to `modules/fallback_palette.lua` if the theme file is
  missing, so a broken theme can never stop Hyprland starting.
- Runtime flags (game mode, caffeine, night light) live in
  `$XDG_RUNTIME_DIR/rice`, so they reset on reboot.

## Keybinds

`SUPER` is the main modifier. Everything is in
`config-hypr/.config/hypr/modules/binds.lua` unless noted.

| Keys | Action |
|---|---|
| `SUPER+Q` / `E` / `B` / `SHIFT+B` | alacritty / Thunar / Firefox / Chromium |
| `SUPER+SHIFT+C` / `Z` / `O` / `SHIFT+A` | VSCodium / WhatsApp (zapzap) / Obsidian / Claude desktop |
| `SUPER+A` | pwvucontrol (audio) |
| `SUPER+SPACE` | rofi control hub (apps, windows, clipboard) |
| `SUPER+SHIFT+V` | hub on the Clip tab |
| `SUPER+W` | wallpaper grid (picks are remembered per theme and output; `h` toggles the hidden walls) |
| `SUPER+N` | quick-settings panel (also the top-right corner) |
| `SUPER+Esc` | power grid (wlogout; also the Waybar power button) |
| `SUPER+L` | lock |
| `SUPER+C` | close window |
| `SUPER+V` | toggle floating |
| `SUPER+F` / `SHIFT+F` | maximize (keeps the bar) / fullscreen |
| `SUPER+P` | pseudotile |
| `SUPER+arrows` / `SHIFT+arrows` | focus / move window |
| `SUPER+1…0` / `SHIFT+1…0` | go to / move to workspace |
| `SUPER+mouse wheel` | next / previous workspace |
| `SUPER+left drag` / `right drag` | move / resize a window |
| `SUPER+R` | resize mode (arrows, then `Esc` or `R`) |
| `SUPER+S` / `SHIFT+S` | magic scratchpad / send window to it |
| `SUPER+grave` / `T` / `M` | drop-down terminal / terminal / music scratchpads |
| `SUPER+F1` | game mode |
| `SUPER+=` / `-` / `SHIFT+-` | screen zoom in / out / reset |
| `SUPER+SHIFT+T`, touchpad key | toggle the touchpad (`modules/lid.lua`) |
| `Print` / `SHIFT+Print` / `SUPER+Print` | screenshot screen / region / window (hyprshot) |
| `Ctrl+Print` / `Ctrl+Shift+Print` | record region / screen (`rice-record`; click the red Waybar pill to stop) |
| volume, mic mute, brightness keys | change the level and flash its edge gauge |
| media keys | `playerctl` |
| `Esc` | closes the quick-settings panel while it is open (`modules/qs.lua`) |

Hot corners (`modules/pointer.lua`): top-left opens the rofi window list,
top-right the quick-settings panel; the right edge slides out the gauges.

## Rofi control hub

`SUPER+SPACE` opens one rofi window with three tabs. `Tab` / `Shift+Tab`
(or `Ctrl+Tab`) flip between them; `Alt+1` … `Alt+5` are the per-row actions
of whichever tab is showing. The scripts live in `config-rice/.config/rice/bin`;
`rice-hub` is the launcher and the Windows and Clip tabs are `rice-*` scripts
running as a rofi script mode (each also works on its own: `rice-windows`, …).

| Tab | Script | Enter | Alt+1 … Alt+5 |
|---|---|---|---|
| Apps | rofi `drun` | launch | |
| Windows | `rice-windows` | focus | close · float · pin · bring here |
| Clip | `rice-clip` | copy entry back | delete · wipe all (also Ctrl+Delete, Ctrl+Shift+Delete) |

Wi-Fi and Bluetooth are not tabs: each is a small rofi window of its own, so
they never mix with apps, windows or the clipboard.

| Window | Script | Enter | Alt+1 … Alt+2 |
|---|---|---|---|
| Wi-Fi | `rice-net` | connect / disconnect | forget · rescan |
| Bluetooth | `rice-bt` | connect / disconnect | power · unpair |

`rice-hub net` and `rice-hub bt` open them (so do the Waybar Wi-Fi and Bluetooth
pills and the right-click on the quick-settings tiles).

Direct jumps: `SUPER+SHIFT+V` clipboard, the top-left hot corner opens Windows,
and the Waybar Wi-Fi and Bluetooth pills open their windows. The wallpaper grid
(`rice-wall`, `SUPER+W`) is a separate rofi menu, not a hub tab: it grids
`~/Pictures/Wallpapers` (gifs and videos included), and `h` flips it to `.hidden`
inside that dir and back (a fresh launch always starts on the visible walls); the power menu
is no longer rofi at all — `SUPER+Esc` and the Waybar power button run
`wlogout -b 5 -L 380 -R 380 -T 410 -B 410`, from the `config-wlogout` package
(`layout`, `style.css`): five buttons in one row (wlogout draws a blank tile when
the count does not fill its rows) and margins that make the ring panel hug the
tiles. Each tile is glass with a coloured icon and fills with its Waybar pill
gradient on focus or hover (Lock green, Exit Session mauve, Shut Down red,
Suspend yellow, Restart blue), inside the Hyprland mauve/blue/teal ring; colours
and icons follow the theme. The layer rule in `rules.lua` uses wlogout's real
namespace, `logout_dialog`, for the blur, dim and pop-in. There is no Hibernate button: this machine has
no resume set up (no `resume` initramfs hook, no `resume=`), so hibernating just
powers off and the session is lost. Exit Session runs `hl.dsp.exit()`; the old
`hyprctl dispatch exit` is a Lua error on this Hyprland.

Suspend needs two system settings that are not in these dotfiles (this HP laptop
with an NVIDIA GPU): `sudo systemctl enable nvidia-suspend nvidia-resume
nvidia-hibernate` (the driver keeps video memory across sleep, which those units
save and restore), and the embedded controller must not wake the machine, as it
fires about 80 events a second and woke suspend at once. That is
`echo 'w /sys/module/acpi/parameters/ec_no_wakeup - - - - Y' | sudo tee
/etc/tmpfiles.d/ec-no-wakeup.conf`. If the screen stays frozen after a resume,
power-cycling it from another tty brings it back: `hyprctl dispatch
'hl.dsp.dpms({ action = "disable" })'`, then the same with `"enable"`.
The old rofi `rice-power` script is still in `config-rice` but nothing calls it.
Optional dependency: `cliphist` + `wl-clipboard` (Clip). Switches live in the
quick-settings panel (`SUPER+N`) and the sliders in the right-edge gauges, not
here.

Look: the theme is `config-rofi/.config/rofi/themes/rice.rasi`, coloured from
`~/.config/theming/current/rofi-colors.rasi`, so `rice-theme` re-colours it.
rofi has no live preview pane and no animation system; the tabs use the message
bar for status and thumbnails (Clip) instead.

Startup speed: rofi runs every tab's script once at launch (it reads each tab's
name from it) and only draws after the last one returns, so `rice-hub` runs the
Windows and Clip tabs in parallel first and hands each script its finished output
(`RICE_PRE`). Keep tab scripts cheap on `ROFI_RETV=0`: no `sleep`, no per-row
forks, no `nmcli` rescans (use `--rescan no`).

To try an unstowed checkout: `RICE_BIN=$PWD/config-rice/.config/rice/bin ./config-rice/.config/rice/bin/rice-hub`.

## Quick-settings panel

`SUPER+N` or the top-right corner opens a card in the top right: six toggle
tiles (Wi-Fi, Bluetooth, do not disturb, night light, caffeine, game mode), the
power profile and the theme as segmented controls (one click picks the value, no
cycling: TLP's power-saver / balanced / performance through
`rice-power-profile`, and Mocha or Latte through `rice-theme`), and a strip
underneath. Click a tile to flip it; click outside the card or press `Esc` to
close. It is eww: `config-eww/.config/eww/widgets/qs.yuck`, opened by
`scripts/qs-ctl`, with the switches behind `rice-toggle`. No eww window exists
while it is closed. `Esc` is a Hyprland bind that exists only while the panel is
open (`config-hypr/.config/hypr/modules/qs.lua`).

Right-click a tile: Wi-Fi and Bluetooth close the panel and open that list in its
own rofi window (`rice-hub net` / `rice-hub bt`; those lists live only there, and a
chevron marks the tiles that have it); do not disturb and Caffeine open the
strip, which then shows their durations (30 min, 1 h, 2 h, until switched off),
and the picked tile keeps a ring until the strip closes.

A click shows at once. `scripts/qs-flip` first flips the tile on screen
(`scripts/qs-opt`, about 20 ms) and keeps what was asked for in
`$XDG_RUNTIME_DIR/rice/qs/pend/`, then makes the real change, then re-reads the
state; `scripts/qs-state` (also the 2 s poll) lays the pending clicks over the
real state until the two agree, so the real state always has the last word and a
change that never happens shows its real state again after a few seconds.
`qs-state` returns one object — the three rows of toggle tiles, the power profile
and the theme — and the panel binds to it (`qs_state`). The state checks and the
Wi-Fi, Bluetooth and power-profile writes go over D-Bus (`busctl`) instead of
`nmcli`, `bluetoothctl` and `tlpctl`, which is why a full read of all tiles takes
about 20 ms instead of about 250; the old commands are the fallback. The Wi-Fi
name comes from `iw` when it is installed.

The card is translucent glass: `@glass` for the card and `@glass_tile` for the
tiles, chips and segmented controls (about 60% opaque, one `@define-color` each
in both theme palettes under `config-theming`), with a thin light edge and no
gradient behind the fill (a gradient there would show through the glass). The
notification list below it is exactly as wide (`control-center-width` in
`config-swaync/.config/swaync/config.json` is 336 because swaync draws its box 24
px wider than that number). Hyprland blurs the panel
(`config-hypr/.config/hypr/modules/rules.lua`, `qs-panel` with `ignore_alpha`),
and the transparent margins are left out of the blur. One place sets the level
for this panel and for the notification one.

Do not disturb and Caffeine can also run on a timer. `rice-dnd for 1800` turns
DND on and schedules the end with a transient user timer (`systemd-run --user
--unit=rice-dnd-timer`); `rice-dnd until` prints when it ends, and a plain
`rice-dnd on` or `off` cancels it. `rice-caffeine for 1800` is the same, except
its holder runs `sleep 1800` instead of `sleep infinity` so it ends by itself,
and `rice-caffeine until` says when. The panel picks the power profile and the
theme directly through `scripts/qs-set` (one `flock` per control: the pick shows
on screen first and the real state has the last word), starts a DND or Caffeine
timer through `scripts/qs-timer`, and opens the Wi-Fi or Bluetooth list in the
rofi hub from a tile right-click through `scripts/qs-more` (`qs_sel` tells it
which timers the strip is showing).

All notifications are listed in one tidy list right under the panel (not grouped
by app, scrollable, with a Clear button): swaync's control centre, opened and
closed together with the panel by `qs-ctl` and positioned just below it
(`control-center-margin-top` in `config-swaync/.config/swaync/config.json` =
panel height + margins; change it if the panel's height changes). Times read as
"1 min ago" (`relative-timestamps`), a message that carries a verification code
gets a COPY action for the code (`notification-2fa-action`), and an empty list
says "All caught up" (`text-empty`). The list and the pop-up toasts are glass like
the quick-settings card but more opaque (about 82%: `@glass_nc`, `@glass_nc_tile` and
`@glass_pop`, one `@define-color` each in both theme palettes; the blur strength is
Hyprland's global `decoration.blur` in `look.lua`), and Hyprland blurs them
(`swaync-control-center` and `swaync-notification-window` in `rules.lua`, with
`ignore_alpha` so the transparent margins are not blurred). The Clear button and
the notification actions stay gradient pills, and a critical notification keeps
its red edge. After a config change run `swaync-client -R`, after a stylesheet
change `swaync-client -rs` (and `hyprctl reload` for the layer rules).

The blur needs `backdrop-filter: blur()` in `style.css` (on `.control-center` and
`.notification`). swaync is GTK4, and GTK 4.24 tells Hyprland itself what to blur
(the `ext-background-effect-v1` protocol); Hyprland 0.56 trusts that over the
layer rule, so without a blur node in the widget tree swaync gets no blur at all
(Hyprland issue 16508). Hyprland still does the real blur, with the size and
passes from `look.lua`. The eww panels are GTK3 and only need the layer rule.

Do not disturb, night light and caffeine are only here: Waybar has no bell,
moon or caffeine button (night light still switches itself by the sun through
darkman), and Waybar has no tray, so the nm-applet and blueman helpers (Wi-Fi
password and pairing prompts) run without an icon.

Battery warnings come from `rice-batsignal` (20% and 10%, through swaync). It
does not start while the battery reads 0% and is not discharging, so a stuck
gauge cannot warn forever.

## Themes (Mocha / Latte)

`rice-theme toggle` (or the Theme tile) switches everything: `rice-theme apply
latte|mocha`. Each theme also names its `color-scheme` (light/dark for libadwaita
apps, Firefox, Brave) and its GTK theme (`gtk-theme`). GTK3 follows through
gsettings; GTK4's css links in `~/.config/gtk-4.0` are slot links
`rice-theme bootstrap` points at the active GTK theme (skipped when that theme
isn't installed: Latte needs the AUR package `catppuccin-gtk-theme-latte`). There
is no automatic switching and no keybind; the wallpaper stays the Mocha walls.

Qt6 apps follow too: `QT_QPA_PLATFORMTHEME=qt6ct` (env.lua) makes qt6ct hand
them the Kvantum style (`config-qt6ct`), `rice-theme` writes the Kvantum theme
(`catppuccin-mocha-peach` / `-latte-peach`) and links a qt6ct palette. KDE apps
(Dolphin, Okular) read `~/.config/kdeglobals` instead, so `rice-theme` also keeps
a `Rice` colour scheme there (`[General]`/`[UiSettings] ColorScheme`, the
`[Colors:*]` sections and `[KDE] widgetStyle=kvantum`) and leaves the rest of the
file alone; the original is saved as `~/.local/state/rice/kdeglobals.orig`.

## Right-edge gauges

Touching the right edge of the screen slides out the gauge level with the
pointer: brightness (upper), volume (middle) or microphone (lower). Drag or
scroll on one to change it; click the volume or mic icon to mute. The volume,
brightness and mic-mute keys flash their gauge for a moment
(`config-rice/.config/rice/bin/rice-volume`, `rice-bright`). eww draws them
(`config-eww/.config/eww/widgets/edge.yuck`) and `scripts/edge-ctl` opens and
closes them; no window exists while a gauge is hidden.

## Troubleshooting and rollback

- **Colours missing or a bar with no styling:** run `rice-theme bootstrap`
  (slot links missing), then `rice-theme apply`.
- **The Lua config has an error:** Hyprland starts with emergency binds
  (`SUPER+Q` terminal, `SUPER+M` exit); the error shows in the config-error
  banner. `hyprctl reload` applies a fix without restarting. Test a file
  without applying it: `Hyprland --verify-config -c path/to/hyprland.lua`.
- **Waybar:** use `waybar-git`. Signals it does not handle (`SIGRTMIN+n`) kill
  it, so only send the ones `rice-sync` sends.
- **No eww gauges or panel after an update:** `pkill -x eww; eww daemon`.
- **Go back to Mocha:** `rice-theme apply mocha`.
- Do not use `hyprctl reload full-reset` to go back to a hyprlang config: it
  crashes Hyprland 0.56.2. Roll back with `git switch` on the old branch and a
  re-login.
- Your old `~/.config` files that `stow.sh` replaced are under
  `~/.dotfiles-backup/<timestamp>/`.
