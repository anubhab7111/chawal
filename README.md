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

`SUPER+SPACE` opens one rofi window with eleven tabs. `Tab` / `Shift+Tab`
(or `Ctrl+Tab`) flip between them; `Alt+1` … `Alt+5` are the per-row actions
of whichever tab is showing. The scripts live in `config-rice/.config/rice/bin`;
`rice-hub` is the launcher and every other tab is a `rice-*` script running as
a rofi script mode (each also works on its own: `rice-audio`, `rice-net`, …).

| Tab | Script | Enter | Alt+1 … Alt+5 |
|---|---|---|---|
| Apps | rofi `drun` | launch | |
| Toggles | `rice-toggles` | flip a switch (Wi-Fi, Bluetooth, night light, DND, caffeine, game mode, mute, mic) | |
| Windows | `rice-windows` | focus | close · float · pin · bring here |
| Audio | `rice-audio` | make default output | vol − · vol + · mute · play/pause · next |
| Wi-Fi | `rice-net` | connect / disconnect | forget · rescan |
| BT | `rice-bt` | connect / disconnect | power · unpair |
| Calc | `rice-calc` | evaluate what you typed (qalc) | clear history · copy result |
| Emoji | `rice-emoji` | open the rofimoji picker (copies) | |
| Clip | `rice-clip` | copy entry back | delete · wipe all (also Ctrl+Delete, Ctrl+Shift+Delete) |
| Walls | `rice-wall` | open the wallpaper grid | |
| Power | `rice-power` | lock / suspend / log out / reboot / shut down (asks to confirm) | |

Direct jumps: `SUPER+SHIFT+V` clipboard, `SUPER+/` calculator, `SUPER+.` emoji,
`SUPER+W` wallpapers, `SUPER+M` / `SUPER+Esc` power, and the top-left hot corner
opens Windows. Optional dependencies: `qalc` (Calc), `rofimoji` (Emoji),
`cliphist` + `wl-clipboard` (Clip), `playerctl` (Audio now-playing).

Look: the theme is `config-rofi/.config/rofi/themes/rice.rasi`, coloured from
`~/.config/theming/current/rofi-colors.rasi`, so `rice-theme` re-colours it.
rofi has no live preview pane and no animation system; the tabs use the message
bar for status and thumbnails (Clip, Walls) instead.

Startup speed: rofi runs every tab's script once at launch (it reads each tab's
name from it) and only draws after the last one returns, so `rice-hub` runs the
data tabs in parallel first and hands each script its finished output
(`RICE_PRE`). Keep tab scripts cheap on `ROFI_RETV=0`: no `sleep`, no per-row
forks, no `nmcli` rescans (use `--rescan no`).

To try an unstowed checkout: `RICE_BIN=$PWD/config-rice/.config/rice/bin ./config-rice/.config/rice/bin/rice-hub`.

## Quick-settings panel

`SUPER+N` or the top-right corner opens a card of toggle tiles (Wi-Fi,
Bluetooth, do not disturb, night light, caffeine, game mode, plus power profile
and theme, which stay disabled until they have something to switch). Click a
tile to flip it; click outside the card or press `Esc` to close. It is eww:
`config-eww/.config/eww/widgets/qs.yuck`, opened by `scripts/qs-ctl`, with the
switches behind `rice-toggle` (the same backends as the rofi Toggles tab). No
window exists while it is closed. `Esc` is a Hyprland bind that exists only
while the panel is open (`config-hypr/.config/hypr/modules/qs.lua`).
