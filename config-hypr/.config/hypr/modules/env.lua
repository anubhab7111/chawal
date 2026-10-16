-- Environment variables, ported from configs/env.conf unchanged.
-- See https://wiki.hypr.land/Configuring/Environment-variables/

-- Desktop environment
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Qt
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")

-- Cursor
hl.env("HYPRCURSOR_THEME", "HyprBibataModernClassicSVG")
hl.env("HYPRCURSOR_SIZE", "34")

-- GPUs. Stable names from system/etc/udev/rules.d/70-dri-stable.rules
-- (install with sudo ~/dotfiles/system/install.sh): Intel iGPU (PCI 00:02.0)
-- renders; NVIDIA (01:00.0) only drives HDMI. Card numbers change between boots.
hl.env("AQ_DRM_DEVICES", "/dev/dri/intel-igpu:/dev/dri/nvidia-dgpu")
hl.env("GBM_BACKEND", "i915")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("vblank_mode", "0")
hl.env("__GL_SYNC_TO_VBLANK", "0")

-- Applications
hl.env("HYPRSHOT_DIR", "/home/ushtro/Pictures/Screenshots/")
