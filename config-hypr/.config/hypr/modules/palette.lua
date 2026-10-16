-- Theme palette: the active theme's hyprland.lua (via the theming/current
-- symlink), else the committed fallback. dofile() is used instead of
-- require() so a missing or broken theme file can't stop the config.
--
--   rice.palette         the colour table (see fallback_palette.lua)
--   rice.palette_source  "theme" or "fallback"

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
