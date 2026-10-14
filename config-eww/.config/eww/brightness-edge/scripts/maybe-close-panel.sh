#!/usr/bin/env bash
# Same debounce and two-step animated close as volume-edge: slide the panel
# out, wait out the transition, then close the window only if the cursor is
# still outside both the hotzone and panel rectangles combined.
#
# Bounds must stay in sync with the :geometry values in eww.yuck.
CFG="$1"
sleep 0.08

outside() {
    read -r x y < <(hyprctl cursorpos | tr -d ',')
    (( x < 0 || x > 100 || y < 438 || y > 698 ))
}

if outside; then
    eww --config "$CFG" update panel_open=false
    sleep 0.26
    outside && eww --config "$CFG" close brightness-panel
fi
