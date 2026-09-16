# chawal

My Hyprland rice: configs, themes, icons, and fonts.

## Layout

Each top-level directory is a GNU Stow package: `config-*` packages hold
one directory under `.config`, `home-*` packages hold one dotfile/dir
directly under `$HOME`. Run `./stow.sh` to symlink everything into place
(existing real files at any target path are moved into a timestamped
backup under `~/.dotfiles-backup/` first, never deleted).

- `config-hypr` — Hyprland, hyprlock, hypridle, hyprpaper
- `config-hyprpanel`, `config-waybar` — bar
- `config-mako` — notifications
- `config-swww` — wallpaper daemon
- `config-rofi`, `config-wofi` — launchers
- `config-eww` — widgets
- `config-nwg-bar`, `config-nwg-look`, `config-wlogout` — panel/logout UI
- `config-gtk-2.0`, `config-gtk-3.0`, `config-gtk-4.0`, `config-gtkrc`,
  `config-gtkrc-2.0`, `home-gtkrc-20` (`~/.gtkrc-2.0`) — GTK theming
- `config-qt5ct`, `config-kvantum` — Qt theming
- `config-kitty`, `config-alacritty`, `config-tmux` — terminal
- `config-btop`, `config-cava`, `config-fastfetch` — system monitors/info
- `config-starship.toml` — shell prompt
- `config-yazi` — file manager
- `config-themes`, `config-theming` — theming
- `home-fonts`, `home-icons`, `home-themes` — fonts, icon themes, GTK themes
- `home-xinitrc`
