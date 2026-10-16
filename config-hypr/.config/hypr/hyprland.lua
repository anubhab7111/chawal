-- Hyprland config entry point (Lua). The hyprlang config (hyprland.conf and
-- configs/*.conf) was retired in P8; hypridle and hyprlock stay hyprlang.
--
-- `rice` is the one global shared by the modules and reachable from
-- `hyprctl eval`. Each require() gets its own error scope, so a broken
-- module is reported in `hyprctl configerrors` without stopping the rest.

rice = rice or {}

require("modules.palette")
require("modules.env")
require("modules.monitors")
require("modules.look")
require("modules.input")
require("modules.rules")
require("modules.binds")
require("modules.modes") -- after look: captures its values as the baseline
require("modules.lid")
require("modules.pointer") -- after modes: reads rice.modes.game
require("modules.autostart")
