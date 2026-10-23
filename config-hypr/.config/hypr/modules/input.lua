hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		follow_mouse = 1,
		mouse_refocus = true,
		float_switch_override_focus = 2,

		repeat_rate = 30,
		repeat_delay = 300,

		sensitivity = 0,
		accel_profile = "flat",
		force_no_accel = false,

		touchpad = {
			natural_scroll = false,
			disable_while_typing = true,
			clickfinger_behavior = true,
			tap_to_click = true,
			drag_lock = false,
			middle_button_emulation = false,
		},
	},

	cursor = {
		no_hardware_cursors = false,
		no_break_fs_vrr = false,
		min_refresh_rate = 60,
		hotspot_padding = 1,
		inactive_timeout = 0,
		no_warps = false,
		persistent_warps = false,
		warp_on_change_workspace = false,
		default_monitor = "",
		zoom_factor = 1.0,
		zoom_rigid = false,
		enable_hyprcursor = true,
		hide_on_key_press = false,
		hide_on_touch = true,
	},

	gestures = {
		workspace_swipe_distance = 300,
		workspace_swipe_invert = true,
		workspace_swipe_min_speed_to_force = 30,
		workspace_swipe_cancel_ratio = 0.5,
		workspace_swipe_create_new = true,
		workspace_swipe_forever = false,
	},
})

-- Touchpad gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = "float" })
hl.gesture({ fingers = 4, direction = "down", action = "close" })
hl.gesture({ fingers = 4, direction = "up", action = "fullscreen" })
