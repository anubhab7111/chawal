#!/usr/bin/env bash
# Both the hotzone and panel eventboxes call this on hover-lost. A leave
# fires every time the pointer crosses the seam between those two adjacent
# (non-overlapping) surfaces too, not just when it truly leaves the widget
# -- and if you retreat straight from the hotzone without ever touching the
# panel, the panel's own onhoverlost never fires at all, so it never
# closes. Debounce: wait a beat, then only close if the cursor has actually
# landed outside both rectangles combined.
#
# Bounds must stay in sync with the :geometry values in eww.yuck.
CFG="$1"
sleep 0.08

read -r x y < <(hyprctl cursorpos | tr -d ',')
if (( x < 1820 || x > 1920 || y < 438 || y > 698 )); then
    eww --config "$CFG" close volume-panel
fi
