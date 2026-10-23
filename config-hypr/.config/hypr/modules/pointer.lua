rice.corners = {
	size = 2, -- px from the edge
	dwell_ticks = 3, -- x 100 ms
	actions = {
		top_left = function()
			hl.exec_cmd("~/.config/rice/bin/rice-hub window")
		end,
		top_right = function()
			hl.exec_cmd("~/.config/eww/scripts/qs-ctl toggle")
		end,
	},
}

rice.edges = {
	size = 2, -- px from the right edge
	action = function()
		hl.exec_cmd("~/.config/eww/scripts/edge-ctl edge")
	end,
}

local state = { corner = nil, ticks = 0, fired = false, edge = false }

local function at_right_edge(pos, m)
	local scale = m.scale or 1
	return pos.x >= m.x + m.width / scale - rice.edges.size
end

local function corner_at(pos, m)
	local scale = m.scale or 1
	local w = m.width / scale
	local lx, ly = pos.x - m.x, pos.y - m.y
	local s = rice.corners.size
	if ly >= s then
		return nil
	end
	if lx < s then
		return "top_left"
	end
	if lx >= w - s then
		return "top_right"
	end
	return nil
end

local function suppressed(m)
	if rice.modes and rice.modes.game then
		return true
	end
	local ws = m.active_workspace
	return ws ~= nil and ws.has_fullscreen
end

local function tick()
	local pos = hl.get_cursor_pos()
	local m = hl.get_monitor_at_cursor()
	local corner = (pos and m) and corner_at(pos, m) or nil

	local edge = (pos and m) and at_right_edge(pos, m) or false
	if edge and not state.edge then
		state.edge = true
		if not suppressed(m) then
			rice.edges.action()
		end
	elseif not edge then
		state.edge = false
	end

	if corner ~= state.corner then
		state.corner, state.ticks, state.fired = corner, 0, false
		return
	end
	if not corner or state.fired then
		return
	end

	state.ticks = state.ticks + 1
	if state.ticks < rice.corners.dwell_ticks then
		return
	end
	state.fired = true
	if suppressed(m) then
		return
	end
	local action = rice.corners.actions[corner]
	if action then
		action()
	end
end

local function start_corner_watch()
	if #hl.get_monitors() == 0 or rice.corner_timer then
		return
	end
	rice.corner_timer = hl.timer(tick, { timeout = 100, type = "repeat" })
end
hl.on("hyprland.start", start_corner_watch)
hl.on("config.reloaded", start_corner_watch)
