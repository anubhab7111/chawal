-- Window, layer and workspace rules. All rules are anonymous on purpose:
-- named rules are evaluated before anonymous ones, which would reorder them.
local p = rice.palette

local function rule(match, effects)
    effects.match = match
    hl.window_rule(effects)
end

local function class(re) return { class = re } end
local function title(re) return { title = re } end

-- General
rule(class([[.*]]), { suppress_event = "maximize" })
rule(class([[^(libreoffice.*)$]]), { suppress_event = "fullscreen" })

-- Floating windows
rule(class([[^(com.saivert.pwvucontrol)$]]), { float = true })
rule(class([[^(blueman-manager)$]]), { float = true })
rule(class([[^(nm-connection-editor)$]]), { float = true })
rule(class([[^(qalculate-gtk)$]]), { float = true })

rule(class([[^(xdg-desktop-portal-gtk)$]]), { float = true })
rule(title([[^(Open File)$]]), { float = true })
rule(title([[^(Save File)$]]), { float = true })
rule(title([[^(Open Folder)$]]), { float = true })
rule(title([[^(Save As)$]]), { float = true })

rule(class([[^(zenity)$]]), { float = true })
rule(title([[^(Picture-in-Picture)$]]), { float = true })
rule(class([[^(imv)$]]), { float = true })

rule(class([[^(polkit-gnome-authentication-agent-1)$]]), { float = true })
rule(class([[^(org.kde.polkit-kde-authentication-agent-1)$]]), { float = true })

-- Centered floating windows
rule(class([[^(com.saivert.pwvucontrol)$]]), { center = true })
rule(class([[^(blueman-manager)$]]), { center = true })
rule(class([[^(qalculate-gtk)$]]), { center = true })
rule(class([[^(nm-connection-editor)$]]), { center = true })
rule(title([[^(Open File)$]]), { center = true })
rule(title([[^(Save File)$]]), { center = true })

-- Window sizes
rule(class([[^(com.saivert.pwvucontrol)$]]), { size = { 900, 600 } })
rule(class([[^(blueman-manager)$]]), { size = { 800, 500 } })
rule(class([[^(qalculate-gtk)$]]), { size = { 600, 700 } })
rule(class([[^(nm-connection-editor)$]]), { size = { 700, 500 } })

-- Opacity
rule(class([[^(com.saivert.pwvucontrol)$]]), { opacity = "0.90 0.85 override" })
rule(class([[^(blueman-manager)$]]), { opacity = "0.90 0.85 override" })
rule(class([[^(thunar)$]]), { opacity = "0.92 0.88 override" })
rule(class([[^(org.gnome.Nautilus)$]]), { opacity = "0.92 0.88 override" })
rule(class([[^(nemo)$]]), { opacity = "0.92 0.88 override" })

rule(class([[^(Alacritty)$]]), { opacity = "0.95 0.90 override" })
rule(class([[^(footclient)$]]), { opacity = "0.95 0.90 override" })

rule(class([[^(code-oss)$]]), { opacity = "0.98 0.95 override" })
rule(class([[^(code)$]]), { opacity = "0.90 0.90 override" })
rule(class([[^(dev.zed.Zed)$]]), { opacity = "0.90 0.90 override" })
rule(class([[^(codium)$]]), { opacity = "0.98 0.95 override" })
rule(class([[^(Cursor)$]]), { opacity = "0.7 0.95 override" })

rule(class([[^(discord)$]]), { opacity = "0.96 0.92 override" })
rule(class([[^(vesktop)$]]), { opacity = "0.96 0.92 override" })
rule(class([[^(com.rtosta.zapzap)$]]), { opacity = "0.96 0.92 override" })
rule(class([[^(Signal)$]]), { opacity = "0.96 0.92 override" })

rule(class([[^(firefox)$]]), { opacity = "1.00 1.00 override" })
rule(class([[^(steam_app_default)$]]), { opacity = "1.00 1.00 override" })
rule(class([[^(µVision)$]]), { opacity = "1.00 1.00 override" })

-- Blur: every window that has any transparency gets the frosted-glass blur
-- (decoration.blur in look.lua); an opaque window is never blurred, so this
-- costs nothing for them. The one exception is gamescope (games).
rule(class([[^(gamescope)$]]), { no_blur = true })

-- Idle inhibit
rule(class([[^(mpv)$]]), { idle_inhibit = "focus" })
rule(class([[^(vlc)$]]), { idle_inhibit = "focus" })
rule(class([[^(firefox)$]]), { idle_inhibit = "fullscreen" })
rule(class([[^(chromium)$]]), { idle_inhibit = "fullscreen" })
rule(class([[^(steam_app_.*)$]]), { idle_inhibit = "always" })

-- Layer rules
local function layer(namespace, effects)
    effects.match = { namespace = namespace }
    hl.layer_rule(effects)
end

layer("wofi", { animation = "popin 80%" })
layer("wofi", { dim_around = true })

layer("rofi", { blur = true, ignore_alpha = 0.5, animation = "popin 90%", dim_around = true })

-- Power grid: same treatment as rofi (blur behind the translucent window,
-- popin, dim the desktop behind it). wlogout's layer namespace is
-- "logout_dialog", not "wlogout", so a rule on "wlogout" never matched.
layer("logout_dialog", { blur = true, ignore_alpha = 0.5, animation = "popin 80%", dim_around = true })

-- The notification list and the toasts are translucent glass now; ignore_alpha blur
-- only the filled part, not the fully transparent window margins around it.
layer("swaync-notification-window", { blur = true, ignore_alpha = 0.3, animation = "slide right" })
layer("swaync-control-center", { blur = true, ignore_alpha = 0.3, animation = "slide top" })

-- Volume edge-hover slider: no blur (its own namespace, so it doesn't inherit
-- the blanket gtk-layer-shell blur rule below; with ignore_opacity and
-- popups_ignorealpha on, that blur rendered through the widget's transparent
-- margins as a visible blurred box). It slides in from the right instead.
layer("volume-panel", { animation = "slide right" })

-- Quick-settings panel (slides down from the top edge) and its click-outside scrim (fades).
-- The card is translucent (@glass, rules.lua) so it is blurred; ignore_alpha keeps the
-- fully transparent rounded corners and window margins out of the blur.
layer("qs-panel", { blur = true, ignore_alpha = 0.3, animation = "slide top" })
layer("qs-scrim", { animation = "fade" })

layer("gtk-layer-shell", { blur = true })
layer("selection", { no_anim = true })

-- Special animations
rule(class([[^(thunar)$]]), { animation = "slide" })
rule(class([[^(org.gnome.Nautilus)$]]), { animation = "slide" })

rule(class([[^(com.saivert.pwvucontrol)$]]), { animation = "popin 80%" })
rule(class([[^(blueman-manager)$]]), { animation = "popin 80%" })
rule(class([[^(qalculate-gtk)$]]), { animation = "popin 80%" })

rule(title([[^(Picture-in-Picture)$]]), { animation = "fade" })

-- Tiling exceptions
rule(class([[^(com\.github\.th-ch\.youtube-music)$]]), { tile = true })
rule(class([[^(discord)$]]), { tile = true })

-- Window borders
-- No border in fullscreen or maximized (SUPER+F / SUPER+SHIFT+F)
rule({ class = [[^(firefox)$]], fullscreen = true }, { border_size = 0 })
rule({ class = [[^(chromium)$]], fullscreen = true }, { border_size = 0 })
rule({ class = [[^(mpv)$]], fullscreen = true }, { border_size = 0 })
rule(class([[^(steam_app_.*)$]]), { border_size = 0 })

rule(class([[^(firefox)$]]), { border_color = "rgb(" .. p.red .. ")" })
rule(class([[^(code-oss)$]]), { border_color = "rgb(" .. p.blue .. ")" })
rule(class([[^(thunar)$]]), { border_color = "rgb(" .. p.green .. ")" })
rule(class([[^(discord)$]]), { border_color = "rgb(" .. p.peach .. ")" })

-- Pinning and special behaviours
rule(title([[^(Picture-in-Picture)$]]), { pin = true })

rule(class([[^(steam)$]]), { no_initial_focus = true })
rule(class([[^(com\.github\.th-ch\.youtube-music)$]]), { no_initial_focus = true })

rule(class([[^(steam_app_.*)$]]), { immediate = true })
rule(class([[^(cs2)$]]), { immediate = true })

-- XWayland apps
rule({ xwayland = true }, { rounding = 12 })

-- Workspace rules
hl.workspace_rule({ workspace = "1", persistent = true })
hl.workspace_rule({ workspace = "2", persistent = true })
hl.workspace_rule({ workspace = "special:music", on_created_empty = "youtube-music" })
hl.workspace_rule({ workspace = "special:term", on_created_empty = "alacritty" })
hl.workspace_rule({ workspace = "special:dropdown", on_created_empty = "alacritty --class dropdown" })

-- Drop-down terminal (SUPER+grave): a wide strip under the bar, sliding in
rule(class([[^(dropdown)$]]), {
    float = true,
    size = { "monitor_w*0.98", "monitor_h*0.45" },
    move = { "monitor_w*0.01", "60" },
    animation = "slide top",
    opacity = "0.95 0.90 override",
})
