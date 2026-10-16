-- Look and feel, ported from configs/decorations.conf unchanged.
local p = rice.palette

hl.config({
    general = {
        gaps_in = 8,
        gaps_out = 15,
        border_size = 3,

        -- Tri-colour gradient border, colours from the active theme
        col = {
            active_border = {
                colors = {
                    "rgba(" .. p.border_active[1] .. ")",
                    "rgba(" .. p.border_active[2] .. ")",
                    "rgba(" .. p.border_active[3] .. ")",
                },
                angle = 10,
            },
            inactive_border = "0x" .. p.border_inactive,
        },

        resize_on_border = true,
        extend_border_grab_area = 15,
        hover_icon_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 15,
        active_opacity = 1.0,
        inactive_opacity = 0.92,
        fullscreen_opacity = 1.0,

        dim_inactive = true,
        dim_strength = 0.06,
        dim_special = 0.4,

        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            ignore_opacity = true,
            new_optimizations = true,
            xray = false,
            noise = 0.015,
            contrast = 0.92,
            brightness = 0.88,
            vibrancy = 0.25,
            vibrancy_darkness = 0.35,
            popups = true,
            popups_ignorealpha = 0.6,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = true,
        special_scale_factor = 0.95,
        force_split = 0,
        default_split_ratio = 1.0,
    },

    master = {
        new_status = "master",
        new_on_top = false,
        mfact = 0.55,
        orientation = "left",
        special_scale_factor = 0.95,
    },

    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,

        vrr = 1,

        focus_on_activate = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,

        -- Window swallowing
        enable_swallow = true,
        swallow_regex = [[^(alacritty|kitty|footclient)$]],
        swallow_exception_regex = [[^(wev)$]],

        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
        disable_autoreload = false,

        allow_session_lock_restore = true,
        close_special_on_empty = true,
        exit_window_retains_fullscreen = false,
        initial_workspace_tracking = 1,

        layers_hog_keyboard_focus = true,

        background_color = "0x" .. p.background,
        splash_font_family = "JetBrainsMono Nerd Font",
    },

    binds = {
        workspace_back_and_forth = false,
        allow_workspace_cycles = true,
        workspace_center_on = 0,
        focus_preferred_method = 0,
        ignore_group_lock = false,
        movefocus_cycles_fullscreen = true,
        disable_keybind_grabbing = false,
        window_direction_monitor_fallback = true,
    },

    xwayland = {
        use_nearest_neighbor = true,
        force_zero_scaling = false,
    },

    opengl = {
        nvidia_anti_flicker = true,
    },
})

-- Animations: snappy, with a natural overshoot
local curves = {
    overshot       = { { 0.13, 0.99 }, { 0.29, 1.1 } },
    easeOutQuint   = { { 0.22, 1 },    { 0.36, 1 } },
    easeOutExpo    = { { 0.16, 1 },    { 0.3, 1 } },
    easeInOutCubic = { { 0.65, 0 },    { 0.35, 1 } },
    linear         = { { 0, 0 },       { 1, 1 } },
    smoothIn       = { { 0.25, 1 },    { 0.5, 1 } },
    softBounce     = { { 0.05, 0.7 },  { 0.1, 1.05 } },
}
for name, points in pairs(curves) do
    hl.curve(name, { type = "bezier", points = points })
end

local function anim(leaf, speed, bezier, style)
    hl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = bezier, style = style })
end

-- Windows: overshot slide for a satisfying snap
anim("windowsIn", 4, "overshot", "slide")
anim("windowsOut", 3, "easeInOutCubic", "popin 85%")
anim("windowsMove", 4, "overshot", "slide")

-- Fades: quick and subtle
anim("fadeIn", 3, "smoothIn")
anim("fadeOut", 3, "easeInOutCubic")
anim("fadeSwitch", 3, "smoothIn")
anim("fadeShadow", 3, "smoothIn")
anim("fadeDim", 3, "smoothIn")
anim("fadeLayers", 3, "easeOutExpo")

-- Borders
anim("border", 10, "default")
anim("borderangle", 100, "linear", "loop")

anim("workspaces", 5, "overshot", "slide")
anim("specialWorkspace", 5, "overshot", "slidevert")
