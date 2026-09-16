#!/bin/bash
# Cycle to the next theme in themes/ and apply it. Bound to the waybar button.

set -euo pipefail

THEMING_DIR="$HOME/.config/theming"
CURRENT="$(basename "$(readlink -f "$THEMING_DIR/current")")"

mapfile -t THEMES < <(find "$THEMING_DIR/themes" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

next=""
for i in "${!THEMES[@]}"; do
    if [ "${THEMES[$i]}" = "$CURRENT" ]; then
        next="${THEMES[$(( (i + 1) % ${#THEMES[@]} ))]}"
        break
    fi
done
[ -n "$next" ] || next="${THEMES[0]}"

"$THEMING_DIR/apply-theme.sh" "$next"
