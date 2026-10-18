-- Quick-settings panel (eww: ~/.config/eww/widgets/qs.yuck, opened and closed
-- by scripts/qs-ctl). The only Hyprland side is the Escape key.
--
-- Escape must close the panel but stay untouched everywhere else, so the bind
-- does not live in binds.lua: qs-ctl turns it on when the panel opens and off
-- when it closes (hyprctl eval 'rice.qs.escape_on()' / 'rice.qs.escape_off()').
--
-- Removing a bind matches the key and modifiers in EVERY submap, so removing
-- this one also removes the Escape bind of the resize submap (binds.lua).
-- escape_off puts that one back; define_submap only adds what its callback
-- binds, it does not repeat the other resize binds.

rice.qs = rice.qs or {}

function rice.qs.escape_off()
    local handle = rice.qs.escape
    rice.qs.escape = nil
    if not handle then return end
    -- a config reload drops every bind, so the handle may be stale
    pcall(function() handle:remove() end)
    hl.define_submap("resize", function()
        hl.bind("escape", hl.dsp.submap("reset"))
    end)
end

function rice.qs.escape_on()
    rice.qs.escape_off()
    rice.qs.escape = hl.bind("escape", hl.dsp.exec_cmd("~/.config/eww/scripts/qs-ctl close"))
end
