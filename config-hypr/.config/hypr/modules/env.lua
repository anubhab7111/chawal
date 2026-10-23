-- Desktop environment
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Qt
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

hl.env("HYPRCURSOR_THEME", "HyprBibataModernClassicSVG")
hl.env("HYPRCURSOR_SIZE", "30")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "30")

-- GPUs. Stable names from system/etc/udev/rules.d/70-dri-stable.rules
hl.env("AQ_DRM_DEVICES", "/dev/dri/intel-igpu:/dev/dri/nvidia-dgpu")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
hl.env("LIBVA_DRIVER_NAME", "iHD")

-- Applications
hl.env("HYPRSHOT_DIR", "/home/ushtro/Pictures/Screenshots/")
