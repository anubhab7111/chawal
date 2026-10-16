-- Keybinds. Ported from configs/bindings.conf in P5; P6 fixed the quirks
-- (duplicate brightness binds, SUPER+SHIFT+0 doing two things, instant exit).

local terminal    = "alacritty"
local fileManager = "thunar"
local menu        = "wofi --show drun"
local code        = "vscodium"
local browser     = "firefox"

local mainMod = "SUPER"

local bind = hl.bind
local exec = hl.dsp.exec_cmd

-- System
-- Exit Hyprland after a Yes/No confirm (rofi's power menu replaces this in P11)
local confirm_exit = [=[[ "$(printf 'No\nYes' | rofi -dmenu -i -no-custom -p 'Exit Hyprland?')" = Yes ]]=]
    .. [[ && hyprctl dispatch 'hl.dsp.exit()']]
bind(mainMod .. " + M", exec(confirm_exit))
-- Lock through logind so hypridle's lock_cmd (single hyprlock instance) runs
bind(mainMod .. " + L", exec("loginctl lock-session"))
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

-- Volume: 5% steps capped at 100%, repeat while held, work on the lock
-- screen. Either volume key unmutes first.
local held = { repeating = true, locked = true }
local sink = "@DEFAULT_AUDIO_SINK@"
local function volume(step)
    return exec("wpctl set-mute " .. sink .. " 0; wpctl set-volume -l 1.0 " .. sink .. " " .. step)
end
bind("XF86AudioRaiseVolume", volume("5%+"), held)
bind("XF86AudioLowerVolume", volume("5%-"), held)
bind("XF86AudioMute", exec("wpctl set-mute " .. sink .. " toggle"), { locked = true })
bind("XF86AudioMicMute", exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Media
bind("XF86AudioPlay", exec("playerctl play-pause"), { locked = true })
bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
bind("XF86AudioNext", exec("playerctl next"), { locked = true })
bind("XF86AudioPrev", exec("playerctl previous"), { locked = true })

-- Brightness: exponential 5% steps (fine near dark), never below 1% of max.
-- brightnessctl 0.5 reads -n as a raw value only, so 1% is computed.
local function brightness(step)
    return exec("brightnessctl -e4 -n$(( $(brightnessctl m) / 100 )) set " .. step)
end
bind("XF86MonBrightnessUp", brightness("5%+"), held)
bind("XF86MonBrightnessDown", brightness("5%-"), held)

-- Screenshots
bind(mainMod .. " + PRINT", exec("hyprshot -m window"))
bind("PRINT", exec("hyprshot -m output"))
bind("SHIFT + PRINT", exec("hyprshot -m region"))

-- Utilities
bind("SUPER + SHIFT + V", exec("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

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
-- SUPER+SHIFT+0 stays "move window to workspace 10" (see the workspace loop)
