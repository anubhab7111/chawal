-- Hot corners and the right-edge gauges. A 100 ms timer watches the pointer: a corner fires once the
-- pointer has stayed within 2 px of it for 300 ms (3 ticks), and re-arms
-- only after the pointer leaves, so a quick pass or resting there does not
-- repeat it. Nothing fires in fullscreen or game mode. (Lua cannot see a
-- drag in progress; the dwell keeps a drag through a corner from firing.)
--
--   top-left   window overview: rice-hub window (hyprshell's overview
--              replaces it in P24 once installed)
--   top-right  quick settings panel (eww qs-ctl toggle)
--
-- rice.corners.actions maps a corner to a function, so tests and later
-- phases can swap them.

rice.corners = {
    size = 2,         -- px from the edge
    dwell_ticks = 3,  -- x 100 ms
    actions = {
        top_left = function() hl.exec_cmd("~/.config/rice/bin/rice-hub window") end,
        top_right = function() hl.exec_cmd("~/.config/eww/scripts/qs-ctl toggle") end,
    },
}

-- Right screen edge. Entering the strip hands over to eww's edge-ctl, which
-- knows where the volume and brightness gauges are and opens the one the
-- pointer is level with (and does nothing for any other height). It fires
-- once per entry, so resting at the edge does not repeat it. There is no
-- always-mapped window at the edge for this: such a window blocks clicks
-- (browser scrollbars) in its strip.
rice.edges = {
    size = 2, -- px from the right edge
    action = function() hl.exec_cmd("~/.config/eww/scripts/edge-ctl edge") end,
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
    if ly >= s then return nil end
    if lx < s then return "top_left" end
    if lx >= w - s then return "top_right" end
    return nil
end

local function suppressed(m)
    if rice.modes and rice.modes.game then return true end
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
        if not suppressed(m) then rice.edges.action() end
    elseif not edge then
        state.edge = false
    end

    if corner ~= state.corner then
        state.corner, state.ticks, state.fired = corner, 0, false
        return
    end
    if not corner or state.fired then return end

    state.ticks = state.ticks + 1
    if state.ticks < rice.corners.dwell_ticks then return end
    state.fired = true
    if suppressed(m) then return end
    local action = rice.corners.actions[corner]
    if action then action() end
end

-- like the power watcher in modes.lua: no timers in --verify-config (no
-- monitors, no event loop); start on launch and after every reload
local function start_corner_watch()
    if #hl.get_monitors() == 0 or rice.corner_timer then return end
    rice.corner_timer = hl.timer(tick, { timeout = 100, type = "repeat" })
end
hl.on("hyprland.start", start_corner_watch)
hl.on("config.reloaded", start_corner_watch)
