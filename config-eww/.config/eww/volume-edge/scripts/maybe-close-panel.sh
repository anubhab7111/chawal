#!/usr/bin/env bash
# Both the hotzone and panel eventboxes call this on hover-lost. A leave
# fires every time the pointer crosses the seam between those two adjacent
# (non-overlapping) surfaces too, not just when it truly leaves the widget
# -- and if you retreat straight from the hotzone without ever touching the
# panel, the panel's own onhoverlost never fires at all, so it never
# closes. Debounce: wait a beat, then only close if the cursor has actually
# landed outside both rectangles combined.
#
# Closing is two steps so it can animate: flip `panel_open` (the revealer
# slides the panel back out), wait out the transition, and only then destroy
# the window -- after re-checking, so a pointer that came back in mid-slide
# keeps the panel instead of losing it.
#
# Bounds must stay in sync with the :geometry values in eww.yuck.
CFG="$1"
sleep 0.08

outside() {
    read -r x y < <(hyprctl cursorpos | tr -d ',')
    (( x < 1820 || x > 1920 || y < 438 || y > 698 ))
}

if outside; then
    eww --config "$CFG" update panel_open=false
    sleep 0.26
    outside && eww --config "$CFG" close volume-panel
fi
