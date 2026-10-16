-- Autostart. Runs once per session on
-- the first rendered frame; config reloads don't run it again.
--
-- RICE_NESTED is set by the test harness for nested Hyprland instances:
-- these commands act on the whole user session (theme replay kills and
-- restarts waybar/eww, dbus-update-activation-environment rewrites the
-- systemd environment), so a nested test instance must not run them.

local commands = {
    -- System services and environment
    -- (pipewire is socket-activated; --all already exports WAYLAND_DISPLAY,
    -- DISPLAY and XDG_CURRENT_DESKTOP to both dbus and systemd.)
    "dbus-update-activation-environment --systemd --all",
    -- A quick re-login can leave the agent at systemd's start limit.
    "systemctl --user reset-failed plasma-polkit-agent; systemctl --user start plasma-polkit-agent",

    -- Wallpaper and theming. Wallpaper, waybar, the screen shader and
    -- cava/btop/rofi/GTK-icon theming are runtime state that only
    -- apply-theme.sh sets, so replay the last active theme on every login.
    "awww-daemon",
    [[bash -c 'sleep 1; ~/.config/theming/apply-theme.sh "$(cat ~/.config/theming/state 2>/dev/null || echo catppuccin)"']],

    -- Cursor theme
    "hyprctl setcursor HyprBibataModernClassicSVG 30",

    -- UI components (waybar is started by the theme replay above)
    "hypridle",
    "mako",

    -- Tray applets
    "nm-applet --indicator & blueman-applet",

    -- Clipboard history
    "wl-paste --type text --watch cliphist store",
    "wl-paste --type image --watch cliphist store",
}

hl.on("hyprland.start", function()
    if os.getenv("RICE_NESTED") then
        rice.autostart_skipped = true
        return
    end
    for _, cmd in ipairs(commands) do
        hl.exec_cmd(cmd)
    end
end)
