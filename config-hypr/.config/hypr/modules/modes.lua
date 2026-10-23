local overlays = {
	battery = {
		["decoration.blur.enabled"] = false,
		["decoration.shadow.enabled"] = false,
	},
	game = {
		["animations.enabled"] = false,
		["decoration.blur.enabled"] = false,
		["decoration.shadow.enabled"] = false,
		["decoration.rounding"] = 0,
		["general.gaps_in"] = 0,
		["general.gaps_out"] = 0,
		["general.border_size"] = 1,
	},
}
local order = { "battery", "game" }

rice.modes = {}

local function read_line(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local line = f:read("l")
	f:close()
	return line
end

local function find_adapter()
	for _, name in ipairs({ "ADP1", "ADP0", "AC", "ACAD" }) do
		local path = "/sys/class/power_supply/" .. name .. "/online"
		if read_line(path) then
			return path
		end
	end
end
rice.adapter = find_adapter()

local baseline = {}
for _, name in ipairs(order) do
	for key in pairs(overlays[name]) do
		if baseline[key] == nil then
			baseline[key] = hl.get_config(key)
		end
	end
end

local function nested(flat)
	local tree = {}
	for key, value in pairs(flat) do
		local node, parts = tree, {}
		for part in key:gmatch("[^.]+") do
			parts[#parts + 1] = part
		end
		for i = 1, #parts - 1 do
			node[parts[i]] = node[parts[i]] or {}
			node = node[parts[i]]
		end
		node[parts[#parts]] = value
	end
	return tree
end

function rice.apply_modes()
	local values = {}
	for key, value in pairs(baseline) do
		values[key] = value
	end
	for _, name in ipairs(order) do
		if rice.modes[name] then
			for key, value in pairs(overlays[name]) do
				values[key] = value
			end
		end
	end
	hl.config(nested(values))
end

-- true when the mode changed
function rice.set_mode(name, on)
	on = on and true or false
	if (rice.modes[name] or false) == on then
		return false
	end
	rice.modes[name] = on
	rice.apply_modes()
	return true
end

local function wall_sync()
	hl.exec_cmd("~/.config/rice/bin/rice-wall sync")
end

local function check_power(sync)
	local online = rice.adapter and read_line(rice.adapter)
	if rice.set_mode("battery", online == "0") and sync then
		wall_sync()
	end
end

check_power()

local function start_power_watch()
	if #hl.get_monitors() == 0 then
		return
	end
	check_power()
	if not rice.power_timer then
		rice.power_timer = hl.timer(function()
			check_power(true)
		end, { timeout = 5000, type = "repeat" })
	end
end
hl.on("hyprland.start", start_power_watch)
hl.on("config.reloaded", start_power_watch)

local run_dir = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/rice"
local game_flag = run_dir .. "/gamemode"
local bin = "~/.config/rice/bin/"

rice.gamemode = {}

function rice.gamemode.toggle()
	local on = not rice.modes.game
	if on then
		os.execute("mkdir -p '" .. run_dir .. "'")
		local f = io.open(game_flag, "w")
		if f then
			f:close()
		end
	else
		os.remove(game_flag)
	end
	rice.set_mode("game", on)
	hl.exec_cmd(
		bin
			.. "rice-dnd "
			.. (on and "hold" or "release")
			.. " gamemode; "
			.. bin
			.. "rice-sync gamemode; "
			.. bin
			.. "rice-wall sync"
	)
end

local function exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
	end
	return f ~= nil
end
rice.set_mode("game", exists(game_flag))
