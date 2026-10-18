# chawal

My Hyprland rice: configs, themes, icons, and fonts.

## Layout

Each top-level directory is a GNU Stow package: `config-*` packages hold
one directory under `.config`, `home-*` packages hold one dotfile/dir
directly under `$HOME`. Run `./stow.sh` to symlink everything into place
(existing real files at any target path are moved into a timestamped
backup under `~/.dotfiles-backup/` first, never deleted).

- `config-hypr` — Hyprland, hyprlock, hypridle
- `config-waybar` — bar
- `config-swaync` — notifications and the control center
- `config-rofi`, `config-wofi` — launchers
- `config-eww` — widgets
- `config-nwg-look`, `config-wlogout` — GTK settings/logout UI
- `config-gtk-2.0`, `config-gtk-3.0`, `config-gtk-4.0`, `config-gtkrc`,
  `config-gtkrc-2.0`, `home-gtkrc-20` (`~/.gtkrc-2.0`) — GTK theming
- `config-qt5ct`, `config-kvantum` — Qt theming
- `config-alacritty`, `config-tmux` — terminal
- `config-btop`, `config-cava`, `config-fastfetch` — system monitors/info
- `config-starship.toml` — shell prompt
- `config-yazi` — file manager
- `config-themes`, `config-theming` — theming
- `config-darkman`, `home-darkman-hooks` — dark/light by the sun (night light hook)
- `home-fonts`, `home-icons`, `home-themes` — fonts, icon themes, GTK themes
- `home-xinitrc`

## Rofi control hub

`SUPER+SPACE` opens one rofi window with five tabs. `Tab` / `Shift+Tab`
(or `Ctrl+Tab`) flip between them; `Alt+1` … `Alt+5` are the per-row actions
of whichever tab is showing. The scripts live in `config-rice/.config/rice/bin`;
`rice-hub` is the launcher and every other tab is a `rice-*` script running as
a rofi script mode (each also works on its own: `rice-net`, `rice-windows`, …).

| Tab | Script | Enter | Alt+1 … Alt+5 |
|---|---|---|---|
| Apps | rofi `drun` | launch | |
| Windows | `rice-windows` | focus | close · float · pin · bring here |
| Wi-Fi | `rice-net` | connect / disconnect | forget · rescan |
| BT | `rice-bt` | connect / disconnect | power · unpair |
| Clip | `rice-clip` | copy entry back | delete · wipe all (also Ctrl+Delete, Ctrl+Shift+Delete) |

Direct jumps: `SUPER+SHIFT+V` clipboard, and the top-left hot corner opens
Windows. The wallpaper grid (`rice-wall`, `SUPER+W`) and the power menu
(`rice-power`, `SUPER+M` / `SUPER+Esc`, Waybar power button) are separate rofi
menus, not hub tabs. Optional dependency: `cliphist` + `wl-clipboard` (Clip).
Switches live in the quick-settings panel (`SUPER+N`) and the sliders in the
right-edge gauges, not here.

Look: the theme is `config-rofi/.config/rofi/themes/rice.rasi`, coloured from
`~/.config/theming/current/rofi-colors.rasi`, so `rice-theme` re-colours it.
rofi has no live preview pane and no animation system; the tabs use the message
bar for status and thumbnails (Clip) instead.

Startup speed: rofi runs every tab's script once at launch (it reads each tab's
name from it) and only draws after the last one returns, so `rice-hub` runs the
data tabs in parallel first and hands each script its finished output
(`RICE_PRE`). Keep tab scripts cheap on `ROFI_RETV=0`: no `sleep`, no per-row
forks, no `nmcli` rescans (use `--rescan no`).

To try an unstowed checkout: `RICE_BIN=$PWD/config-rice/.config/rice/bin ./config-rice/.config/rice/bin/rice-hub`.

## Quick-settings panel

`SUPER+N` or the top-right corner opens a card of toggle tiles (Wi-Fi,
Bluetooth, do not disturb, night light, caffeine, game mode, the Mocha/Latte
theme, and power profile, which stays disabled until it has something to
switch). Click a tile to flip it; click outside the card or press `Esc` to
close. It is eww:
`config-eww/.config/eww/widgets/qs.yuck`, opened by `scripts/qs-ctl`, with the
switches behind `rice-toggle`. No eww window exists while it is closed. `Esc`
is a Hyprland bind that exists only while the panel is open
(`config-hypr/.config/hypr/modules/qs.lua`).

## Themes (Mocha / Latte)

`rice-theme toggle` (or the Theme tile) switches everything: `rice-theme apply
latte|mocha`. Each theme in `config-theming/.config/theming/themes/` also names
its `color-scheme` (light/dark for libadwaita apps, Firefox, Brave) and its GTK
theme (`gtk-theme`). GTK3 follows through gsettings; GTK4's css links in
`~/.config/gtk-4.0` are slot links `rice-theme bootstrap` points at the active
GTK theme (skipped when that theme isn't installed: Latte needs the AUR package
`catppuccin-gtk-theme-latte`). There is no automatic switching and no keybind.

All notifications are listed right under the panel (scrollable, with a Clear
button): swaync's control centre, opened and closed together with the panel by
`qs-ctl` and positioned just below it (`control-center-margin-top` in
`config-swaync/.config/swaync/config.json` = panel height + margins; change it if
the panel's height changes). Do not disturb, night light and caffeine are only
here: Waybar has no bell, moon or caffeine button (night light still switches
itself by the sun through darkman), and Waybar has no tray, so the nm-applet and
blueman helpers (Wi-Fi password and pairing prompts) run without an icon.

## Right-edge gauges

Touching the right edge of the screen slides out the gauge level with the
pointer: brightness (upper), volume (middle) or microphone (lower). Drag or
scroll on one to change it; click the volume or mic icon to mute. The volume,
brightness and mic-mute keys flash their gauge for a moment
(`config-rice/.config/rice/bin/rice-volume`, `rice-bright`). eww draws them
(`config-eww/.config/eww/widgets/edge.yuck`) and `scripts/edge-ctl` opens and
closes them; no window exists while a gauge is hidden.
