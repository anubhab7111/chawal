-- Hyprland config entry point (Lua). Hyprland prefers this file over
-- hyprland.conf when both exist; the .conf files stay as a fallback until P8.
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
require("modules.autostart")
