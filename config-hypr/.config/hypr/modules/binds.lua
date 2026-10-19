-- Keybinds. Ported from the hyprlang config in P5; P6 fixed the quirks
-- (duplicate brightness binds, SUPER+SHIFT+0 doing two things, instant exit).

local terminal    = "alacritty"
local fileManager = "thunar"
local menu        = "~/.config/rice/bin/rice-hub"
local code        = "vscodium"
local browser     = "firefox"

local mainMod = "SUPER"

local bind = hl.bind
local exec = hl.dsp.exec_cmd

-- System
-- Lock through logind so hypridle's lock_cmd (single hyprlock instance) runs
bind(mainMod .. " + L", exec("loginctl lock-session"))
bind(mainMod .. " + F1", function() rice.gamemode.toggle() end)          -- Game mode (modes.lua)
-- Power grid. wlogout's own config (layout, style.css and icons) is the
-- config-wlogout package, stowed to ~/.config/wlogout. Five buttons in one
-- row (-b 5); with the default 3 per row wlogout draws a blank sixth tile.
-- The margins keep the tiles square. The Waybar power button uses the same flags.
bind(mainMod .. " + escape", exec("wlogout -b 5 -T 400 -B 400"))

-- Applications
bind(mainMod .. " + Q", exec(terminal))
bind(mainMod .. " + E", exec(fileManager))
bind(mainMod .. " + SPACE", exec(menu))                                        -- Rofi hub (apps first; Tab flips tabs)
bind(mainMod .. " + SHIFT + C", exec(code))
bind(mainMod .. " + B", exec(browser))
bind(mainMod .. " + SHIFT + B", exec("chromium"))
bind(mainMod .. " + Z", exec("zapzap"))
bind(mainMod .. " + A", exec("pwvucontrol"))                                   -- Audio control
bind(mainMod .. " + SHIFT + A", exec("claude-desktop"))
bind(mainMod .. " + O", exec("obsidian"))

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

-- Scratchpads: each starts its app the first time (workspace rules in rules.lua)
bind(mainMod .. " + grave", hl.dsp.workspace.toggle_special("dropdown"))      -- drop-down terminal
bind(mainMod .. " + T", hl.dsp.workspace.toggle_special("term"))
bind(mainMod .. " + M", hl.dsp.workspace.toggle_special("music"))

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
-- screen. Either volume key unmutes first. rice-volume / rice-bright also
-- flash the right-edge gauge (edge-ctl osd).
local held = { repeating = true, locked = true }
bind("XF86AudioRaiseVolume", exec("~/.config/rice/bin/rice-volume up"), held)
bind("XF86AudioLowerVolume", exec("~/.config/rice/bin/rice-volume down"), held)
bind("XF86AudioMute", exec("~/.config/rice/bin/rice-volume mute"), { locked = true })
bind("XF86AudioMicMute", exec("~/.config/rice/bin/rice-volume mic-mute"), { locked = true })

-- Media
bind("XF86AudioPlay", exec("playerctl play-pause"), { locked = true })
bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
bind("XF86AudioNext", exec("playerctl next"), { locked = true })
bind("XF86AudioPrev", exec("playerctl previous"), { locked = true })

-- Brightness: exponential 5% steps (fine near dark), never below 1% of max.
bind("XF86MonBrightnessUp", exec("~/.config/rice/bin/rice-bright up"), held)
bind("XF86MonBrightnessDown", exec("~/.config/rice/bin/rice-bright down"), held)

-- Screenshots
bind(mainMod .. " + PRINT", exec("hyprshot -m window"))
bind("PRINT", exec("hyprshot -m output"))
bind("SHIFT + PRINT", exec("hyprshot -m region"))

-- Screen recording (the same key stops it)
bind("CTRL + PRINT", exec("~/.config/rice/bin/rice-record toggle region"))
bind("CTRL + SHIFT + PRINT", exec("~/.config/rice/bin/rice-record toggle screen"))

-- Utilities
bind("SUPER + SHIFT + V", exec("~/.config/rice/bin/rice-hub clip"))           -- Clipboard history (hub tab)
bind("SUPER + W", exec("~/.config/rice/bin/rice-wall"))                         -- Wallpaper picker
bind("SUPER + N", exec("~/.config/eww/scripts/qs-ctl toggle"))                  -- Quick settings (eww)

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
