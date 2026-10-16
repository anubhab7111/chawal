-- Environment variables. P6 dropped the stale GBM/vsync overrides.
-- See https://wiki.hypr.land/Configuring/Environment-variables/

-- Desktop environment
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Qt
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
-- QT_QPA_PLATFORMTHEME is left unset until qt6ct is installed (P35).

-- Cursor: Bibata Modern Classic at 30 everywhere. Hyprland draws the
-- hyprcursor build (home-icons); XWayland, Qt and anything else that reads
-- XCURSOR_* use the XCursor build from bibata-cursor-theme-bin. GTK reads
-- settings.ini / ~/.gtkrc-2.0 / gsettings, all set to the same theme and size.
hl.env("HYPRCURSOR_THEME", "HyprBibataModernClassicSVG")
hl.env("HYPRCURSOR_SIZE", "30")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "30")

-- GPUs. Stable names from system/etc/udev/rules.d/70-dri-stable.rules
-- (install with sudo ~/dotfiles/system/install.sh): Intel iGPU (PCI 00:02.0)
-- renders; NVIDIA (01:00.0) only drives HDMI. Card numbers change between boots.
hl.env("AQ_DRM_DEVICES", "/dev/dri/intel-igpu:/dev/dri/nvidia-dgpu")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
hl.env("LIBVA_DRIVER_NAME", "iHD")

-- Applications
hl.env("HYPRSHOT_DIR", "/home/ushtro/Pictures/Screenshots/")
