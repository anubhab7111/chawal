local commands = {
	"dbus-update-activation-environment --systemd --all",
	"systemctl --user reset-failed plasma-polkit-agent; systemctl --user start plasma-polkit-agent",

	"awww-daemon",
	[[bash -c 'rt=~/.config/rice/bin/rice-theme; $rt bootstrap; waybar & eww daemon; sleep 1; $rt apply']],

	"gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Classic; gsettings set org.gnome.desktop.interface cursor-size 30",

	"hyprsunset --identity",

	"bash -c 'sleep 3; systemctl --user restart darkman'",

	"~/.config/rice/bin/rice-caffeine off",

	"~/.config/rice/bin/rice-batsignal",

	"hypridle",
	"GDK_WAYLAND_DISABLE=ext_background_effect_manager_v1 swaync",

	"nm-applet --indicator & blueman-applet",

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
