#!/bin/bash
# Switch the active system theme and reload every themed app.
# Usage: apply-theme.sh <theme-name>

set -euo pipefail

THEMING_DIR="$HOME/.config/theming"
THEME_NAME="${1:?usage: apply-theme.sh <theme-name>}"
THEME_DIR="$THEMING_DIR/themes/$THEME_NAME"

if [ ! -d "$THEME_DIR" ]; then
    echo "No such theme: $THEME_NAME (looked in $THEME_DIR)" >&2
    exit 1
fi

ln -sfn "themes/$THEME_NAME" "$THEMING_DIR/current"
echo "$THEME_NAME" > "$THEMING_DIR/state"

# Wallpaper: apply every output:path entry in this theme's wallpaper.conf, if any
WALLPAPER_CONF="$THEME_DIR/wallpaper.conf"
if [ -f "$WALLPAPER_CONF" ]; then
    while IFS=: read -r output path; do
        [ -z "$output" ] && continue
        case "$output" in \#*) continue ;; esac
        if [ ! -f "$path" ]; then
            echo "Warning: wallpaper not found, skipping: $path" >&2
            continue
        fi
        if [ "$output" = "*" ]; then
            awww img "$path" >/dev/null 2>&1 &
        else
            awww img "$path" -o "$output" >/dev/null 2>&1 &
        fi
    done < "$WALLPAPER_CONF"
    wait
fi

# Waybar config/style: use this theme's own files if it has them (e.g. a
# different module layout), otherwise fall back to the shared base layout.
for pair in "waybar-config.json:config" "waybar-style.css:style.css"; do
    src_name="${pair%%:*}"
    target="$HOME/.config/waybar/${pair#*:}"
    if [ -f "$THEME_DIR/$src_name" ]; then
        ln -sfn "../theming/themes/$THEME_NAME/$src_name" "$target"
    else
        ln -sfn "../theming/base/$src_name" "$target"
    fi
done

# GTK icon theme: use this theme's own pick if it has one, else the shared default
ICON_THEME_FILE="$THEME_DIR/gtk-icon-theme"
[ -f "$ICON_THEME_FILE" ] || ICON_THEME_FILE="$THEMING_DIR/base/gtk-icon-theme"
if [ -f "$ICON_THEME_FILE" ]; then
    ICON_THEME="$(tr -d '[:space:]' < "$ICON_THEME_FILE")"
    for f in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
        [ -f "$f" ] && sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$ICON_THEME/" "$f"
    done
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" >/dev/null 2>&1 || true
fi

# eww/arin dock SCSS: this theme's reskin if it has one, else the original look.
EWW_ARIN_DIR="$HOME/.config/eww/arin"
if [ -f "$THEME_DIR/eww-arin.scss" ]; then
    ln -sfn "../../theming/themes/$THEME_NAME/eww-arin.scss" "$EWW_ARIN_DIR/eww.scss"
else
    ln -sfn "../../theming/base/eww-arin.scss" "$EWW_ARIN_DIR/eww.scss"
fi

# Bar vs. floating dock: themes with a `use-eww-dock` marker replace waybar
# with the eww/arin floating dock (search/apps/weather/music/system pods).
# Every other theme uses waybar. Tear down whichever isn't wanted first.
USE_DOCK=0
if [ -f "$THEME_DIR/use-eww-dock" ]; then
    USE_DOCK=1
fi

if [ "$USE_DOCK" = "1" ]; then
    pkill -x waybar >/dev/null 2>&1 || true
    # eww's own IPC-based `kill` can silently no-op (observed: a daemon
    # survived it, leaving a duplicate "bar" layer-shell surface + doubled
    # exclusive-zone reservation once a second one opened). Force it.
    eww --config "$EWW_ARIN_DIR" kill >/dev/null 2>&1 || true
    pkill -x eww >/dev/null 2>&1 || true
    sleep 0.3
    (setsid eww --config "$EWW_ARIN_DIR" daemon >/dev/null 2>&1 &) || true
    sleep 0.5
    eww --config "$EWW_ARIN_DIR" open bar >/dev/null 2>&1 || true
else
    eww --config "$EWW_ARIN_DIR" kill >/dev/null 2>&1 || true
    pkill -x eww >/dev/null 2>&1 || true
fi

# Volume edge-hover widget: its own eww daemon, independent of the
# waybar-vs-eww-dock choice above -- but the `pkill -x eww` calls in both
# branches kill it too (they match by process name, not config dir), so
# always relaunch it here.
VOLUME_EDGE_DIR="$HOME/.config/eww/volume-edge"
if [ -d "$VOLUME_EDGE_DIR" ]; then
    (setsid eww --config "$VOLUME_EDGE_DIR" daemon >/dev/null 2>&1 &) || true
    sleep 0.3
    eww --config "$VOLUME_EDGE_DIR" open volume-hotzone >/dev/null 2>&1 || true
fi

# Hyprland: re-source config (picks up hyprland-colors.conf + decorations.conf
# + hypr-overrides.conf via the current symlink)
hyprctl reload >/dev/null 2>&1 || true

# Hyprland screen shader: this theme's post-process, or clear it. MUST run
# AFTER `hyprctl reload` above — reload re-parses the static config (which
# never sets screen_shader), so setting this before reload gets clobbered.
if [ -f "$THEME_DIR/screen.frag" ]; then
    hyprctl keyword decoration:screen_shader "$THEME_DIR/screen.frag" >/dev/null 2>&1 || true
else
    hyprctl keyword decoration:screen_shader "[[EMPTY]]" >/dev/null 2>&1 || true
fi

# Waybar: only (re)started when this theme doesn't use the eww dock. Config/style
# targets may have changed, needs a full restart to pick it up.
if [ "$USE_DOCK" = "0" ]; then
    pkill -x waybar >/dev/null 2>&1 || true
    (setsid waybar >/dev/null 2>&1 &) || true
fi

# cava: patch the 8 gradient_color_N keys in the live config from this theme's
# palette, else the shared default gradient.
CAVA_COLORS_FILE="$THEME_DIR/cava-colors"
[ -f "$CAVA_COLORS_FILE" ] || CAVA_COLORS_FILE="$THEMING_DIR/base/cava-colors"
CAVA_CONFIG="$HOME/.config/cava/config"
if [ -f "$CAVA_COLORS_FILE" ] && [ -f "$CAVA_CONFIG" ]; then
    while IFS='=' read -r key val; do
        key="${key% }"   # trim the trailing space before "="
        val="${val# }"   # trim the leading space after "="
        [ -z "$key" ] && continue
        case "$key" in \#*) continue ;; esac
        sed -i "s|^${key} = .*|${key} = ${val}|" "$CAVA_CONFIG"
    done < "$CAVA_COLORS_FILE"
fi

# btop: switch its color_theme to this theme's pick, else the shared default.
BTOP_THEME_FILE="$THEME_DIR/btop-theme"
[ -f "$BTOP_THEME_FILE" ] || BTOP_THEME_FILE="$THEMING_DIR/base/btop-theme"
BTOP_CONF="$HOME/.config/btop/btop.conf"
if [ -f "$BTOP_THEME_FILE" ] && [ -f "$BTOP_CONF" ]; then
    BTOP_THEME="$(tr -d '[:space:]' < "$BTOP_THEME_FILE")"
    sed -i "s/^color_theme = .*/color_theme = \"$BTOP_THEME\"/" "$BTOP_CONF"
fi

# rofi: point current.rasi at this theme's pick, else the shared default.
# (Not currently bound to a keybind — wofi is the active launcher — but kept
# in sync so rofi looks right the moment it's invoked.)
ROFI_THEME_FILE="$THEME_DIR/rofi.rasi"
[ -f "$ROFI_THEME_FILE" ] || ROFI_THEME_FILE="$THEMING_DIR/base/rofi.rasi"
if [ -f "$ROFI_THEME_FILE" ]; then
    ln -sfn "$ROFI_THEME_FILE" "$HOME/.config/rofi/current.rasi"
fi

# kitty: reloads its config (and re-included theme file) on SIGUSR1
pkill -SIGUSR1 -x kitty >/dev/null 2>&1 || true

# mako: config symlink target changed, reload it
makoctl reload >/dev/null 2>&1 || true

# alacritty: COPY (not symlink) so its live-reload file-watcher — which
# locks onto an inode, not a path — actually sees a change. See the comment
# in ~/.config/alacritty/alacritty.toml for why.
if [ -f "$THEME_DIR/alacritty-colors.toml" ]; then
    cp "$THEME_DIR/alacritty-colors.toml" "$HOME/.config/alacritty/current-theme.toml"
fi

# wofi/wlogout (read config fresh on each launch) pick up the new theme
# automatically, no action needed. fastfetch has no hardcoded colors of its
# own — it inherits whatever terminal (kitty/alacritty) runs it, which is
# already themed above.

# VS Code: merge (or remove) a workbench.colorCustomizations block on top of
# the base theme. VS Code hot-reloads settings.json changes on its own, no
# restart/signal needed. Guarded so a JSON hiccup can't abort the rest of
# the switch.
VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
VSCODE_CUSTOM_FILE="$THEME_DIR/vscode-colorCustomizations.json"
if [ -f "$VSCODE_SETTINGS" ]; then
    python3 - "$VSCODE_SETTINGS" "$VSCODE_CUSTOM_FILE" <<'PYEOF' || true
import json, os, sys
settings_path, custom_path = sys.argv[1], sys.argv[2]
with open(settings_path) as f:
    settings = json.load(f)
if os.path.isfile(custom_path):
    with open(custom_path) as f:
        settings["workbench.colorCustomizations"] = json.load(f)
else:
    settings.pop("workbench.colorCustomizations", None)
with open(settings_path, "w") as f:
    json.dump(settings, f, indent=4)
    f.write("\n")
PYEOF
fi

# Brave: best-effort native dark/light toggle only (no full color reskin —
# Chromium has no simple config-file hook for that short of installing a
# theme extension, which we don't do here). Only touches Preferences when
# Brave ISN'T running: editing it live risks Brave's own periodic write
# silently clobbering this change.
BRAVE_PREFS="$HOME/.config/BraveSoftware/Brave-Browser/Default/Preferences"
BRAVE_SCHEME_FILE="$THEME_DIR/brave-color-scheme"
[ -f "$BRAVE_SCHEME_FILE" ] || BRAVE_SCHEME_FILE="$THEMING_DIR/base/brave-color-scheme"
if [ -f "$BRAVE_PREFS" ] && [ -f "$BRAVE_SCHEME_FILE" ]; then
    if pgrep -x brave >/dev/null 2>&1; then
        echo "Note: Brave is running, skipping its theme update (close it and re-switch to apply)." >&2
    else
        BRAVE_SCHEME="$(tr -d '[:space:]' < "$BRAVE_SCHEME_FILE")"
        python3 - "$BRAVE_PREFS" "$BRAVE_SCHEME" <<'PYEOF' || true
import json, sys
path, scheme = sys.argv[1], int(sys.argv[2])
with open(path) as f:
    prefs = json.load(f)
prefs.setdefault("browser", {}).setdefault("theme", {})["color_scheme2"] = scheme
with open(path, "w") as f:
    json.dump(prefs, f)
PYEOF
    fi
fi

echo "Theme switched to: $THEME_NAME"
