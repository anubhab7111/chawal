#!/bin/bash
# Emits JSON for the waybar custom/theme-switcher module.

THEMING_DIR="$HOME/.config/theming"
CURRENT="$(basename "$(readlink -f "$THEMING_DIR/current")")"

if [ "$CURRENT" = "petabyte" ]; then
    # nf-md-incognito (U+F05F3)
    icon="$(printf '\U000f05f3')"
else
    # nf-md-palette (U+F0538)
    icon="$(printf '\U000f0538')"
fi
label="${CURRENT^}"

printf '{"text": "%s %s", "tooltip": "Theme: %s\\nClick to switch", "alt": "%s", "class": "%s"}\n' \
    "$icon" "$label" "$label" "$CURRENT" "$CURRENT"
