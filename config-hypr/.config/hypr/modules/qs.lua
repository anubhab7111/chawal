rice.qs = rice.qs or {}

function rice.qs.escape_off()
	local handle = rice.qs.escape
	rice.qs.escape = nil
	if not handle then
		return
	end
	-- a config reload drops every bind, so the handle may be stale
	pcall(function()
		handle:remove()
	end)
	hl.define_submap("resize", function()
		hl.bind("escape", hl.dsp.submap("reset"))
	end)
end

function rice.qs.escape_on()
	rice.qs.escape_off()
	rice.qs.escape = hl.bind("escape", hl.dsp.exec_cmd("~/.config/eww/scripts/qs-ctl close"))
end
