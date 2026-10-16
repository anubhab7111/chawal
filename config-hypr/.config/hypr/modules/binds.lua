-- Keybinds, ported from configs/bindings.conf with no behaviour change.
-- Known quirks are kept on purpose and fixed in P6 (see the plan):
-- the duplicate brightness binds and SUPER+SHIFT+0 doing two things.

local terminal    = "alacritty"
local fileManager = "thunar"
local menu        = "wofi --show drun"
local code        = "vscodium"
local browser     = "firefox"

local mainMod = "SUPER"

local bind = hl.bind
local exec = hl.dsp.exec_cmd

-- System
bind(mainMod .. " + M", hl.dsp.exit())                                         -- Exit Hyprland
bind(mainMod .. " + L", exec("hyprlock"))                                      -- Lock screen
bind(mainMod .. " + F1", exec("~/.config/hypr/scripts/gamemode.sh"))
bind(mainMod .. " + escape", exec("wlogout"))

-- Applications
bind(mainMod .. " + Q", exec(terminal))
bind(mainMod .. " + E", exec(fileManager))
bind(mainMod .. " + SPACE", exec(menu))                                        -- App launcher
bind(mainMod .. " + SHIFT + C", exec(code))
bind(mainMod .. " + B", exec(browser))
bind(mainMod .. " + SHIFT + B", exec("chromium"))
bind(mainMod .. " + Z", exec("zapzap"))
bind(mainMod .. " + A", exec("pwvucontrol"))                                   -- Audio control

-- Window management
bind(mainMod .. " + C", hl.dsp.window.close())
bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))     -- keeps the bar
bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
bind(mainMod .. " + P", hl.dsp.window.pseudo())                                -- Pseudotile (dwindle)

-- Focus and move with the arrow keys
local dirs = { left = "l", right = "r", up = "u", down = "d" }
for key, dir in pairs(dirs) do
    bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = dir }))
    bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
end

-- Workspaces 1-10: switch, and move the active window
for i = 1, 10 do
    local key = tostring(i % 10)
    bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = tostring(i) }))
    bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- Special workspace (scratchpad)
bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Mouse: scroll through workspaces, LMB drag moves, RMB drag resizes
bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Resize mode
bind(mainMod .. " + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
    local steps = {
        left = { -20, 0 }, right = { 20, 0 }, up = { 0, -20 }, down = { 0, 20 },
        h = { -20, 0 }, l = { 20, 0 }, k = { 0, -20 }, j = { 0, 20 },
    }
    for key, d in pairs(steps) do
        bind(key, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }))
    end
    bind("escape", hl.dsp.submap("reset"))
    bind("R", hl.dsp.submap("reset"))
end)

-- Media
bind("XF86AudioRaiseVolume", exec("pamixer --allow-boost -i 5"))
bind("XF86AudioLowerVolume", exec("pamixer --allow-boost -d 5"))
bind("XF86AudioMute", exec("pamixer -t"))
bind("XF86AudioPlay", exec("playerctl play-pause"))
bind("XF86AudioPause", exec("playerctl play-pause"))
bind("XF86AudioNext", exec("playerctl next"))
bind("XF86AudioPrev", exec("playerctl previous"))

-- Brightness (duplicated plain + locked binds, as before; fixed in P6)
bind("XF86MonBrightnessUp", exec("brightnessctl s +5%"))
bind("XF86MonBrightnessDown", exec("brightnessctl s 5%-"))
bind("XF86MonBrightnessUp", exec("brightnessctl set +5%"), { locked = true })
bind("XF86MonBrightnessDown", exec("brightnessctl set 5%-"), { locked = true })

-- Screenshots
bind(mainMod .. " + PRINT", exec("hyprshot -m window"))
bind("PRINT", exec("hyprshot -m output"))
-- Was "$shiftMod, PRINT": $shiftMod was never defined, but hyprlang still
-- read the literal "$shiftMod" as SHIFT, so the live bind is SHIFT+PRINT.
bind("SHIFT + PRINT", exec("hyprshot -m region"))

-- Utilities
bind("SUPER + SHIFT + V", exec("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))
bind("SUPER + SHIFT + N", exec("~/.config/theming/toggle-theme.sh"))

-- Zoom
local function zoom_by(factor)
    return function()
        hl.config({ cursor = { zoom_factor = hl.get_config("cursor.zoom_factor") * factor } })
    end
end
local function zoom_reset()
    hl.config({ cursor = { zoom_factor = 1 } })
end

bind(mainMod .. " + equal", zoom_by(1.1))
bind(mainMod .. " + minus", zoom_by(0.9), { repeating = true })
bind(mainMod .. " + KP_ADD", zoom_by(1.1), { repeating = true })
bind(mainMod .. " + KP_SUBTRACT", zoom_by(0.9), { repeating = true })

bind(mainMod .. " + SHIFT + mouse_up", zoom_reset)
bind(mainMod .. " + SHIFT + mouse_down", zoom_reset)
bind(mainMod .. " + SHIFT + minus", zoom_reset)
bind(mainMod .. " + SHIFT + KP_SUBTRACT", zoom_reset)
bind(mainMod .. " + SHIFT + 0", zoom_reset)
