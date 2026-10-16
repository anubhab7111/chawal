-- Runtime modes layered on top of the static config. The baseline is what
-- look.lua and friends just set; each active mode overrides a few options,
-- applied in `order` (later wins): battery now, game mode in P20.
--
-- Battery: blur and shadows off while unplugged. A 5 s timer watches the AC
-- adapter; rice.adapter can point it at another file (used by the tests).
-- Hyprland rebuilds the Lua state on every reload, so the modes and the
-- timer start fresh each load (no stacking timers).

local overlays = {
    battery = {
        ["decoration.blur.enabled"] = false,
        ["decoration.shadow.enabled"] = false,
    },
}
local order = { "battery" }

rice.modes = {}

local function read_line(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local line = f:read("l")
    f:close()
    return line
end

-- The laptop's AC adapter, or nil (a desktop has none: never "battery").
local function find_adapter()
    for _, name in ipairs({ "ADP1", "ADP0", "AC", "ACAD" }) do
        local path = "/sys/class/power_supply/" .. name .. "/online"
        if read_line(path) then return path end
    end
end
rice.adapter = find_adapter()

-- Baseline values of every option some mode touches
local baseline = {}
for _, name in ipairs(order) do
    for key in pairs(overlays[name]) do
        if baseline[key] == nil then baseline[key] = hl.get_config(key) end
    end
end

-- { ["a.b.c"] = v } -> { a = { b = { c = v } } } for hl.config
local function nested(flat)
    local tree = {}
    for key, value in pairs(flat) do
        local node, parts = tree, {}
        for part in key:gmatch("[^.]+") do parts[#parts + 1] = part end
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
    for key, value in pairs(baseline) do values[key] = value end
    for _, name in ipairs(order) do
        if rice.modes[name] then
            for key, value in pairs(overlays[name]) do values[key] = value end
        end
    end
    hl.config(nested(values))
end

function rice.set_mode(name, on)
    on = on and true or false
    if (rice.modes[name] or false) == on then return end
    rice.modes[name] = on
    rice.apply_modes()
end

local function check_power()
    local online = rice.adapter and read_line(rice.adapter)
    rice.set_mode("battery", online == "0")
end

check_power()

-- An hl.timer segfaults `Hyprland --verify-config` (no event loop there), so
-- the watcher starts once Hyprland really runs: on start, and after each
-- reload (which drops the old Lua state and its timer). Verify also fires
-- config.reloaded, but with no monitors, which is how it is told apart.
local function start_power_watch()
    if #hl.get_monitors() == 0 then return end
    check_power()
    if not rice.power_timer then
        rice.power_timer = hl.timer(check_power, { timeout = 5000, type = "repeat" })
    end
end
hl.on("hyprland.start", start_power_watch)
hl.on("config.reloaded", start_power_watch)
