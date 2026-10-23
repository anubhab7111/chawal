local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local theme_file = config_home .. "/theming/current/hyprland.lua"

local ok, palette = pcall(dofile, theme_file)
if ok and type(palette) == "table" and palette.border_active then
	rice.palette = palette
	rice.palette_source = "theme"
else
	rice.palette = require("modules.fallback_palette")
	rice.palette_source = "fallback"
end
