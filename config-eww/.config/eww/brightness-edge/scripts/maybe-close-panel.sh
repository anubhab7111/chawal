#!/usr/bin/env bash
# Same debounce as volume-edge: close the panel only once the cursor has
# landed outside both the hotzone and panel rectangles combined.
#
# Bounds must stay in sync with the :geometry values in eww.yuck.
CFG="$1"
sleep 0.08

read -r x y < <(hyprctl cursorpos | tr -d ',')
if (( x < 0 || x > 100 || y < 438 || y > 698 )); then
    eww --config "$CFG" close brightness-panel
fi
