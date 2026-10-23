local function read_line(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local line = f:read("l")
	f:close()
	return line
end

-- Lid ----------------------------------------------------------------------

rice.lid = {
	internal = "eDP-1",
	state_file = "/proc/acpi/button/lid/LID0/state",
	panel_off = false,
}

function rice.lid.closed()
	local state = read_line(rice.lid.state_file) or ""
	return state:find("closed") ~= nil
end

local function other_screen_on()
	for _, m in ipairs(hl.get_monitors()) do
		if m.name ~= rice.lid.internal and m.name ~= "FALLBACK" then
			return true
		end
	end
	return false
end

local function set_panel(off)
	if rice.lid.panel_off == off then
		return
	end
	rice.lid.panel_off = off
	if off then
		hl.monitor({ output = rice.lid.internal, disabled = true })
	else
		hl.monitor({
			output = rice.lid.internal,
			disabled = false,
			mode = "preferred",
			position = "auto",
			scale = "auto",
		})
	end
end

function rice.lid.update()
	set_panel(rice.lid.closed() and other_screen_on())
end

local function update_soon()
	hl.timer(function()
		rice.lid.update()
	end, { timeout = 300, type = "oneshot" })
end

hl.bind("switch:on:Lid Switch", update_soon, { locked = true })
hl.bind("switch:off:Lid Switch", update_soon, { locked = true })
hl.on("monitor.added", update_soon)
hl.on("monitor.removed", update_soon)
local function update_if_running()
	if #hl.get_monitors() > 0 then
		rice.lid.update()
	end
end
hl.on("hyprland.start", update_if_running)
hl.on("config.reloaded", update_if_running)

local run_dir = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/rice"

rice.touchpad = {
	name = "syna32d1:00-06cb:ced1-touchpad",
	flag = run_dir .. "/touchpad-off",
}

local function exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
	end
	return f ~= nil
end

function rice.touchpad.enabled()
	return not exists(rice.touchpad.flag)
end

local function apply_touchpad(enabled)
	hl.device({ name = rice.touchpad.name, enabled = enabled })
end

function rice.touchpad.toggle()
	local enable = not rice.touchpad.enabled()
	if enable then
		os.remove(rice.touchpad.flag)
	else
		os.execute("mkdir -p '" .. run_dir .. "'")
		local f = io.open(rice.touchpad.flag, "w")
		if f then
			f:close()
		end
	end
	apply_touchpad(enable)
	hl.exec_cmd(
		"notify-send -a rice -t 1500 -h string:x-canonical-private-synchronous:touchpad 'Touchpad "
			.. (enable and "on" or "off")
			.. "'"
	)
end

if not rice.touchpad.enabled() then
	apply_touchpad(false)
end

hl.bind("XF86TouchpadToggle", function()
	rice.touchpad.toggle()
end)
hl.bind("SUPER + SHIFT + T", function()
	rice.touchpad.toggle()
end)
