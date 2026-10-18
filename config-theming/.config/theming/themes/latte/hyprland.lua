-- Catppuccin Latte palette for the Hyprland Lua config.
-- Loaded by config-hypr/.config/hypr/modules/palette.lua through the
-- theming/current symlink. Plain hex strings: RRGGBB, or AARRGGBB/RRGGBBAA
-- where noted. modules/fallback_palette.lua is a copy of this file.
return {
    rosewater = "dc8a78",
    flamingo  = "dd7878",
    pink      = "ea76cb",
    mauve     = "8839ef",
    red       = "d20f39",
    maroon    = "e64553",
    peach     = "fe640b",
    yellow    = "df8e1d",
    green     = "40a02b",
    teal      = "179299",
    sky       = "04a5e5",
    sapphire  = "209fb5",
    blue      = "1e66f5",
    lavender  = "7287fd",
    text      = "4c4f69",
    subtext1  = "5c5f77",
    subtext0  = "6c6f85",
    overlay2  = "7c7f93",
    overlay1  = "8c8fa1",
    overlay0  = "9ca0b0",
    surface2  = "acb0be",
    surface1  = "bcc0cc",
    surface0  = "ccd0da",
    base      = "eff1f5",
    mantle    = "e6e9ef",
    crust     = "dce0e8",

    -- Derived values used by modules/look.lua
    border_active   = { "8839efff", "1e66f5ff", "179299ff" }, -- RRGGBBAA, 10deg gradient
    border_inactive = "ffbcc0cc",                             -- AARRGGBB
    background      = "eff1f5",
}
