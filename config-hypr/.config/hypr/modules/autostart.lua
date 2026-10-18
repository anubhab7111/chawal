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

    -- Theme, bars and wallpaper. rice-theme bootstrap creates the state dir
    -- and slot links that waybar, eww and alacritty read colours through, so
    -- it runs first; apply then replays the saved theme (wallpaper, Hyprland
    -- palette, shader) once awww-daemon is up.
    "awww-daemon",
    [[bash -c 'rt=~/.config/rice/bin/rice-theme; $rt bootstrap; waybar & eww daemon; sleep 1; $rt apply']],

    -- Cursor for GTK apps that read gsettings (env.lua sets the rest)
    "gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Classic; gsettings set org.gnome.desktop.interface cursor-size 30",

    -- Night light daemon, neutral until rice-nightlight turns it warm
    "hyprsunset --identity",

    -- Dark/light by the sun (darkman hooks switch the night light). Restarted
    -- here, after the environment import above, so its hooks can reach
    -- Hyprland; the delay lets hyprsunset above come up first.
    "bash -c 'sleep 3; systemctl --user restart darkman'",

    -- Caffeine starts off every login (its inhibitor can outlive a logout)
    "~/.config/rice/bin/rice-caffeine off",

    -- UI components (waybar and the eww edge widgets start with the theme above)
    "hypridle",
    "swaync",

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
