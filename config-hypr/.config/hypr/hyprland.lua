rice = rice or {}

require("modules.palette")
require("modules.env")
require("modules.monitors")
require("modules.look")
require("modules.input")
require("modules.rules")
require("modules.binds")
require("modules.qs")
require("modules.modes") -- after look: captures its values as the baseline
require("modules.lid")
require("modules.pointer") -- after modes: reads rice.modes.game
require("modules.autostart")
